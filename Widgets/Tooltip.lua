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
-- Frame builder
---------------------------------------------------------------------------

function Tooltip:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "BazWidgetsTooltipDock", UIParent)
    f:SetSize(DESIGN_WIDTH, DESIGN_HEIGHT)
    -- Slot is intentionally empty when no tooltip is showing — any
    -- placeholder text would just be visual noise and would still be
    -- visible when the user has the widget docked but inactive.

    -- When the drawer collapses, displayFrame:Hide() cascades through
    -- its descendants and our slot becomes invisible. The GameTooltip
    -- itself, however, lives under UIParent — anchoring it to a now-
    -- invisible frame doesn't move it off-screen, so without this
    -- hook the tooltip would hover at its last position even after
    -- the drawer slid shut. OnHide fires when our visibility chain
    -- breaks; if the live tooltip is still anchored to us at that
    -- moment, dismiss it. The user's next hover after re-opening
    -- the drawer will re-anchor naturally via SetDefaultAnchor.
    f:HookScript("OnHide", function()
        if GameTooltip and GameTooltip:IsShown() then
            local _, anchor = GameTooltip:GetPoint(1)
            if anchor == f then
                GameTooltip:Hide()
            end
        end
    end)

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

-- Floor for the dynamic scale — below this and the tooltip text gets
-- hard to read at any reasonable drawer width.
local MIN_SCALE = 0.5

-- Compute the tooltip scale that makes its rendered pixel width match
-- the slot's rendered pixel width. Returns nil if either width hasn't
-- resolved yet (tooltip just opened, no content yet).
local function ComputeFitScale(tooltip)
    if not frame then return nil end
    local naturalW = tooltip:GetWidth() or 0
    if naturalW < 1 then return nil end

    local frameW   = frame:GetWidth() or 0
    local frameEff = frame:GetEffectiveScale() or 1
    if frameW < 1 or frameEff < 0.001 then return nil end

    local ttParent = tooltip:GetParent()
    local ttParentEff = (ttParent and ttParent:GetEffectiveScale()) or 1
    if ttParentEff < 0.001 then ttParentEff = 1 end

    -- Solve for newScale such that
    --   naturalW * newScale * ttParentEff   ==   frameW * frameEff
    local s = (frameW * frameEff) / (naturalW * ttParentEff)
    if s > 1.0 then s = 1.0 end           -- never enlarge past natural
    if s < MIN_SCALE then s = MIN_SCALE end
    return s
end

local function ApplyAnchorTo(tooltip)
    if not frame then return end
    -- Skip when the slot itself isn't visible. This covers two cases
    -- with one check: (a) the user disabled the widget via the
    -- standard Enabled toggle, which calls widget.frame:Hide(); and
    -- (b) the drawer is collapsed, which hides our parent chain.
    -- In either case anchoring would resolve to an off-screen position
    -- and confuse the user.
    if not frame:IsVisible() then return end

    -- Scale the tooltip to fit the slot width before re-anchoring.
    -- Width may not be resolved at this point (SetDefaultAnchor often
    -- runs before content is set), so we apply a best-effort scale
    -- here and let OnSizeChanged refine it once content fills in.
    local s = ComputeFitScale(tooltip)
    if s then tooltip:SetScale(s) end

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

    -- Once content fills in, re-fit the scale (we may have anchored
    -- pre-content with no usable width) and recompute slot height so
    -- the drawer slot grows to match the rendered tooltip.
    --
    -- BWD's host scales the widget's frame by `frame:GetScale()` —
    -- our reported `_desiredHeight` is in design (pre-host-scale)
    -- coordinates. We want the rendered slot height to equal the
    -- tooltip's rendered pixel height, so:
    --   designHeight * hostScale  ==  ttLogicalH * ttScale
    --   designHeight = ttLogicalH * ttScale / hostScale
    GameTooltip:HookScript("OnSizeChanged", function(self)
        if not frame or not frame:IsVisible() then return end

        local s = ComputeFitScale(self)
        if s then self:SetScale(s) end

        local ttLogicalH = self:GetHeight() or 0
        local ttScale    = self:GetScale() or 1
        local hostScale  = frame:GetScale() or 1
        if hostScale < 0.001 then hostScale = 1 end

        local design = (ttLogicalH * ttScale) / hostScale
        if design < DESIGN_HEIGHT then design = DESIGN_HEIGHT end
        if math.abs(design - lastTooltipHeight) > 1 then
            lastTooltipHeight = design
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
-- Widget host hooks
---------------------------------------------------------------------------

function Tooltip:GetDesiredHeight()
    return math.max(lastTooltipHeight, DESIGN_HEIGHT)
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
    })

    InstallHooks()
end

BazCore:QueueForLogin(function() Tooltip:Init() end)
