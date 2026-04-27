-- BazWidgets Widget: Delve Timer
--
-- Dormant widget that auto-shows when you're inside a delve scenario.
-- Tracks your run time, compares against your best time for that delve
-- (account-wide), and saves a new best when you beat it.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID    = "bazwidgets_delvetimer"
local DESIGN_WIDTH = 220
local DESIGN_HEIGHT = 64
local PAD          = 8

-- Colors
local CLR_NAME    = { 1.00, 0.85, 0.45 }
local CLR_TIME    = { 1.00, 0.95, 0.85 }
local CLR_BEST    = { 0.65, 0.85, 1.00 }
local CLR_NEW_PB  = { 0.40, 1.00, 0.40 }
local CLR_DIM     = { 0.65, 0.65, 0.70 }

local Timer = {}
addon.DelveTimerWidget = Timer

---------------------------------------------------------------------------
-- Saved best times - account-wide, stored on BazCoreDB so they survive
-- per-character data wipes and propagate to all toons.
---------------------------------------------------------------------------

local function GetBestTimes()
    BazCoreDB = BazCoreDB or {}
    BazCoreDB.delveTimerBests = BazCoreDB.delveTimerBests or {}
    return BazCoreDB.delveTimerBests
end

-- Best times are keyed by scenarioID (so different variants of the
-- same-named delve don't lump together - each layout gets its own PB).
-- Falls back to name when no scenarioID is available.
local function MakeKey(scenarioID, name)
    if scenarioID and scenarioID > 0 then
        return "id:" .. scenarioID
    elseif name and name ~= "" then
        return "name:" .. name
    end
    return nil
end

local function GetBestForDelve(scenarioID, name)
    local key = MakeKey(scenarioID, name)
    if not key then return nil end
    local entry = GetBestTimes()[key]
    if type(entry) == "number" then return entry end       -- legacy scalar
    return entry and entry.time or nil
end

local function SaveBestForDelve(scenarioID, name, seconds)
    if not seconds or seconds <= 0 then return end
    local key = MakeKey(scenarioID, name)
    if not key then return end
    GetBestTimes()[key] = {
        id   = scenarioID,
        name = name,
        time = seconds,
    }
end

---------------------------------------------------------------------------
-- Time formatting
---------------------------------------------------------------------------

local function FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    end
    return string.format("%d:%02d", m, s)
end

---------------------------------------------------------------------------
-- Run state
---------------------------------------------------------------------------

local R = {
    inDelve     = false,
    delveName   = "",
    scenarioID  = nil,    -- per-variant identifier
    runStartGT  = nil,    -- GetTime() at run start
    runEndGT    = nil,    -- GetTime() at run end (nil while running)
    isNewBest   = false,
    completed   = false,
}

local function FetchScenario()
    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        R.inDelve = false
        return
    end
    R.inDelve = true
    if C_Scenario.GetInfo then
        -- C_Scenario.GetInfo returns:
        --   name, currentStage, numStages, flags, hasBonusStep,
        --   isBonusStepComplete, completed, xp, money, scenarioType,
        --   areaName, textureKit, scenarioID
        local name, _, _, _, _, _, _, _, _, _, _, _, scenarioID = C_Scenario.GetInfo()
        if name then R.delveName = name end
        if scenarioID and scenarioID > 0 then R.scenarioID = scenarioID end
    end
end

local function StartRun()
    if R.runStartGT then return end       -- already running
    R.runStartGT = GetTime()
    R.runEndGT   = nil
    R.isNewBest  = false
    R.completed  = false
end

local function EndRun(completed)
    if not R.runStartGT then return end   -- nothing to end
    R.runEndGT  = GetTime()
    R.completed = completed and true or false

    if R.completed then
        local elapsed = R.runEndGT - R.runStartGT
        local prev    = GetBestForDelve(R.scenarioID, R.delveName)
        if not prev or elapsed < prev then
            SaveBestForDelve(R.scenarioID, R.delveName, elapsed)
            R.isNewBest = true
        end
    end
end

local function ResetRun()
    R.runStartGT = nil
    R.runEndGT   = nil
    R.isNewBest  = false
    R.completed  = false
end

---------------------------------------------------------------------------
-- Frame construction
---------------------------------------------------------------------------

local frame

function Timer:Build()
    if frame then return frame end

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)

    -- Delve name (top)
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.name:SetPoint("TOPLEFT", PAD, -PAD + 2)
    f.name:SetPoint("RIGHT", -PAD, 0)
    f.name:SetJustifyH("LEFT")
    f.name:SetTextColor(unpack(CLR_NAME))
    f.name:SetWordWrap(false)

    -- Live timer (large, center)
    f.time = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.time:SetPoint("LEFT", PAD, -2)
    f.time:SetJustifyH("LEFT")
    f.time:SetTextColor(unpack(CLR_TIME))

    -- Best/PB indicator (right)
    f.best = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.best:SetPoint("RIGHT", -PAD, -2)
    f.best:SetJustifyH("RIGHT")
    f.best:SetTextColor(unpack(CLR_BEST))

    -- Bottom separator line
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", PAD, 4)
    sep:SetPoint("BOTTOMRIGHT", -PAD, 4)
    sep:SetColorTexture(0.30, 0.25, 0.15, 0.4)

    -- OnUpdate ticker drives the live readout while a run is active
    local accum = 0
    f:SetScript("OnUpdate", function(self, dt)
        accum = accum + dt
        if accum < 0.1 then return end
        accum = 0
        if R.runStartGT and not R.runEndGT then
            Timer:RefreshDisplay()
        end
    end)

    frame = f
    return f
end

---------------------------------------------------------------------------
-- Display refresh
---------------------------------------------------------------------------

function Timer:RefreshDisplay()
    if not frame then return end

    local elapsed
    if R.runStartGT then
        elapsed = (R.runEndGT or GetTime()) - R.runStartGT
    end

    frame.name:SetText(R.delveName ~= "" and R.delveName or "Delve")

    if elapsed then
        frame.time:SetText(FormatTime(elapsed))
        if R.completed then
            frame.time:SetTextColor(unpack(CLR_NEW_PB))
        else
            frame.time:SetTextColor(unpack(CLR_TIME))
        end
    else
        frame.time:SetText("--:--")
        frame.time:SetTextColor(unpack(CLR_DIM))
    end

    -- Best / PB indicator
    if R.isNewBest then
        frame.best:SetText("|cff40ff40NEW BEST!|r")
    else
        local best = GetBestForDelve(R.scenarioID, R.delveName)
        if best then
            frame.best:SetText("Best: |cffaaccff" .. FormatTime(best) .. "|r")
        else
            frame.best:SetText("|cff666666First run|r")
        end
    end

    if addon.WidgetHost and addon.WidgetHost.UpdateWidgetStatus then
        addon.WidgetHost:UpdateWidgetStatus(WIDGET_ID)
    end
end

---------------------------------------------------------------------------
-- Widget contract
---------------------------------------------------------------------------

function Timer:GetDesiredHeight() return DESIGN_HEIGHT end

function Timer:GetStatusText()
    if R.runStartGT and not R.runEndGT then
        local elapsed = GetTime() - R.runStartGT
        return FormatTime(elapsed), unpack(CLR_TIME)
    end
    return ""
end

function Timer:GetOptionsArgs()
    return {
        header = {
            order = 1,
            type = "header",
            name = "Delve Timer",
        },
        intro = {
            order = 2,
            type = "lead",
            text = "Auto-tracks how long each delve takes and remembers your best time per delve (account-wide). Beating your best shows a |cff40ff40NEW BEST!|r flash.",
        },
        clearAll = {
            order = 10,
            type = "execute",
            name = "|cffff4444Clear All Best Times|r",
            desc = "Wipe every saved personal best across all delves. Cannot be undone.",
            confirm = true,
            confirmText = "Wipe ALL saved best delve times for this account?",
            func = function()
                BazCoreDB.delveTimerBests = {}
                Timer:RefreshDisplay()
            end,
        },
    }
end

---------------------------------------------------------------------------
-- Init - register dormant widget
---------------------------------------------------------------------------

function Timer:Init()
    local f = self:Build()

    f:RegisterEvent("SCENARIO_UPDATE")
    f:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
    f:RegisterEvent("SCENARIO_COMPLETED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function(_, event)
        local wasInDelve = R.inDelve
        FetchScenario()

        if R.inDelve and not wasInDelve then
            -- Just entered a delve - start a fresh run
            ResetRun()
            StartRun()
        elseif R.inDelve and event == "SCENARIO_COMPLETED" then
            -- Finished it - record the time
            EndRun(true)
        elseif not R.inDelve and wasInDelve then
            -- Left without completing - discard the run, no PB save
            ResetRun()
        end

        Timer:RefreshDisplay()
    end)
    f:HookScript("OnShow", function()
        FetchScenario()
        Timer:RefreshDisplay()
    end)

    local widgetDef = {
        id           = WIDGET_ID,
        label        = "Delve Timer",
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = f,
        GetDesiredHeight = function() return Timer:GetDesiredHeight() end,
        GetStatusText    = function() return Timer:GetStatusText() end,
        GetOptionsArgs   = function() return Timer:GetOptionsArgs() end,
    }

    local LBW = LibStub("LibBazWidget-1.0")
    LBW:RegisterDormantWidget(widgetDef, {
        events = {
            "SCENARIO_UPDATE",
            "SCENARIO_COMPLETED",
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
        },
        condition = function()
            FetchScenario()
            return R.inDelve
        end,
    })
end

Timer:Init()
