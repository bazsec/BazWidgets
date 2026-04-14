-- BazWidgets Widget: Collection Counter
--
-- Shows mount and pet collection counts with completion percentages.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_collections"
local DESIGN_WIDTH = 220
local PAD          = 10
local ROW_HEIGHT   = 22

local CollectionWidget = {}
local frame

local function GetMountStats()
    if not C_MountJournal or not C_MountJournal.GetMountIDs then
        return 0, 0
    end
    -- Ensure Blizzard_Collections is loaded so the journal is populated
    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_Collections")
    end
    local owned, total = 0, 0
    for _, mountID in ipairs(C_MountJournal.GetMountIDs() or {}) do
        total = total + 1
        local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if isCollected then owned = owned + 1 end
    end
    return owned, total
end

local function GetPetStats()
    if not C_PetJournal or not C_PetJournal.GetNumPets then
        return 0, 0
    end
    -- API returns (numPets, numOwned). numPets is the total visible, numOwned is what we have
    local total, owned = C_PetJournal.GetNumPets()
    return owned or 0, total or 0
end

function CollectionWidget:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsCollections", UIParent)
    f:SetSize(DESIGN_WIDTH, PAD * 2 + ROW_HEIGHT * 2)

    -- Mounts row
    f.mountIcon = f:CreateTexture(nil, "ARTWORK")
    f.mountIcon:SetSize(20, 20)
    f.mountIcon:SetPoint("TOPLEFT", PAD, -PAD)
    f.mountIcon:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse")
    f.mountIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.mountLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.mountLabel:SetPoint("LEFT", f.mountIcon, "RIGHT", 6, 0)
    f.mountLabel:SetText("Mounts")
    f.mountLabel:SetTextColor(0.9, 0.9, 0.9)

    -- Anchor value's RIGHT to the icon's RIGHT center vertically
    f.mountValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.mountValue:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    f.mountValue:SetPoint("TOP", f.mountIcon, "TOP", 0, -2)
    f.mountValue:SetTextColor(1, 0.82, 0)

    -- Pets row
    f.petIcon = f:CreateTexture(nil, "ARTWORK")
    f.petIcon:SetSize(20, 20)
    f.petIcon:SetPoint("TOPLEFT", PAD, -PAD - ROW_HEIGHT)
    f.petIcon:SetTexture("Interface\\Icons\\INV_Pet_BabyBlizzardBear")
    f.petIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.petLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.petLabel:SetPoint("LEFT", f.petIcon, "RIGHT", 6, 0)
    f.petLabel:SetText("Pets")
    f.petLabel:SetTextColor(0.9, 0.9, 0.9)

    f.petValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.petValue:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    f.petValue:SetPoint("TOP", f.petIcon, "TOP", 0, -2)
    f.petValue:SetTextColor(1, 0.82, 0)

    frame = f
    return f
end

function CollectionWidget:Update()
    if not frame then return end
    local mOwned, mTotal = GetMountStats()
    local pOwned, pTotal = GetPetStats()

    local mPct = mTotal > 0 and math.floor(mOwned / mTotal * 100) or 0
    local pPct = pTotal > 0 and math.floor(pOwned / pTotal * 100) or 0

    frame.mountValue:SetText(string.format("%d|cff888888 / %d (%d%%)|r", mOwned, mTotal, mPct))
    frame.petValue:SetText(string.format("%d|cff888888 / %d (%d%%)|r", pOwned, pTotal, pPct))

    if addon.WidgetHost and addon.WidgetHost.UpdateWidgetStatus then
        addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
    end
end

function CollectionWidget:GetStatusText()
    local mOwned = GetMountStats()
    local pOwned = GetPetStats()
    return mOwned .. " / " .. pOwned, 1, 0.82, 0
end

function CollectionWidget:GetDesiredHeight()
    return PAD * 2 + ROW_HEIGHT * 2
end

function CollectionWidget:Init()
    local f = self:Build()
    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Collections",
        designWidth  = DESIGN_WIDTH,
        designHeight = self:GetDesiredHeight(),
        frame        = f,
        GetDesiredHeight = function() return CollectionWidget:GetDesiredHeight() end,
        GetStatusText    = function() return CollectionWidget:GetStatusText() end,
    })

    f:RegisterEvent("NEW_MOUNT_ADDED")
    f:RegisterEvent("NEW_PET_ADDED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:HookScript("OnEvent", function() CollectionWidget:Update() end)

    -- Delayed first update so journals are loaded
    C_Timer.After(3, function() CollectionWidget:Update() end)
end

BazCore:QueueForLogin(function() CollectionWidget:Init() end)
