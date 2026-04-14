-- BazWidgets Widget: Stat Summary
--
-- Compact display of item level + key secondary stats.
-- Title bar shows item level via GetStatusText.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_stats"
local DESIGN_WIDTH = 220
local PAD          = 10
local ROW_HEIGHT   = 16
local LABEL_W      = 80

local STATS = {
    { key = "crit",    label = "Crit",    color = { 1, 0.82, 0 } },
    { key = "haste",   label = "Haste",   color = { 0.4, 0.9, 1 } },
    { key = "mastery", label = "Mastery", color = { 1, 0.5, 0.8 } },
    { key = "vers",    label = "Vers",    color = { 0.5, 1, 0.5 } },
}

local DESIGN_HEIGHT = PAD * 2 + 22 + ROW_HEIGHT * #STATS + 6

local StatWidget = {}
local frame
local lastIlvl = 0

local function GetItemLevel()
    local _, equipped = GetAverageItemLevel()
    return math.floor(equipped or 0)
end

local STAT_GETTERS = {
    crit    = function() return GetCritChance() or 0 end,
    haste   = function() return _G.GetHaste() or 0 end,
    mastery = function() return GetMasteryEffect() or 0 end,
    vers    = function() return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0 end,
}

function StatWidget:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsStatSummary", UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)

    -- Item level header
    f.ilvlIcon = f:CreateTexture(nil, "ARTWORK")
    f.ilvlIcon:SetSize(20, 20)
    f.ilvlIcon:SetPoint("TOPLEFT", PAD, -PAD)
    f.ilvlIcon:SetTexture("Interface\\Icons\\INV_Misc_Statue_03")
    f.ilvlIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.ilvlLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.ilvlLabel:SetPoint("LEFT", f.ilvlIcon, "RIGHT", 6, 4)
    f.ilvlLabel:SetText("Item Level")
    f.ilvlLabel:SetTextColor(0.7, 0.7, 0.7)

    f.ilvlValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.ilvlValue:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -PAD - 2)
    f.ilvlValue:SetTextColor(1, 0.82, 0)

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", PAD, -PAD - 22)
    sep:SetPoint("TOPRIGHT", -PAD, -PAD - 22)
    sep:SetColorTexture(0.3, 0.25, 0.15, 0.4)

    -- Stat rows
    f.rows = {}
    local y = -(PAD + 28)
    for _, stat in ipairs(STATS) do
        local row = {}
        row.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("TOPLEFT", PAD + 4, y)
        row.label:SetText(stat.label)
        row.label:SetTextColor(unpack(stat.color))

        row.value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.value:SetPoint("TOPRIGHT", -PAD, y)
        row.value:SetTextColor(0.95, 0.95, 0.95)

        f.rows[stat.key] = row
        y = y - ROW_HEIGHT
    end

    frame = f
    return f
end

function StatWidget:Update()
    if not frame then return end
    local ilvl = GetItemLevel()
    lastIlvl = ilvl
    frame.ilvlValue:SetText(ilvl)

    for _, stat in ipairs(STATS) do
        local row = frame.rows[stat.key]
        local val = STAT_GETTERS[stat.key]() or 0
        row.value:SetText(string.format("%.1f%%", val))
    end

    if addon.WidgetHost and addon.WidgetHost.UpdateWidgetStatus then
        addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
    end
end

function StatWidget:GetStatusText()
    return tostring(lastIlvl), 1, 0.82, 0
end

function StatWidget:GetDesiredHeight() return DESIGN_HEIGHT end

function StatWidget:Init()
    local f = self:Build()
    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Stats",
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = f,
        GetDesiredHeight = function() return StatWidget:GetDesiredHeight() end,
        GetStatusText    = function() return StatWidget:GetStatusText() end,
    })

    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
    f:RegisterEvent("COMBAT_RATING_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:HookScript("OnEvent", function() StatWidget:Update() end)

    self:Update()
end

BazCore:QueueForLogin(function() StatWidget:Init() end)
