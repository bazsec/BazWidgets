-- BazWidgets Widget: Bountiful Tracker
--
-- Surfaces delve-related currencies: Restored Coffer Keys (currency 3028)
-- and Coffer Key Shards (currency 3310, 100 shards = 1 key). Also auto-
-- discovers any other currency with "coffer" or "key shard" in its name.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_bountiful"
local DESIGN_WIDTH = 220
local PAD          = 8
local ROW_H        = 22

-- Known delve currency IDs.
-- 3028: Restored Coffer Key (Constants.DelvesConsts.DELVES_NORMAL_KEY_CURRENCY_ID)
-- 3310: Coffer Key Shards (100 shards = 1 key)
local KEY_CURRENCY_ID = 3028
local KNOWN_CURRENCIES = { 3028, 3310 }

-- Colors
local CLR_VALUE  = { 1.00, 0.85, 0.45 }
local CLR_LABEL  = { 0.90, 0.90, 0.90 }

local Bountiful = {}
addon.BountifulWidget = Bountiful

---------------------------------------------------------------------------
-- Currency scanning
---------------------------------------------------------------------------

-- Discover all delve-related currencies. Always includes the known
-- key (3028) and shards (3310). Also walks the player's currency list
-- for anything else with "coffer" or "key shard" in its name.
local function ScanDelveCurrencies()
    local found = {}
    local seen = {}

    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        for _, id in ipairs(KNOWN_CURRENCIES) do
            local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and info and info.name and not seen[id] then
                found[#found + 1] = { id = id, info = info }
                seen[id] = true
            end
        end
    end

    if C_CurrencyInfo
       and C_CurrencyInfo.GetCurrencyListSize
       and C_CurrencyInfo.GetCurrencyListInfo
       and C_CurrencyInfo.GetCurrencyListLink then
        local count = C_CurrencyInfo.GetCurrencyListSize() or 0
        for i = 1, count do
            local listInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
            if listInfo and not listInfo.isHeader and listInfo.name then
                local n = listInfo.name:lower()
                if n:find("coffer") or n:find("key shard") then
                    local link = C_CurrencyInfo.GetCurrencyListLink(i)
                    local id
                    if link then id = tonumber(link:match("currency:(%d+)")) end
                    if id and not seen[id] then
                        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
                        if ok and info then
                            found[#found + 1] = { id = id, info = info }
                            seen[id] = true
                        end
                    end
                end
            end
        end
    end

    return found
end

---------------------------------------------------------------------------
-- Frame construction
---------------------------------------------------------------------------

local frame
local rows = {}

local function GetOrCreateRow(i)
    if rows[i] then return rows[i] end
    local row = CreateFrame("Frame", nil, frame)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18, 18)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.qty = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.qty:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.qty:SetJustifyH("LEFT")
    row.qty:SetTextColor(unpack(CLR_VALUE))

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row.qty, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", 0, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetTextColor(unpack(CLR_LABEL))

    rows[i] = row
    return row
end

function Bountiful:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(DESIGN_WIDTH, PAD * 2 + ROW_H)

    f.rowContainer = CreateFrame("Frame", nil, f)
    f.rowContainer:SetPoint("TOPLEFT", PAD, -PAD)
    f.rowContainer:SetPoint("RIGHT", -PAD, 0)
    f.rowContainer:SetHeight(ROW_H)

    -- Wipe any stale state from the prior version that tracked usage,
    -- so saved variables don't grow.
    if addon.SetWidgetSetting then
        addon:SetWidgetSetting(WIDGET_ID, "state", nil)
    end

    self._desiredHeight = PAD * 2 + ROW_H
    frame = f
    return f
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

function Bountiful:Refresh()
    if not frame then return end

    local entries = ScanDelveCurrencies()

    for _, row in ipairs(rows) do row:Hide() end

    local y = 0
    for i, entry in ipairs(entries) do
        local row = GetOrCreateRow(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.rowContainer, "TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", frame.rowContainer, "TOPRIGHT", 0, y)
        row:SetHeight(ROW_H - 2)
        row:Show()

        if entry.info.iconFileID then
            row.icon:SetTexture(entry.info.iconFileID)
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        local qty = entry.info.quantity or 0
        local maxQty = entry.info.maxQuantity or 0
        if maxQty and maxQty > 0 then
            row.qty:SetText(qty .. "|cff999999/" .. maxQty .. "|r")
        else
            row.qty:SetText(tostring(qty))
        end

        row.label:SetText(entry.info.name or "")
        y = y - ROW_H
    end

    if #entries == 0 then
        local row = GetOrCreateRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.rowContainer, "TOPLEFT", 0, 0)
        row:SetPoint("TOPRIGHT", frame.rowContainer, "TOPRIGHT", 0, 0)
        row:SetHeight(ROW_H)
        row:Show()
        row.icon:SetTexture(nil)
        row.qty:SetText("")
        row.label:SetText("|cff888888No delve currencies found|r")
        y = -ROW_H
    end

    frame.rowContainer:SetHeight(math.max(ROW_H, math.abs(y)))
    self._desiredHeight = PAD * 2 + math.abs(y)

    if addon.WidgetHost and addon.WidgetHost.UpdateWidgetStatus then
        addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
    end
end

---------------------------------------------------------------------------
-- Widget contract
---------------------------------------------------------------------------

function Bountiful:GetDesiredHeight()
    return self._desiredHeight or (PAD * 2 + ROW_H)
end

function Bountiful:GetStatusText()
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, KEY_CURRENCY_ID)
    if ok and info and info.quantity then
        return tostring(info.quantity), unpack(CLR_VALUE)
    end
    return ""
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function Bountiful:Init()
    local f = self:Build()

    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Bountiful Tracker",
        designWidth  = DESIGN_WIDTH,
        designHeight = PAD * 2 + ROW_H,
        frame        = f,
        GetDesiredHeight = function() return Bountiful:GetDesiredHeight() end,
        GetStatusText    = function() return Bountiful:GetStatusText() end,
    })

    f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:HookScript("OnEvent", function() Bountiful:Refresh() end)

    self:Refresh()
end

BazCore:QueueForLogin(function() Bountiful:Init() end)
