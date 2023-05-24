local addon_name, a = ...

local db_version_required = 1
local debug = false
local modified = {}

local function dprint(...)
	if debug then print(addon_name, 'DEBUG:', ...) end
end

local defaults = {
	db_version = 1,
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
	},
}

local map = {
	[1] = 'MainMenuBar',
	[2] = 'MultiBarBottomLeft',
	[3] = 'MultiBarBottomRight',
	[4] = 'MultiBarRight',
	[5] = 'MultiBarLeft',
	[6] = 'MultiBar5',
	[7] = 'MultiBar6',
	[8] = 'MultiBar7',
}

local reverse_growth = {
	[1] = function(axis, bar)
		if axis == 'y' then
			_G[bar].addButtonsToTop = not _G[bar].addButtonsToTop
		else
			_G[bar].addButtonsToRight = not _G[bar].addButtonsToRight
		end
	end,
	[2] = function(axis, bar)
		if axis == 'y' then
			hooksecurefunc(_G[bar], 'UpdateGridLayout', function(self)
				self.addButtonsToTop = not self.addButtonsToTop
			end)
		else
			hooksecurefunc(_G[bar], 'UpdateGridLayout', function(self)
				self.addButtonsToRight = not self.addButtonsToRight
			end)
		end
	end,
}

local function modify_bars()
	for axis, enableaxis in pairs(a.db.enable) do
		if enableaxis ~= 'none' then
			for bar, enablebar in pairs(a.db[axis]) do
				if enableaxis == 'all' or enablebar then
					bar = map[bar]
					reverse_growth[a.db.method](axis, bar)
					modified[bar] = true
				end
			end
		end
	end
end


local function update_grid_layouts()
	local c = 0
	for bar, _ in pairs(modified) do
		_G[bar]:UpdateGridLayout()
		c = c + 1
	end
	wipe(modified)
	dprint('updated', c, 'modified action bars(s).')
end


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


	Action Bar 1: MainMenuBar
	Action Bar 2: MultiBarBottomLeft
	Action Bar 3: MultiBarBottomRight
	Action Bar 4: MultiBarRight
	Action Bar 5: MultiBarLeft
	Action Bar 6: MultiBar5
	Action Bar 7: MultiBar6
	Action Bar 8: MultiBar7

==============================================================================]]



--[[ License ===================================================================

	Copyright © 2023 Thomas Floeren

	This file is part of NAME_OF_THIS_ADDON.

	NAME_OF_THIS_ADDON is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	NAME_OF_THIS_ADDON is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
	or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along with
	NAME_OF_THIS_ADDON. If not, see <https://www.gnu.org/licenses/>.

==============================================================================]]
