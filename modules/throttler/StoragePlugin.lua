local modPath = '/mods/EM/'
local ThrottlerPlugin = import(modPath .. 'modules/throttler/ThrottlerPlugin.lua').ThrottlerPlugin

StoragePlugin = Class(ThrottlerPlugin) {
	__init = function(self, eco)
		eco['massStored'] = eco['massStored'] - 1000
		eco['energyStored']  = eco['energyStored'] - 2000
	end,
	add = function(self, project)
		--table.insert(self.projects, project)
	end,
	throttle = function(self, eco, project)
	--[[
		local types = {'mass', 'energy'}
		local min = {mass=1000, energy=2000}
		local drain = {mass=0, energy=0}

		for _, t in types do
			local net = eco[t .. 'Income'] - eco[t .. 'Actual'] - project[t .. 'Requested']

			if(eco[t .. 'Stored'] - net < min[t]) then

			end
		end
		]]

	end,
}
