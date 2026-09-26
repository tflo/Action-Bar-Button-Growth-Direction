-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2023-2026 Thomas Floeren

local MYNAME, NS = ...

local DB_VERSION = 1
local debug = false

local function dprint(...)
	if debug then print('|cff33ff99'..MYNAME..'|r DEBUG:', ...) end
end
NS.dprint = dprint

--[[===========================================================================
	Init
===========================================================================]]--

local MAX_BAR_INDEX = 10
NS.MAX_BAR_INDEX = MAX_BAR_INDEX

local defaults = {
	db_version = DB_VERSION,
	enable = { y = 'some', x = 'none' },
	y = {
		[1] = true,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false,
		[7] = false,
		[8] = false,
		[9] = false, -- StanceBar
		[10] = false, -- PetActionBar
	},
	x = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false,
		[7] = false,
		[8] = false,
		[9] = false, -- StanceBar
		[10] = false, -- PetActionBar
	},
}
NS.defaults = defaults

-- We have `LoadSavedVariablesFirst: 1`

if type(ABBGD_db) ~= 'table' or ABBGD_db.db_version ~= DB_VERSION then
	-- Copy, so that user edits never alter `defaults` (the options panel's reset values).
	ABBGD_db = CopyTable(defaults)
end

-- The legacy, tainting methods 1/2 are gone; the field has no meaning anymore.
ABBGD_db.method = nil

-- Repair incomplete or hand-edited profiles (e.g. from before bars 9/10 existed).
local valid_enable = { none = true, some = true, all = true }
if type(ABBGD_db.enable) ~= 'table' then ABBGD_db.enable = {} end
for _, axis in ipairs { 'y', 'x' } do
	if not valid_enable[ABBGD_db.enable[axis]] then
		ABBGD_db.enable[axis] = defaults.enable[axis]
	end
	if type(ABBGD_db[axis]) ~= 'table' then ABBGD_db[axis] = {} end
	for idx = 1, MAX_BAR_INDEX do
		if type(ABBGD_db[axis][idx]) ~= 'boolean' then
			ABBGD_db[axis][idx] = defaults[axis][idx]
		end
	end
end

local db = ABBGD_db
NS.db = db

--[[===========================================================================
	Main

	NOTE :
	Writing to a bar's own fields (addButtonsToTop/addButtonsToRight) and/or
	calling a protected method (UpdateGridLayout/Layout) on it from insecure
	addon code permanently taints that secure frame for the whole session.
	Under the 12.0+ (and 1.60 beta) "secret values" security model this taint
	leaks into unrelated systems later touching the same frame (party frames,
	action button cooldowns, Edit Mode, etc.), throwing errors like
	"tainted by 'ActionBarButtonGrowthDirection'".

	To avoid this we never write to the bar's own table and never call any
	method on the bar itself. We only reposition its button container child
	frames directly, replicating Blizzard's own grid-layout math, and we always
	do this from a freshly scheduled (C_Timer.After) callback, so our code never
	runs inside a call stack that Blizzard itself initiated.

	The containers have secure action buttons anchored to them, so they are
	restricted in combat: any re-layout requested in combat is postponed until
	PLAYER_REGEN_ENABLED.

	Blizzard only re-lays out a bar when its cached grid settings change
	(ActionBarMixin:ShouldUpdateGrid), i.e. on Edit Mode changes or when the
	number of shown buttons changes (stance bar). Our events are only wake-ups:
	a bar is laid out again only if Blizzard re-laid it out since our last pass
	(see layout_token) or the settings changed, so most events cost nothing.
===========================================================================]]--

local map = {
	[1] = 'MainActionBar',
	[2] = 'MultiBarBottomLeft',
	[3] = 'MultiBarBottomRight',
	[4] = 'MultiBarRight',
	[5] = 'MultiBarLeft',
	[6] = 'MultiBar5',
	[7] = 'MultiBar6',
	[8] = 'MultiBar7',
	[9] = 'StanceBar',
	[10] = 'PetActionBar',
}
NS.map = map

-- Reproduces ActionBarMixin:UpdateGridLayout's math ourselves, but only ever
-- touches the button container children, never the bar itself.
local function apply_reversed_layout(name, frame, axes)
	if not frame or type(frame.shownButtonContainers) ~= 'table' then
		dprint('apply_reversed_layout: no frame or shownButtonContainers for', tostring(name))
		return
	end
	if type(GridLayoutUtil) ~= 'table' or type(AnchorUtil) ~= 'table' then
		dprint('apply_reversed_layout: GridLayoutUtil/AnchorUtil not available')
		return
	end
	local containers = frame.shownButtonContainers
	if #containers == 0 then
		dprint('apply_reversed_layout:', name, 'has 0 shown containers, skipping')
		return
	end

	local addTop = frame.addButtonsToTop
	if axes.y then
		addTop = not addTop
	end
	local addRight = frame.addButtonsToRight
	if axes.x then
		addRight = not addRight
	end

	local numRows = frame.numRows or 1
	local stride = math.max(1, math.ceil(#containers / numRows))
	local minPad = frame.minButtonPadding or 2
	local buttonPadding = math.max(minPad, frame.buttonPadding or minPad)
	local xMultiplier = addRight and 1 or -1
	local yMultiplier = addTop and 1 or -1

	local layout
	if frame.isHorizontal then
		layout = GridLayoutUtil.CreateStandardGridLayout(stride, buttonPadding, buttonPadding, xMultiplier, yMultiplier)
	else
		layout = GridLayoutUtil.CreateVerticalGridLayout(stride, buttonPadding, buttonPadding, xMultiplier, yMultiplier)
	end

	local anchorPoint
	if frame.addButtonsToLeft then
		anchorPoint = 'LEFT'
	elseif addTop then
		anchorPoint = addRight and 'BOTTOMLEFT' or 'BOTTOMRIGHT'
	else
		anchorPoint = addRight and 'TOPLEFT' or 'TOPRIGHT'
	end

	if debug then
		dprint(string.format(
			'apply_reversed_layout: %s containers=%d numRows=%s isHorizontal=%s addTop=%s addRight=%s stride=%d pad=%s anchor=%s',
			tostring(name), #containers, tostring(numRows), tostring(frame.isHorizontal),
			tostring(addTop), tostring(addRight), stride, tostring(buttonPadding), anchorPoint
		))
	end

	GridLayoutUtil.ApplyGridLayout(containers, AnchorUtil.CreateAnchor(anchorPoint, frame, anchorPoint), layout)
end

-- Bars to reverse, keyed by frame name: { frame = frame, axes = { y = true, x = true } }
local modified = {}
-- Bars we've ever touched, so we can restore their default layout
-- if a setting is turned off via the options panel without a UI reload.
local known_bars = {}

local function collect_modified_bars()
	wipe(modified)
	for axis, enableaxis in pairs(db.enable) do
		dprint('collect_modified_bars: axis', axis, 'enable', tostring(enableaxis))
		if enableaxis ~= 'none' then
			for idx, enablebar in pairs(db[axis]) do
				if enableaxis == 'all' or enablebar then
					local bar_name = map[idx]
					local frame = bar_name and _G[bar_name]
					if frame then
						modified[bar_name] = modified[bar_name] or { frame = frame, axes = {} }
						modified[bar_name].axes[axis] = true
						known_bars[bar_name] = frame
						dprint('collect_modified_bars: will reverse', axis, 'for', bar_name)
					else
						dprint('collect_modified_bars: bar not found', tostring(bar_name))
					end
				end
			end
		end
	end
end

-- Blizzard's UpdateGridLayout always stores a brand-new `oldGridSettings` table
-- (ActionBarMixin:CacheGridSettings) after laying out a bar. So if that table is
-- still the one we laid out over, Blizzard hasn't touched the bar since and our
-- layout still stands. `false` stands for "never laid out by Blizzard yet".
local function layout_token(frame)
	return frame.oldGridSettings or false
end

-- Per bar name: the layout_token our layout was last applied over.
local applied_over = {}
-- Set when the settings change; forces a full re-apply of all known bars.
local settings_dirty = true

local NO_AXES = {}

local function needs_reapply()
	if settings_dirty then return true end
	for name, frame in pairs(known_bars) do
		if applied_over[name] ~= layout_token(frame) then return true end
	end
	return false
end

local function reapply()
	local force = settings_dirty
	if force then
		collect_modified_bars()
		settings_dirty = false
	end
	local c = 0
	-- Iterate every bar we've touched, not just the currently-enabled ones,
	-- so unchecking a bar restores its default layout immediately.
	for name, frame in pairs(known_bars) do
		local token = layout_token(frame)
		if force or applied_over[name] ~= token then
			local entry = modified[name]
			apply_reversed_layout(name, frame, entry and entry.axes or NO_AXES)
			applied_over[name] = token
			c = c + 1
		end
	end
	dprint('reapply: laid out', c, 'bar(s), force', tostring(force))
end

local ef = CreateFrame 'Frame'

local reapply_pending = false
local function run_pending_reapply()
	reapply_pending = false
	if not needs_reapply() then return end
	if InCombatLockdown() then
		dprint('run_pending_reapply: in combat, waiting for PLAYER_REGEN_ENABLED')
		ef:RegisterEvent 'PLAYER_REGEN_ENABLED'
		return
	end
	reapply()
end

-- Always run on a freshly scheduled callback (next frame tick), so we never
-- execute right inside a call stack that Blizzard itself initiated.
-- Debounced: multiple events in the same frame only schedule one timer.
local function schedule_reapply(event)
	dprint('schedule_reapply: triggered by', tostring(event))
	if reapply_pending then return end
	reapply_pending = true
	C_Timer.After(0, run_pending_reapply)
end

-- For the options panel: settings changed, re-apply all known bars.
local function settings_changed(reason)
	settings_dirty = true
	schedule_reapply(reason)
end

-- expose settings_changed to the namespace for use by the options panel
NS.settings_changed = settings_changed

--[[===========================================================================
	Events
===========================================================================]]--

ef:RegisterEvent 'PLAYER_LOGIN'
ef:RegisterEvent 'PLAYER_ENTERING_WORLD'
ef:RegisterEvent 'ACTIONBAR_PAGE_CHANGED'
ef:RegisterEvent 'UPDATE_BONUS_ACTIONBAR'
ef:RegisterEvent 'UPDATE_VEHICLE_ACTIONBAR'
ef:RegisterEvent 'UPDATE_OVERRIDE_ACTIONBAR'
ef:RegisterEvent 'UPDATE_SHAPESHIFT_FORM'
ef:RegisterEvent 'ACTIONBAR_SHOW_BOTTOMLEFT'
ef:RegisterEvent 'UPDATE_EXTRA_ACTIONBAR'
ef:RegisterEvent 'UPDATE_POSSESS_BAR'
-- Blizzard re-lays out bars on Edit Mode changes
ef:RegisterEvent 'EDIT_MODE_LAYOUTS_UPDATED'
-- StanceBar re-lays out when the number of forms changes
ef:RegisterEvent 'UPDATE_SHAPESHIFT_FORMS'
-- PetActionBar triggers
ef:RegisterEvent 'PET_BAR_UPDATE'
ef:RegisterEvent 'UNIT_PET'
ef:RegisterEvent 'PLAYER_CONTROL_GAINED'
ef:RegisterEvent 'PLAYER_CONTROL_LOST'

ef:SetScript('OnEvent', function(self, event, unit)
	dprint('OnEvent:', event)

	-- UNIT_PET fires for any unit in the group; only react to our own pet.
	if event == 'UNIT_PET' and unit ~= 'player' then
		return
	end

	-- Only registered while a re-layout is waiting for combat to end.
	if event == 'PLAYER_REGEN_ENABLED' then
		self:UnregisterEvent 'PLAYER_REGEN_ENABLED'
	end

	schedule_reapply(event)
end)

-- Setting changes made inside Edit Mode re-lay out bars without an event.
if EventRegistry then
	EventRegistry:RegisterCallback('EditMode.Exit', function()
		schedule_reapply('EditMode.Exit')
	end, MYNAME)
end
