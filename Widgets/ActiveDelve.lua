-- BazWidgets Widget: Active Delve
--
-- Dormant widget that auto-shows when you're in any active scenario
-- (delves are scenarios). Shows the scenario name + objectives, and
-- delegates the tier badge / lives / affix icons to Blizzard's own
-- UIWidgetContainer registered for the scenario's widget set - same
-- approach BazWidgetDrawers' Quest Tracker uses.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID     = "bazwidgets_activedelve"
local DESIGN_WIDTH  = 260
local DESIGN_HEIGHT = 110
local PAD           = 8

-- Colors
local CLR_NAME    = { 1.00, 0.85, 0.45 }
local CLR_OBJ     = { 0.90, 0.90, 0.90 }
local CLR_OBJ_OK  = { 0.40, 1.00, 0.40 }
local CLR_DIM     = { 0.60, 0.60, 0.65 }
local CLR_TIER    = { 1.00, 0.82, 0.00 }

local Delve = {}
addon.ActiveDelveWidget = Delve

---------------------------------------------------------------------------
-- Scenario data fetcher (modelled after BWD QuestTracker/Scenario.lua)
---------------------------------------------------------------------------

local D = {
    inScenario  = false,
    name        = "",
    stageName   = "",
    objectives  = {},   -- list of { text, finished }
    widgetSetID = nil,  -- Blizzard widget set for tier/lives/affixes
    isComplete  = false,
}

local function FetchScenarioData()
    D.inScenario  = false
    D.name        = ""
    D.stageName   = ""
    D.objectives  = {}
    D.widgetSetID = nil
    D.isComplete  = false

    if not C_Scenario or not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
        return
    end
    if not C_Scenario.GetInfo then return end

    local scenarioName = C_Scenario.GetInfo()
    if not scenarioName then return end

    D.inScenario = true
    D.name       = scenarioName

    local stageName, stageDescription, numCriteria
    local widgetSetID
    if C_Scenario.GetStepInfo then
        local s1, s2, s3, _, _, _, _, _, _, _, _, s12 = C_Scenario.GetStepInfo()
        stageName        = s1
        stageDescription = s2
        numCriteria      = s3
        widgetSetID      = s12
    end
    numCriteria = numCriteria or 0
    D.stageName = stageName or ""
    D.widgetSetID = widgetSetID

    if stageDescription and stageDescription ~= "" and stageDescription ~= stageName then
        D.objectives[#D.objectives + 1] = { text = stageDescription, finished = false }
    end

    local allComplete = numCriteria > 0
    for i = 1, numCriteria do
        local info
        if C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
            local ok, data = pcall(C_ScenarioInfo.GetCriteriaInfo, i)
            if ok then info = data end
        end
        if info then
            local text = info.description or ""
            if not info.isWeightedProgress and not info.isFormatted
               and info.totalQuantity and info.totalQuantity >= 1 then
                text = string.format("%d/%d %s",
                    info.quantity or 0, info.totalQuantity, text)
            end
            D.objectives[#D.objectives + 1] = {
                text     = text,
                finished = info.completed and true or false,
            }
            if not info.completed then allComplete = false end
        end
    end

    if #D.objectives == 0 then
        D.objectives[#D.objectives + 1] = {
            text     = stageDescription or "In progress",
            finished = false,
        }
        allComplete = false
    end

    D.isComplete = allComplete
end

---------------------------------------------------------------------------
-- Frame construction
---------------------------------------------------------------------------

local frame
local objectiveLines = {}

function Delve:Build()
    if frame then return frame end

    -- No backdrop - let the widget sit flush against the drawer's own
    -- background. Blizzard's widget container provides its own visual
    -- styling for the delve card.
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)

    -- Blizzard UIWidget container for the delve card (name, tier badge,
    -- lives, affix icons). Same pattern BWD's Quest Tracker uses - we
    -- register for the scenario's widget set and Blizzard renders it.
    local widgetOk, widgetContainer = pcall(CreateFrame, "Frame", nil, f, "UIWidgetContainerTemplate")
    if widgetOk and widgetContainer then
        widgetContainer:Hide()
        widgetContainer:ClearAllPoints()
        widgetContainer:SetPoint("TOPLEFT", 0, 0)
        widgetContainer:SetPoint("TOPRIGHT", 0, 0)
        -- When the widget container resizes (Blizzard adds/removes art),
        -- re-flow our own layout so objectives sit below it.
        local pending = false
        widgetContainer:SetScript("OnSizeChanged", function()
            if pending then return end
            pending = true
            C_Timer.After(0.1, function()
                pending = false
                if frame then Delve:Refresh() end
            end)
        end)
        f.widgetContainer = widgetContainer
    end

    -- Container for objective lines (positioned below the widget container)
    f.objContainer = CreateFrame("Frame", nil, f)
    f.objContainer:SetPoint("LEFT", PAD, 0)
    f.objContainer:SetPoint("RIGHT", -PAD, 0)

    self._desiredHeight = DESIGN_HEIGHT
    frame = f
    return f
end

local NUB_SIZE = 12   -- matches Blizzard quest-tracker bullet size

local function GetOrCreateObjectiveLine(i)
    if objectiveLines[i] then return objectiveLines[i] end
    local row = CreateFrame("Frame", nil, frame.objContainer)
    row.bullet = row:CreateTexture(nil, "ARTWORK")
    row.bullet:SetSize(NUB_SIZE, NUB_SIZE)
    row.bullet:SetPoint("TOPLEFT", 0, -2)
    -- Default atlas - Refresh() swaps to the check atlas when complete
    row.bullet:SetAtlas("ui-questtracker-objective-nub", false)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("TOPLEFT", row.bullet, "TOPRIGHT", 6, 2)
    row.text:SetPoint("TOPRIGHT", 0, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(true)
    objectiveLines[i] = row
    return row
end

---------------------------------------------------------------------------
-- Refresh display
---------------------------------------------------------------------------

function Delve:Refresh()
    if not frame then return end

    -- Register the widget container for the scenario's widget set.
    -- Blizzard renders the delve card (name, tier, lives, affixes) itself.
    local wc = frame.widgetContainer
    local widgetH = 0
    if wc then
        if D.widgetSetID then
            if frame._registeredWidgetSetID ~= D.widgetSetID then
                wc:RegisterForWidgetSet(D.widgetSetID)
                frame._registeredWidgetSetID = D.widgetSetID
            end
            wc:Show()
            wc:ClearAllPoints()
            wc:SetPoint("TOPLEFT", 0, 0)
            wc:SetPoint("TOPRIGHT", 0, 0)
            widgetH = wc:GetHeight() or 0
        else
            if frame._registeredWidgetSetID then
                wc:RegisterForWidgetSet(nil)
                frame._registeredWidgetSetID = nil
            end
            wc:Hide()
        end
    end

    -- Position the objective container below the widget container
    local objY = -widgetH - 4
    frame.objContainer:ClearAllPoints()
    frame.objContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, objY)
    frame.objContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, objY)

    -- Hide all old objective lines
    for _, line in ipairs(objectiveLines) do line:Hide() end

    -- Render objectives
    local oy = 0
    local objH = 0
    for i, obj in ipairs(D.objectives) do
        local row = GetOrCreateObjectiveLine(i)
        row:SetPoint("TOPLEFT", frame.objContainer, "TOPLEFT", 0, oy)
        row:SetPoint("TOPRIGHT", frame.objContainer, "TOPRIGHT", 0, oy)
        row.text:SetText(obj.text or "")
        if obj.finished then
            row.text:SetTextColor(unpack(CLR_OBJ_OK))
            row.bullet:SetAtlas("ui-questtracker-tracker-check", false)
        else
            row.text:SetTextColor(unpack(CLR_OBJ))
            row.bullet:SetAtlas("ui-questtracker-objective-nub", false)
        end
        row:Show()
        local h = math.max(14, row.text:GetStringHeight() + 2)
        row:SetHeight(h)
        oy = oy - h - 2
        objH = objH + h + 2
    end
    frame.objContainer:SetHeight(math.max(objH, 1))

    -- Total widget height = widget container + spacing + objectives + padding
    local total = widgetH + 4 + objH + PAD
    self._desiredHeight = math.max(60, total)
end

---------------------------------------------------------------------------
-- Widget contract
---------------------------------------------------------------------------

function Delve:GetDesiredHeight()
    return self._desiredHeight or DESIGN_HEIGHT
end

function Delve:GetStatusText()
    if D.isComplete then
        return "Done!", unpack(CLR_OBJ_OK)
    end
    local remaining = 0
    for _, obj in ipairs(D.objectives) do
        if not obj.finished then remaining = remaining + 1 end
    end
    if remaining > 0 then
        return tostring(remaining), unpack(CLR_TIER)
    end
    return ""
end

---------------------------------------------------------------------------
-- Init - register dormant widget
---------------------------------------------------------------------------

function Delve:Init()
    local f = self:Build()

    -- Wire scenario events directly on the frame so we re-fetch + render
    -- whenever scenario state changes (LBW only re-evaluates the dormant
    -- condition; it doesn't drive per-event refreshes for us).
    f:RegisterEvent("SCENARIO_UPDATE")
    f:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
    f:RegisterEvent("SCENARIO_COMPLETED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function()
        FetchScenarioData()
        Delve:Refresh()
    end)

    -- Also refresh whenever the frame becomes visible (e.g. on activation
    -- by LBW, or when the drawer slides open).
    f:HookScript("OnShow", function()
        FetchScenarioData()
        Delve:Refresh()
    end)

    local widgetDef = {
        id           = WIDGET_ID,
        label        = "Active Delve",
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = f,
        GetDesiredHeight = function() return Delve:GetDesiredHeight() end,
        GetStatusText    = function() return Delve:GetStatusText() end,
    }

    local LBW = LibStub("LibBazWidget-1.0")
    LBW:RegisterDormantWidget(widgetDef, {
        events = {
            "SCENARIO_UPDATE",
            "SCENARIO_CRITERIA_UPDATE",
            "SCENARIO_COMPLETED",
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
        },
        condition = function()
            FetchScenarioData()
            return D.inScenario
        end,
    })
end

Delve:Init()
