local modPath = '/mods/EM/'

function isPaused(u)
	local is_paused
	if EntityCategoryContains(categories.MASSFABRICATION*categories.STRUCTURE, u) then
		is_paused = GetScriptBit({u}, 4)
	else
		is_paused = GetIsPaused({u})
	end

	return is_paused
end

function setPause(units, toggle, pause)
	if toggle == 'pause' then
		SetPaused(units, pause)
	else
		local bit = GetScriptBit(units, toggle)
		local is_paused = bit

		if toggle == 0  then
			is_paused = not is_paused
		end

		if pause ~= is_paused then
			ToggleScriptBit(units, toggle, bit)
		end
	end
end

local Project = import(modPath .. 'modules/throttler/Project.lua').Project
local Economy = import(modPath .. 'modules/throttler/Economy.lua').Economy
local EnergyPlugin = import(modPath .. 'modules/throttler/EnergyPlugin.lua').EnergyPlugin
local StoragePlugin = import(modPath .. 'modules/throttler/StoragePlugin.lua').StoragePlugin

local Units = import('/mods/common/units.lua')
local econData = import(modPath .. 'modules/units.lua').econData


EcoManager = Class({
	eco = nil,
	projects = {},
	plugins = {},

	__init = function(self)
		self.eco = Economy()
	end,

	LoadProjects = function(self, eco)
		local unpause = {}

		self.projects = {}
		local units = Units.Get(categories.STRUCTURE + categories.ENGINEER)

		for _, u in units do
			local project

			if not u:IsDead() then
				local focus = u:GetFocus()
				local isConstruction = false

				if not focus then
					local is_paused = isPaused(u)

					if EntityCategoryContains(categories.MASSFABRICATION*categories.STRUCTURE, u) then
						data = econData(u)
						--if not (data.energyRequested == 0 and not isPaused(u)) then
							focus = u
						--end
					elseif is_paused and (u:IsIdle() or u:GetWorkProgress() == 0) then
						table.insert(unpause, u)
					end
				else
					isConstruction = true
				end

				if focus then
					local id = focus:GetEntityId()

					project = self.projects[id]
					if not project then
						--LOG("Adding new project " .. id)

						project = Project(focus)
						project.isConstruction = isConstruction
						self.projects[id] = project
					end

					--LOG("Entity " .. u:GetEntityId() .. " is an assister")

					project:AddAssister(eco, u)
				end
			end
		end

		if unpause then
			setPause(unpause, 'pause', false)
		end

		for _, p in self.projects do
			p:LoadFinished()
		end

		return self.projects
	end,

	addPlugin = function(self, name)
		--local plugin = _G[name .. 'Plugin'](self.eco)
		name = name .. 'Plugin'
		local plugin = import(modPath .. 'modules/throttler/' .. name .. '.lua')[name](self.eco)
		table.insert(self.plugins, plugin)
	end,

	manageEconomy = function(self)
		local eco
		local all_projects = {}

		self.pause_list = {}

		self.eco = Economy()
		eco = self.eco
		for _, p in self:LoadProjects(eco) do
			table.insert(all_projects, p)
		end

		--print ("n_projects " .. table.getsize(all_projects))

		LOG("NEW BALANCE ROUND")

		import(modPath .. 'modules/throttler/Project.lua').throttleIndex = 0
		import(modPath .. 'modules/throttler/Project.lua').firstAssister = true

		for _, plugin in self.plugins do
			local pause = false

			plugin.projects = {}
			for _, p in all_projects do
				plugin:add(p)
	 		end

	 		plugin:sort()

			--print ("n_plugin_projects " .. table.getsize(plugin.projects))
	 		for _, p in plugin.projects do
		 		local ratio_inc

	 			if p.throttle < 1 then
	 				if not pause then
	 					local last_ratio = p.throttle
	 					plugin:throttle(eco, p)
	 					if p.throttle > 0 and p.throttle < 1 then
	 						LOG("ADJUST THIS SHIT")
	 						p:adjust_throttle(eco) -- round throttle to nearest assister
	 						LOG("ADJUSTED TO " .. p.throttle)
	 					end

	 					if p.throttle == 1 then
	 						pause = true
	 					end

	 					ratio_inc = p.throttle - last_ratio
	 					eco.energyActual = eco.energyActual + p.energyRequested * (1-ratio_inc)
		 				eco.massActual = eco.massActual + p.massRequested * (1-ratio_inc)
	 				end

	 				if pause then
	 					p:SetEnergyDrain(0)
	 				end


	 				--[[
			 		if not pause then
	 					local last_ratio = p.throttle
		 				plugin:throttle(eco, p)
	 					ratio_inc = p.throttle - last_ratio
		 				if p.throttle < 1 then
			 				--table.insert(projects, p)
		 				else
				 			pause = true -- plugin throttles all from here
		 				end

		 				eco.energyActual = eco.energyActual + p.energyRequested * (1-ratio_inc)
		 				eco.massActual = eco.massActual + p.massRequested * (1-ratio_inc)
		 			end

		 			if(pause) then
				 		p:SetEnergyDrain(0)
		 				--projects[p.id] = nil
		 			end
		 			]]
		 		end
	 		end
		end

		table.sort(all_projects, function(a, b) return a.index < b.index end)
		--LOG(repr(all_projects))

		for _, p in all_projects do
			p:pause(self.pause_list)
		end


		for toggle_key, modes in self.pause_list do
			local toggle = toggle_key

			if toggle ~= 'pause' then
				toggle = tonumber(string.sub(toggle, 8))
			end

			for mode, units in modes do
				setPause(units, toggle, mode == 'pause')
			end
		end
	end
})


