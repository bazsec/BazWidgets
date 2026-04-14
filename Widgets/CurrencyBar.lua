-- BazWidgets Widget: Currency Bar
--
-- Tracks selected currencies in a compact list with icons.
-- Auto-detects relevant tracked currencies from the player's currency list.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_currency"
local DESIGN_WIDTH = 220
local PAD          = 8
local ROW_HEIGHT   = 18
local ICON_SIZE    = 16
local MAX_ROWS     = 6

local CurrencyWidget = {}
local frame
local currentCount = 0

-- Get the user's selected currency ID list (saved per widget)
local function GetSelectedIDs()
    return addon:GetWidgetSetting(WIDGET_ID, "selectedIDs", {}) or {}
end

local function SetSelectedIDs(ids)
    addon:SetWidgetSetting(WIDGET_ID, "selectedIDs", ids or {})
end

local function IsSelected(id)
    for _, cid in ipairs(GetSelectedIDs()) do
        if cid == id then return true end
    end
    return false
end

local function ToggleSelected(id, on)
    local ids = GetSelectedIDs()
    if on then
        for _, cid in ipairs(ids) do
            if cid == id then return end
        end
        ids[#ids + 1] = id
    else
        for i, cid in ipairs(ids) do
            if cid == id then table.remove(ids, i); break end
        end
    end
    SetSelectedIDs(ids)
end

-- Walk the player's known currency list (Currency UI tab)
local function GetKnownCurrencies()
    local list = {}
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyListSize then return list end
    for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info and not info.isHeader and info.name and info.name ~= "" then
            local link = C_CurrencyInfo.GetCurrencyListLink(i)
            local id = link and tonumber(link:match("currency:(%d+)"))
            if id then
                list[#list + 1] = {
                    id = id,
                    name = info.name,
                    iconFileID = info.iconFileID,
                    quantity = info.quantity,
                    maxQuantity = info.maxQuantity,
                }
            end
        end
    end
    return list
end

-- Get tracked currencies: user-selected first, fallback to backpack tracker
local function GetTrackedCurrencies()
    local selected = GetSelectedIDs()
    if #selected > 0 then
        local list = {}
        for _, id in ipairs(selected) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if info and info.name then
                list[#list + 1] = {
                    id = id,
                    name = info.name,
                    iconFileID = info.iconFileID,
                    quantity = info.quantity,
                    maxQuantity = info.maxQuantity,
                }
            end
        end
        return list
    end
    -- Fallback to backpack tracker
    local list = {}
    if C_CurrencyInfo.GetBackpackCurrencyInfo then
        for i = 1, 5 do
            local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
            if info and info.name then
                list[#list + 1] = info
            end
        end
    end
    return list
end

local function FormatNumber(n)
    n = n or 0
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 10000 then return string.format("%.1fk", n / 1000) end
    return tostring(n)
end

function CurrencyWidget:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsCurrencyBar", UIParent)
    f:SetSize(DESIGN_WIDTH, PAD * 2 + ROW_HEIGHT)
    f.rows = {}
    frame = f
    return f
end

function CurrencyWidget:Update()
    if not frame then return end

    -- Hide all existing rows
    for _, row in ipairs(frame.rows) do
        row:Hide()
    end

    local currencies = GetTrackedCurrencies()
    currentCount = #currencies

    if #currencies == 0 then
        if not frame.empty then
            frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            frame.empty:SetPoint("CENTER", 0, 0)
            frame.empty:SetText("|cff666666Pick currencies in\nWidget Settings|r")
            frame.empty:SetJustifyH("CENTER")
        end
        frame.empty:Show()
        frame:SetHeight(PAD * 2 + 32)
        if addon.WidgetHost and addon.WidgetHost.Reflow then
            addon.WidgetHost:Reflow()
        end
        return
    end
    if frame.empty then frame.empty:Hide() end

    local y = -PAD
    for i, info in ipairs(currencies) do
        if i > MAX_ROWS then break end
        local row = frame.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, frame)
            row:SetSize(DESIGN_WIDTH - PAD * 2, ROW_HEIGHT)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(ICON_SIZE, ICON_SIZE)
            row.icon:SetPoint("LEFT", 0, 0)
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
            row.name:SetTextColor(0.9, 0.9, 0.9)
            row.value = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.value:SetPoint("RIGHT", 0, 0)
            row.value:SetTextColor(1, 0.82, 0)
            frame.rows[i] = row
        end
        row.icon:SetTexture(info.iconFileID)
        row.name:SetText(info.name)
        if info.maxQuantity and info.maxQuantity > 0 then
            row.value:SetText(FormatNumber(info.quantity) .. "|cff888888 / " .. FormatNumber(info.maxQuantity) .. "|r")
        else
            row.value:SetText(FormatNumber(info.quantity))
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PAD, y)
        row:SetPoint("TOPRIGHT", -PAD, y)
        row:Show()
        y = y - ROW_HEIGHT
    end

    frame:SetHeight(PAD * 2 + ROW_HEIGHT * math.min(#currencies, MAX_ROWS))

    if addon.WidgetHost then
        if addon.WidgetHost.UpdateWidgetStatus then
            addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
        end
        if addon.WidgetHost.Reflow then addon.WidgetHost:Reflow() end
    end
end

function CurrencyWidget:GetStatusText()
    return tostring(currentCount), 1, 0.82, 0
end

function CurrencyWidget:GetDesiredHeight()
    if not frame then return PAD * 2 + ROW_HEIGHT end
    return frame:GetHeight()
end

function CurrencyWidget:GetOptionsArgs()
    local args = {
        header = {
            order = 1,
            type = "header",
            name = "Currencies to Track",
        },
        desc = {
            order = 2,
            type = "description",
            name = "Pick which currencies appear in the widget. If none are selected, the widget shows whatever is in your default backpack tracker.",
            fontSize = "small",
        },
    }

    local known = GetKnownCurrencies()
    for i, info in ipairs(known) do
        local id = info.id
        args["cur_" .. id] = {
            order = 10 + i,
            type = "toggle",
            name = "|T" .. (info.iconFileID or 134400) .. ":16:16:0:0|t " .. info.name,
            get = function() return IsSelected(id) end,
            set = function(_, val)
                ToggleSelected(id, val)
                CurrencyWidget:Update()
            end,
        }
    end

    if #known == 0 then
        args.empty = {
            order = 10,
            type = "description",
            name = "|cff888888No known currencies found yet. Open the Currency tab to populate this list.|r",
        }
    end

    return args
end

function CurrencyWidget:Init()
    local f = self:Build()
    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Currencies",
        designWidth  = DESIGN_WIDTH,
        designHeight = PAD * 2 + ROW_HEIGHT * 3,
        frame        = f,
        GetDesiredHeight = function() return CurrencyWidget:GetDesiredHeight() end,
        GetStatusText    = function() return CurrencyWidget:GetStatusText() end,
        GetOptionsArgs   = function() return CurrencyWidget:GetOptionsArgs() end,
    })

    f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:HookScript("OnEvent", function() CurrencyWidget:Update() end)

    self:Update()
end

BazCore:QueueForLogin(function() CurrencyWidget:Init() end)
