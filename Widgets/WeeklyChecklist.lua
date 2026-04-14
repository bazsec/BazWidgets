-- BazWidgets Widget: Weekly Checklist
--
-- Tracks weekly content completion: vault progress (M+, raid, world),
-- weekly quests, and instance lockouts.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_weekly"
local DESIGN_WIDTH = 220
local PAD          = 8
local ROW_HEIGHT   = 16
local SECTION_GAP  = 4

local WeeklyWidget = {}
local frame
local lastSummary = ""

-- Get the player's vault status (Great Vault rewards)
local function GetVaultProgress()
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then
        return nil
    end
    local activities = {
        raid = { done = 0, total = 3 },
        mplus = { done = 0, total = 3 },
        world = { done = 0, total = 3 },
    }
    -- Enum.WeeklyRewardChestThresholdType: Raid=1, Activities=2 (M+), World=3
    for _, info in ipairs(C_WeeklyRewards.GetActivities() or {}) do
        local key = info.type == 1 and "raid"
                 or info.type == 2 and "mplus"
                 or info.type == 3 and "world"
        if key and info.progress and info.threshold then
            if info.progress >= info.threshold then
                activities[key].done = activities[key].done + 1
            end
        end
    end
    return activities
end

function WeeklyWidget:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsWeekly", UIParent)
    f:SetSize(DESIGN_WIDTH, 100)

    -- Header
    f.header = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.header:SetPoint("TOPLEFT", PAD, -PAD)
    f.header:SetText("Great Vault")
    f.header:SetTextColor(1, 0.82, 0)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(18, 18)
    f.icon:SetPoint("LEFT", f.header, "RIGHT", 4, 0)
    f.icon:SetTexture("Interface\\Icons\\INV_Misc_QirajiCrystal_05")
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", PAD, -PAD - 18)
    sep:SetPoint("TOPRIGHT", -PAD, -PAD - 18)
    sep:SetColorTexture(0.3, 0.25, 0.15, 0.4)

    f.rows = {}

    frame = f
    return f
end

local function MakeRow(parent, key, label, color)
    local row = parent.rows[key]
    if row then return row end
    row = CreateFrame("Frame", nil, parent)
    row:SetSize(DESIGN_WIDTH - PAD * 2, ROW_HEIGHT)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetText(label)
    row.label:SetTextColor(unpack(color))
    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.value:SetPoint("RIGHT", -4, 0)
    parent.rows[key] = row
    return row
end

local function FormatProgress(done, total)
    if done >= total then
        return "|cff44dd44" .. done .. "/" .. total .. "|r"
    end
    return done .. "/" .. total
end

function WeeklyWidget:Update()
    if not frame then return end

    local vault = GetVaultProgress()
    if not vault then
        return
    end

    local y = -(PAD + 22)

    local raidRow = MakeRow(frame, "raid", "Raid", { 1, 0.5, 0.5 })
    raidRow:ClearAllPoints()
    raidRow:SetPoint("TOPLEFT", PAD, y)
    raidRow:SetPoint("TOPRIGHT", -PAD, y)
    raidRow.value:SetText(FormatProgress(vault.raid.done, vault.raid.total))
    raidRow:Show()
    y = y - ROW_HEIGHT

    local mplusRow = MakeRow(frame, "mplus", "Mythic+", { 0.5, 0.8, 1 })
    mplusRow:ClearAllPoints()
    mplusRow:SetPoint("TOPLEFT", PAD, y)
    mplusRow:SetPoint("TOPRIGHT", -PAD, y)
    mplusRow.value:SetText(FormatProgress(vault.mplus.done, vault.mplus.total))
    mplusRow:Show()
    y = y - ROW_HEIGHT

    local worldRow = MakeRow(frame, "world", "World", { 0.5, 1, 0.7 })
    worldRow:ClearAllPoints()
    worldRow:SetPoint("TOPLEFT", PAD, y)
    worldRow:SetPoint("TOPRIGHT", -PAD, y)
    worldRow.value:SetText(FormatProgress(vault.world.done, vault.world.total))
    worldRow:Show()
    y = y - ROW_HEIGHT

    frame:SetHeight(math.abs(y) + PAD)

    -- Summary for status text: total slots completed
    local total = vault.raid.done + vault.mplus.done + vault.world.done
    lastSummary = total .. "/9"

    if addon.WidgetHost then
        if addon.WidgetHost.UpdateWidgetStatus then
            addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
        end
        if addon.WidgetHost.Reflow then addon.WidgetHost:Reflow() end
    end
end

function WeeklyWidget:GetStatusText()
    if lastSummary == "" then return "", 0.6, 0.6, 0.6 end
    return lastSummary, 1, 0.82, 0
end

function WeeklyWidget:GetDesiredHeight()
    if frame then return frame:GetHeight() end
    return PAD * 2 + 22 + ROW_HEIGHT * 3
end

function WeeklyWidget:Init()
    local f = self:Build()
    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Weekly",
        designWidth  = DESIGN_WIDTH,
        designHeight = self:GetDesiredHeight(),
        frame        = f,
        GetDesiredHeight = function() return WeeklyWidget:GetDesiredHeight() end,
        GetStatusText    = function() return WeeklyWidget:GetStatusText() end,
    })

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    f:HookScript("OnEvent", function() WeeklyWidget:Update() end)

    -- Delay first update so APIs are ready
    C_Timer.After(2, function() WeeklyWidget:Update() end)
end

BazCore:QueueForLogin(function() WeeklyWidget:Init() end)
