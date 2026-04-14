-- BazWidgets Widget: Gold Tracker
--
-- Shows current gold and session change with iconography.
-- Title bar shows compact gold via GetStatusText.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_goldtracker"
local DESIGN_WIDTH = 220
local DESIGN_HEIGHT = 64
local PAD          = 8

local GoldWidget = {}

local sessionStart = 0
local frame

local function FormatGold(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", g, s, c)
    elseif s > 0 then
        return string.format("%d|cffc7c7cfs|r %d|cffeda55fc|r", s, c)
    end
    return string.format("%d|cffeda55fc|r", c)
end

local function FormatGoldShort(copper)
    local g = math.floor(copper / 10000)
    if g >= 1000000 then
        return string.format("%.1fM|cffffd700g|r", g / 1000000)
    elseif g >= 1000 then
        return string.format("%.1fk|cffffd700g|r", g / 1000)
    end
    return g .. "|cffffd700g|r"
end

function GoldWidget:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsGoldTracker", UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)

    -- Coin icon (left)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(28, 28)
    f.icon:SetPoint("LEFT", PAD, 4)
    f.icon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")

    -- Current gold (large, top right of icon)
    f.current = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.current:SetPoint("LEFT", f.icon, "RIGHT", 6, 6)
    f.current:SetJustifyH("LEFT")

    -- Session change (smaller, below current)
    f.change = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.change:SetPoint("LEFT", f.icon, "RIGHT", 6, -8)
    f.change:SetJustifyH("LEFT")

    -- Subtle separator at the bottom
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", PAD, 4)
    sep:SetPoint("BOTTOMRIGHT", -PAD, 4)
    sep:SetColorTexture(0.3, 0.25, 0.15, 0.4)

    frame = f
    return f
end

function GoldWidget:Update()
    if not frame then return end
    local gold = GetMoney() or 0
    frame.current:SetText(FormatGold(gold))

    local diff = gold - sessionStart
    if diff > 0 then
        frame.change:SetText("|cff44dd44Session +|r" .. FormatGold(diff))
    elseif diff < 0 then
        frame.change:SetText("|cffdd4444Session -|r" .. FormatGold(-diff))
    else
        frame.change:SetText("|cff666666Session no change|r")
    end

    if addon.WidgetHost and addon.WidgetHost.UpdateWidgetStatus then
        addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
    end
end

function GoldWidget:GetStatusText()
    return FormatGoldShort(GetMoney() or 0), 1, 0.82, 0
end

function GoldWidget:GetDesiredHeight() return DESIGN_HEIGHT end

function GoldWidget:Init()
    local f = self:Build()
    sessionStart = GetMoney() or 0

    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Gold Tracker",
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = f,
        GetDesiredHeight = function() return GoldWidget:GetDesiredHeight() end,
        GetStatusText    = function() return GoldWidget:GetStatusText() end,
    })

    f:RegisterEvent("PLAYER_MONEY")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:HookScript("OnEvent", function() GoldWidget:Update() end)

    self:Update()
end

BazCore:QueueForLogin(function() GoldWidget:Init() end)
