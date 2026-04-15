-- BazWidgets Widget: Delve Companion
--
-- Dormant widget that auto-shows when you're in a scenario (delve) and
-- displays your active delve companion (Brann or the Midnight companion).
-- Reads the same APIs Blizzard's own Companion Configuration UI uses, so
-- it adapts to whichever companion is active and to future companions.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_companion"
local DESIGN_WIDTH = 260
local DESIGN_HEIGHT = 80
local PAD          = 8
local PORTRAIT     = 56

-- Colors
local CLR_NAME    = { 1.00, 0.85, 0.45 }
local CLR_LEVEL   = { 1.00, 0.82, 0.00 }
local CLR_DIM     = { 0.65, 0.65, 0.70 }
local CLR_XP      = { 0.40, 0.85, 0.40 }
local CLR_XP_BG   = { 0.10, 0.10, 0.12, 0.85 }

local CompanionWidget = {}
addon.CompanionWidget = CompanionWidget

-- Debug logging — flip to true to print resolved companion data
local DEBUG = true
local function dprint(...)
    if DEBUG then
        print("|cffffd700[Companion]|r", ...)
    end
end

---------------------------------------------------------------------------
-- Data state
---------------------------------------------------------------------------

local D = {
    inScenario  = false,
    companionID = nil,
    name        = "",
    level       = 0,
    xpCur       = 0,
    xpMax       = 1,
    displayID   = nil,
    role        = nil,    -- "tank" | "healer" | "dps" | nil
    roleName    = "",     -- localized role display name (e.g. "Curator", "Combat")
}

-- Atlases for the LFG-style role icons (same set Blizzard's own
-- delve companion config UI uses).
local ROLE_ATLAS = {
    tank   = "ui-lfg-roleicon-tank-micro-raid",
    healer = "ui-lfg-roleicon-healer-micro-raid",
    dps    = "ui-lfg-roleicon-dps-micro-raid",
}

---------------------------------------------------------------------------
-- Safe-string helper. Midnight has secret-string taint that can poison
-- other operations; pcall-laundering through string.format strips it.
---------------------------------------------------------------------------

local function Safe(s)
    if s == nil then return "" end
    if BazCore and BazCore.SafeString then return BazCore:SafeString(s) end
    local ok, out = pcall(string.format, "%s", s)
    return ok and out or ""
end

---------------------------------------------------------------------------
-- Read companion data (defensive against missing APIs)
---------------------------------------------------------------------------

local function FetchData()
    D.inScenario = false
    D.companionID = nil
    D.name        = ""
    D.level       = 0
    D.xpCur       = 0
    D.xpMax       = 1
    D.displayID   = nil

    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        return
    end
    D.inScenario = true

    -- C_DelvesUI.GetCompanionInfoForActivePlayer() returns a "info ID" that
    -- is NOT the same as the companionID accepted by *ForCompanion calls.
    -- Those functions document companionID as Nilable = true — passing nil
    -- means "use the active companion", which is exactly what we want.
    -- We pass nil throughout and only stash the info ID for status text.
    local cid = nil

    if DEBUG then
        local infoID
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            local ok, result = pcall(C_DelvesUI.GetCompanionInfoForActivePlayer)
            if ok then infoID = result end
        end
        dprint("infoID:", tostring(infoID), "| C_DelvesUI present:", tostring(C_DelvesUI and true or false))
    end

    D.companionID = cid  -- always nil; lets the API resolve to active

    -- Faction-based name + level (mirrors Blizzard's CompanionInfo refresh)
    if C_DelvesUI and C_DelvesUI.GetFactionForCompanion then
        local factionID = C_DelvesUI.GetFactionForCompanion(cid)
        if factionID then
            -- Level via friendship reputation
            if C_GossipInfo and C_GossipInfo.GetFriendshipReputationRanks then
                local rank = C_GossipInfo.GetFriendshipReputationRanks(factionID)
                if rank and rank.currentLevel then D.level = rank.currentLevel end
            end
            -- XP within current level
            if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
                local rep = C_GossipInfo.GetFriendshipReputation(factionID)
                if rep and rep.nextThreshold then
                    D.xpCur = (rep.standing or 0) - (rep.reactionThreshold or 0)
                    D.xpMax = (rep.nextThreshold or 1) - (rep.reactionThreshold or 0)
                    if D.xpMax <= 0 then D.xpMax = 1 end
                else
                    -- Max level — show full bar
                    D.xpCur, D.xpMax = 1, 1
                end
            end
            -- Name from faction data
            if C_Reputation and C_Reputation.GetFactionDataByID then
                local data = C_Reputation.GetFactionDataByID(factionID)
                if data and data.name then D.name = Safe(data.name) end
            end
        end
    end

    -- Portrait creature display ID
    if C_DelvesUI and C_DelvesUI.GetCreatureDisplayInfoForCompanion then
        local ok, displayID = pcall(C_DelvesUI.GetCreatureDisplayInfoForCompanion, cid)
        if ok then D.displayID = displayID end
    end

    -- Active role detection (Tank/Healer/DPS).
    -- Pattern lifted from Blizzard's own DelvesCompanionAbilityList:
    --   1. Get the companion's trait tree ID
    --   2. Resolve to a config ID (nil if companion isn't customized yet)
    --   3. Get the role node ID
    --   4. Get the active entry from the node info
    --   5. Read the entry's subTreeID
    --   6. Compare to GetRoleSubtreeForCompanion(role, nil) for each role
    D.role     = nil
    D.roleName = ""
    if C_DelvesUI and C_Traits and Enum and Enum.CompanionRoleType then
        local treeID
        if C_DelvesUI.GetTraitTreeForCompanion then
            local ok, t = pcall(C_DelvesUI.GetTraitTreeForCompanion, cid)
            if ok then treeID = t end
        end
        local configID
        if treeID and C_Traits.GetConfigIDByTreeID then
            local ok, c = pcall(C_Traits.GetConfigIDByTreeID, treeID)
            if ok then configID = c end
        end
        local roleNodeID
        if C_DelvesUI.GetRoleNodeForCompanion then
            local ok, n = pcall(C_DelvesUI.GetRoleNodeForCompanion, cid)
            if ok then roleNodeID = n end
        end
        if configID and roleNodeID and C_Traits.GetNodeInfo then
            local ok, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, roleNodeID)
            local activeEntryID = ok and nodeInfo and nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
            if activeEntryID and C_Traits.GetEntryInfo then
                local ok2, entryInfo = pcall(C_Traits.GetEntryInfo, configID, activeEntryID)
                local subTreeID = ok2 and entryInfo and entryInfo.subTreeID
                if subTreeID then
                    -- Walk the three role types and find the matching one
                    local roles = {
                        { key = "dps",    enum = Enum.CompanionRoleType.Dps  },
                        { key = "healer", enum = Enum.CompanionRoleType.Heal },
                        { key = "tank",   enum = Enum.CompanionRoleType.Tank },
                    }
                    for _, r in ipairs(roles) do
                        local ok3, rid = pcall(C_DelvesUI.GetRoleSubtreeForCompanion, r.enum, cid)
                        if ok3 and rid == subTreeID then
                            D.role = r.key
                            break
                        end
                    end
                    -- Localized role name from the subtree info (e.g. "Combat", "Curator")
                    if C_Traits.GetSubTreeInfo then
                        local ok4, subInfo = pcall(C_Traits.GetSubTreeInfo, configID, subTreeID)
                        if ok4 and subInfo and subInfo.name then
                            D.roleName = Safe(subInfo.name)
                        end
                    end
                end
            end
        end
    end

    if DEBUG then
        dprint(string.format("name=%q level=%d xp=%d/%d displayID=%s role=%s roleName=%q",
            tostring(D.name), D.level, D.xpCur, D.xpMax,
            tostring(D.displayID), tostring(D.role), tostring(D.roleName)))
    end
end

---------------------------------------------------------------------------
-- Frame construction
---------------------------------------------------------------------------

local frame

function CompanionWidget:Build()
    if frame then return frame end

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)

    -- Portrait area — built from three stacked textures so we get a
    -- clean circular portrait with a gold ring around it, no decorative
    -- atlas baggage:
    --   1. ringBg  — slightly oversized gold disc, becomes the ring
    --   2. portrait — the actual unit portrait, on top of ringBg
    --   3. circleMask — clips both to a circle
    local RING_THICKNESS = 2

    -- Gold disc (becomes the visible ring)
    f.ringBg = f:CreateTexture(nil, "BACKGROUND")
    f.ringBg:SetAtlas("CircleMask")
    f.ringBg:SetVertexColor(1.00, 0.82, 0.10, 1)
    f.ringBg:SetSize(PORTRAIT + RING_THICKNESS * 2, PORTRAIT + RING_THICKNESS * 2)
    f.ringBg:SetPoint("LEFT", PAD - RING_THICKNESS, 0)

    -- The portrait, sized to leave the ring exposed
    f.portrait = f:CreateTexture(nil, "ARTWORK")
    f.portrait:SetSize(PORTRAIT, PORTRAIT)
    f.portrait:SetPoint("CENTER", f.ringBg, "CENTER", 0, 0)
    f.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    f.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Circle mask clips the portrait into a circle
    f.portraitMask = f:CreateMaskTexture(nil, "ARTWORK")
    f.portraitMask:SetAtlas("CircleMask")
    f.portraitMask:SetAllPoints(f.portrait)
    f.portrait:AddMaskTexture(f.portraitMask)

    -- Hidden — placeholder for the previous decorative ring; kept so other
    -- code that references f.portraitRing doesn't break.
    f.portraitRing = f.ringBg

    -- Name (gold, top-right of portrait)
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.name:SetPoint("TOPLEFT", f.portrait, "TOPRIGHT", 10, -2)
    f.name:SetPoint("RIGHT", -PAD, 0)
    f.name:SetJustifyH("LEFT")
    f.name:SetTextColor(unpack(CLR_NAME))
    f.name:SetWordWrap(false)

    -- Level line (below name)
    f.level = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.level:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -2)
    f.level:SetJustifyH("LEFT")
    f.level:SetTextColor(unpack(CLR_LEVEL))

    -- Role icon (sits to the right of the level text)
    f.roleIcon = f:CreateTexture(nil, "OVERLAY")
    f.roleIcon:SetSize(14, 14)
    f.roleIcon:SetPoint("LEFT", f.level, "RIGHT", 8, 0)
    f.roleIcon:Hide()

    -- Role name (e.g. "Combat", "Curator")
    f.roleText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.roleText:SetPoint("LEFT", f.roleIcon, "RIGHT", 4, 0)
    f.roleText:SetJustifyH("LEFT")
    f.roleText:SetTextColor(unpack(CLR_DIM))

    -- XP bar (below level, full width to right edge)
    f.xpBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.xpBg:SetPoint("BOTTOMLEFT", f.portrait, "BOTTOMRIGHT", 10, 0)
    f.xpBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 6)
    f.xpBg:SetHeight(8)
    f.xpBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f.xpBg:SetBackdropColor(unpack(CLR_XP_BG))
    f.xpBg:SetBackdropBorderColor(0.30, 0.25, 0.15, 0.85)

    f.xpFill = f.xpBg:CreateTexture(nil, "ARTWORK")
    f.xpFill:SetPoint("TOPLEFT", 2, -2)
    f.xpFill:SetPoint("BOTTOMLEFT", 2, 2)
    f.xpFill:SetWidth(0)
    f.xpFill:SetColorTexture(unpack(CLR_XP))

    f.xpText = f.xpBg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.xpText:SetPoint("CENTER", f.xpBg, "CENTER", 0, 0)
    f.xpText:SetTextColor(0.95, 0.95, 0.95)

    frame = f
    return f
end

---------------------------------------------------------------------------
-- Refresh display
---------------------------------------------------------------------------

function CompanionWidget:Refresh()
    if not frame then return end

    -- Name + level
    if D.name ~= "" then
        frame.name:SetText(D.name)
    else
        frame.name:SetText("Companion")
    end
    if D.level > 0 then
        frame.level:SetText("Level " .. D.level)
    else
        frame.level:SetText("")
    end

    -- Portrait
    if D.displayID and SetPortraitTextureFromCreatureDisplayID then
        local ok = pcall(SetPortraitTextureFromCreatureDisplayID, frame.portrait, D.displayID)
        if ok then
            frame.portrait:SetTexCoord(0, 1, 0, 1)
        end
    end

    -- Role icon + name
    if D.role and ROLE_ATLAS[D.role] then
        frame.roleIcon:SetAtlas(ROLE_ATLAS[D.role], false)
        frame.roleIcon:Show()
        frame.roleText:SetText(D.roleName ~= "" and D.roleName or D.role)
    else
        frame.roleIcon:Hide()
        frame.roleText:SetText("")
    end

    -- XP bar
    local pct = math.min(1, math.max(0, D.xpCur / math.max(1, D.xpMax)))
    local barW = (frame.xpBg:GetWidth() or 100) - 4
    frame.xpFill:SetWidth(math.max(0.001, barW * pct))
    if D.xpMax > 1 then
        frame.xpText:SetText(D.xpCur .. " / " .. D.xpMax)
    else
        frame.xpText:SetText("Max Level")
    end
end

---------------------------------------------------------------------------
-- Widget contract
---------------------------------------------------------------------------

function CompanionWidget:GetDesiredHeight() return DESIGN_HEIGHT end

function CompanionWidget:GetStatusText()
    if D.level > 0 then
        return "Lv " .. D.level, unpack(CLR_LEVEL)
    end
    return ""
end

---------------------------------------------------------------------------
-- Init — register dormant widget
---------------------------------------------------------------------------

function CompanionWidget:Init()
    local f = self:Build()

    f:RegisterEvent("SCENARIO_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("UPDATE_FACTION")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    f:SetScript("OnEvent", function()
        FetchData()
        CompanionWidget:Refresh()
    end)
    f:HookScript("OnShow", function()
        FetchData()
        CompanionWidget:Refresh()
    end)

    local widgetDef = {
        id           = WIDGET_ID,
        label        = "Delve Companion",
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = f,
        GetDesiredHeight = function() return CompanionWidget:GetDesiredHeight() end,
        GetStatusText    = function() return CompanionWidget:GetStatusText() end,
    }

    local LBW = LibStub("LibBazWidget-1.0")
    LBW:RegisterDormantWidget(widgetDef, {
        events = {
            "SCENARIO_UPDATE",
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
        },
        condition = function()
            FetchData()
            -- Show in any scenario; the data fetcher reads the active
            -- companion and gracefully handles a missing companion ID
            -- (Refresh shows a placeholder in that case).
            return D.inScenario
        end,
    })
end

CompanionWidget:Init()
