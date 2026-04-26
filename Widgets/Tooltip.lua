-- BazWidgets Widget: Tooltip
--
-- A docked slot whose only job is to be the anchor for the global
-- GameTooltip. Hooks `GameTooltip_SetDefaultAnchor` to reroute every
-- default-anchored tooltip into this widget's frame, so item / unit /
-- spell hover tooltips appear inside the drawer instead of floating
-- at the cursor or screen edge.
--
-- Defaults to bottom-of-drawer docking (the natural place for a
-- tooltip — stacks upward as content grows). Per-widget toggle to
-- pause the anchor override without removing the widget.

local addon = BazCore:GetAddon("BazWidgetDrawers")
if not addon then return end

local WIDGET_ID     = "bazwidgets_tooltip"
local DESIGN_WIDTH  = 280
local DESIGN_HEIGHT = 60   -- minimum slot footprint when no tooltip is up
local PAD           = 4

local Tooltip = {}
addon.TooltipWidget = Tooltip

local frame              -- the widget's own frame (sits in the drawer slot)
local hookInstalled      = false
local lastTooltipHeight  = DESIGN_HEIGHT  -- last GameTooltip height we saw

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

local function IsActive()
    -- Per-widget toggle — defaults to true so the widget does its job
    -- the moment the user enables it.
    local v = addon:GetWidgetSetting(WIDGET_ID, "active", true)
    return v ~= false
end

---------------------------------------------------------------------------
-- Frame builder
---------------------------------------------------------------------------

function Tooltip:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsTooltipDock", UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)
    -- Subtle dashed outline so an empty slot is visually present even
    -- when no tooltip is showing — gives the user feedback that this
    -- IS the dock and not a layout glitch.
    f.placeholder = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.placeholder:SetPoint("CENTER")
    f.placeholder:SetText("Hover for tooltip")
    f.placeholder:SetTextColor(0.6, 0.6, 0.6, 0.8)
    frame = f
    return f
end

---------------------------------------------------------------------------
-- Anchor hook
--
-- GameTooltip_SetDefaultAnchor is what most of Blizzard's hover code
-- calls when an item/unit/etc. tooltip needs a default position. By
-- hook-overriding the anchor inside that function we capture the
-- common cases (bag, action bar, unit frame, quest log, etc.). Some
-- addons that hardcode `GameTooltip:SetOwner(self, "ANCHOR_RIGHT")`
-- bypass this — those keep their own anchor, which is fine.
---------------------------------------------------------------------------

local function ApplyAnchorTo(tooltip)
    if not frame then return end
    if not IsActive() then return end
    tooltip:ClearAllPoints()
    -- BOTTOMRIGHT-anchor so the tooltip's bottom edge stays planted on
    -- our slot's bottom-right; content extends up and to the left as
    -- the tooltip grows. Matches the standard "bottom-right pinned
    -- tooltip" UX.
    tooltip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

local function InstallHooks()
    if hookInstalled then return end
    hookInstalled = true

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if tooltip == GameTooltip then
            ApplyAnchorTo(tooltip)
        end
    end)

    -- Track the live tooltip height so the widget can grow / shrink
    -- alongside the visible tooltip. Drives _desiredHeight, which BWD's
    -- WidgetHost reads to size the slot.
    GameTooltip:HookScript("OnSizeChanged", function(self)
        if not IsActive() then return end
        local h = self:GetHeight() or DESIGN_HEIGHT
        if h < DESIGN_HEIGHT then h = DESIGN_HEIGHT end
        if math.abs(h - lastTooltipHeight) > 1 then
            lastTooltipHeight = h
            if addon.WidgetHost and addon.WidgetHost.Reflow then
                addon.WidgetHost:Reflow()
            end
        end
    end)

    -- When the tooltip closes, fall back to the minimum slot height.
    GameTooltip:HookScript("OnHide", function()
        if math.abs(lastTooltipHeight - DESIGN_HEIGHT) > 1 then
            lastTooltipHeight = DESIGN_HEIGHT
            if addon.WidgetHost and addon.WidgetHost.Reflow then
                addon.WidgetHost:Reflow()
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Per-widget settings
---------------------------------------------------------------------------

function Tooltip:GetOptionsArgs()
    return {
        activeHeader = {
            order = 1,
            type  = "header",
            name  = "Tooltip Anchor",
        },
        active = {
            order = 2,
            type  = "toggle",
            name  = "Anchor Tooltips Here",
            desc  = "When on, default-anchored tooltips (item / unit / spell / quest hovers) appear inside this widget's slot in the drawer, growing upward from the bottom. When off, the slot stays in place but Blizzard's normal anchoring is used.",
            get   = function() return IsActive() end,
            set   = function(_, val)
                addon:SetWidgetSetting(WIDGET_ID, "active", val and true or false)
            end,
        },
        note = {
            order = 3,
            type  = "note",
            style = "info",
            text  = "Some addons hardcode their own tooltip anchor (e.g. ANCHOR_RIGHT off a button) and will keep it — this widget only redirects tooltips that use the default anchor. Coverage is typically ~80%: bags, action bars, unit frames, quest log, character pane.",
        },
    }
end

---------------------------------------------------------------------------
-- Widget host hooks
---------------------------------------------------------------------------

function Tooltip:GetDesiredHeight()
    return math.max(lastTooltipHeight, DESIGN_HEIGHT)
end

function Tooltip:GetStatusText()
    if IsActive() then
        return "active", 0.5, 0.95, 0.5
    end
    return "off", 0.7, 0.7, 0.7
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function Tooltip:Init()
    local f = self:Build()

    BazCore:RegisterDockableWidget({
        id           = WIDGET_ID,
        label        = "Tooltip",
        designWidth  = DESIGN_WIDTH,
        designHeight = DESIGN_HEIGHT,
        frame        = f,
        -- Tooltip belongs at the drawer bottom by default — grows
        -- upward as content expands, which matches how BOTTOMRIGHT-
        -- pinned tooltips naturally behave.
        defaultDockToBottom = true,
        GetDesiredHeight    = function() return Tooltip:GetDesiredHeight() end,
        GetStatusText       = function() return Tooltip:GetStatusText() end,
        GetOptionsArgs      = function() return Tooltip:GetOptionsArgs() end,
    })

    InstallHooks()
end

BazCore:QueueForLogin(function() Tooltip:Init() end)
