-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2023-2026 Thomas Floeren

local addon_name, a = ...

local db_version_required = 1
local debug = false
local modified = {}

local _

local function dprint(...)
	if debug then print(addon_name, 'DEBUG:', ...) end
end

local defaults = {
	db_version = db_version_required,
	method = 1,
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
		[9] = false,
		[10] = false,
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
		[10] = false,
	},
}

local map = {
	-- updated to match Blizzard's current frame name (MainActionBar) while
	-- keeping a fallback resolver for older clients using MainMenuBar.
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

-- Fallbacks for frames that were renamed in recent client patches
local fallback_map = {
	-- known rename: MainMenuBar -> MainActionBar. Add both directions so we can
	-- resolve either name on older or newer clients.
	['MainMenuBar'] = 'MainActionBar',
	['MainActionBar'] = 'MainMenuBar',
}

local function resolve_bar_name(name)
	if type(name) ~= 'string' then return nil end
	if _G[name] then return name end
	if fallback_map[name] and _G[fallback_map[name]] then return fallback_map[name] end
	-- Generic substitution in case of simple renames
	local alt = name:gsub('MainMenuBar', 'MainActionBar')
	if alt ~= name and _G[alt] then return alt end
	return nil
end

-- Try to resolve a frame from either a name or an existing frame object.
-- Returns: frame, resolvedName
local function TryGetFrame(nameOrFrame)
	if type(nameOrFrame) == 'table' then
		-- already a frame-like object; try to get its name if available
		local okName = nil
		if type(nameOrFrame.GetName) == 'function' then
			okName = nameOrFrame:GetName()
		end
		return nameOrFrame, okName
	end
	if type(nameOrFrame) ~= 'string' then
		return nil, nil
	end
	local resolved = resolve_bar_name(nameOrFrame) or nameOrFrame
	local frame = _G[resolved]
	if frame then
		return frame, resolved
	end
	return nil, nil
end

local reverse_growth = {
	-- Accepts: axis, frame, optName
	[1] = function(axis, frame, optName)
		if not frame then
			dprint('reverse_growth[1]: frame not found', tostring(optName))
			return
		end
		if axis == 'y' then
			frame.addButtonsToTop = not frame.addButtonsToTop
		else
			frame.addButtonsToRight = not frame.addButtonsToRight
		end
	end,
	[2] = function(axis, frame, optName)
		if not frame then
			dprint('reverse_growth[2]: frame not found', tostring(optName))
			return
		end
		if axis == 'y' then
			hooksecurefunc(frame, 'UpdateGridLayout', function(self)
				self.addButtonsToTop = not self.addButtonsToTop
			end)
		else
			hooksecurefunc(frame, 'UpdateGridLayout', function(self)
				self.addButtonsToRight = not self.addButtonsToRight
			end)
		end
	end,
}

local function modify_bars()
	for axis, enableaxis in pairs(a.db.enable) do
		if enableaxis ~= 'none' then
			local bars = a.db[axis]
			if type(bars) == 'table' then
				for idx, enablebar in pairs(bars) do
					if enableaxis == 'all' or enablebar then
						local barName = map[idx]
						local frame, resolved = TryGetFrame(barName)
						if frame then
							reverse_growth[a.db.method](axis, frame, resolved or barName)
							-- Store the resolved frame to avoid re-resolving later
							modified[resolved or barName] = frame
						else
							-- Frame not present; simply log. No deferred retry.
							dprint('modify_bars: bar not found', tostring(barName))
						end
					end
				end
			end
		end
	end
end


local function update_grid_layouts()
	local c = 0
	for name, frame in pairs(modified) do
		if frame and type(frame.UpdateGridLayout) == 'function' then
			frame:UpdateGridLayout()
			c = c + 1
		else
			dprint('update_grid_layouts: could not update', tostring(name))
		end
	end
	wipe(modified)
	dprint('updated', c, 'modified action bars(s).')
end


-- pending hook retry logic removed; frames not found are logged instead


local ef = CreateFrame 'Frame'
ef:RegisterEvent 'ADDON_LOADED'
ef:RegisterEvent 'PLAYER_LOGIN'

ef:SetScript('OnEvent', function(self, event, ...)
	if event == 'ADDON_LOADED' then
		self:UnregisterEvent 'ADDON_LOADED'
		if not ABBGD_db or ABBGD_db.db_version ~= db_version_required then
			ABBGD_db = defaults
		end
		a.db = ABBGD_db
		if a.db.method == 2 then
			modify_bars()
		end
	else
		if a.db.method == 1 then
			modify_bars()
		end
		update_grid_layouts()
	end
end)



--[[ Notes =====================================================================

	The hooked function (method 2) has to run twice after the hook to actually
	apply the modified attribute. So we let it be run by the client during the
	loading process, and at login we run it once again.


	Action Bar 1: MainActionBar (previously MainMenuBar)
	Action Bar 2: MultiBarBottomLeft
	Action Bar 3: MultiBarBottomRight
	Action Bar 4: MultiBarRight
	Action Bar 5: MultiBarLeft
	Action Bar 6: MultiBar5
	Action Bar 7: MultiBar6
	Action Bar 8: MultiBar7

==============================================================================]]
