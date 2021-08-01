local modPath = '/mods/EM/'
local ThrottlerPlugin = import(modPath .. 'modules/throttler/ThrottlerPlugin.lua').ThrottlerPlugin

MassPlugin = Class(ThrottlerPlugin) {
	_sortProjects = function(a, b)
		return a.massTimeEfficiency < b.massTimeEfficiency
	end,

	add = function(self, project)
		if EntityCategoryContains(categories.MASSEXTRACTION, project.unit) then
			table.insert(self.projects, project)
		end
	end,

	throttle = function(self, eco, project)
		for _, t in {'mass', 'energy'} do
			local net = eco:net(t)
			local new_net = net - project[t .. 'Requested']

			if new_net < 0 then
				if t == 'energy' then
					project:SetEnergyDrain(math.max(0, net))
				else
					project:SetMassDrain(math.max(0, net))
				end
			end
		end

	end,
}
