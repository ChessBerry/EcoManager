local modPath = '/mods/EM/'

local Units = import('/mods/common/units.lua')
local Select = import('/lua/ui/game/selection.lua')

local bp2factories = {}

function resetOrderQueue(factory)
	local queue = SetCurrentFactoryForQueueDisplay(factory)

	if not queue then
		return
	end

	for i = 1, table.getsize(queue) do
		local count = queue[i].count

		if i == 1 then
			count = count - 1
		end
		DecreaseBuildCountInQueue(i, count)
	end
end

function resetOrderQueues()
	local factories = EntityCategoryFilterDown(categories.FACTORY, GetSelectedUnits() or {})

	if factories then
		Select.Hidden(function()
			for _, factory in factories do
				resetOrderQueue(factory)
			end
		end)
	end
end

function loadFactories()
	local all_factories = Units.Get(categories.FACTORY)

	bp2factories = {}

	for _, tech in {categories.TECH1, categories.TECH2, categories.TECH3} do
		for _, type in {categories.LAND, categories.AIR, categories.NAVAL} do
			factories = EntityCategoryFilterDown(tech * type, all_factories)
			local orders, toggles, categories = GetUnitCommandData(factories)
			local bps = EntityCategoryGetUnitList(categories)

			for _, bp in bps do
				if not bp2factories[bp] then
					bp2factories[bp] = {}
				end

				for _, factory in factories do
					id = factory:GetEntityId()
					if not bp2factories[bp][id] then
						bp2factories[bp][id] = factory
					elseif bp2factories[bp][id]:IsDead() then
						bp2factories[bp][id] = nil
					end
				end
			end
		end
	end

--[[
	for _, factory in factories do
		orders, toggles, categories = GetUnitCommandData(factories)
	end
	]]

end

function factoryData(factory)
	local queue = SetCurrentFactoryForQueueDisplay(factory)

	--LOG(repr(queue))
end

function orderFactories()
	local factories = Units.Get(categories.FACTORY)
	local orders
	local toggles
	local categories

	loadFactories()

	orders = {"uel0101", "uea0102"}
	factory_orders = {}

	for _, o in orders do
		factories = bp2factories[o]

		if factories then
			tmp = {}
			for _, f in factories do
				local data = factoryData(f)
				table.insert(tmp, f)
			end

			Select.Hidden(function ()
				SelectUnits(tmp)
				IssueBlueprintCommand("UNITCOMMAND_BuildFactory", o, 1)
			end)
		end
	end



	--[[

	orders, toggles, categories = GetUnitCommandData(factories)

	LOG(repr(orders))
	LOG(repr(EntityCategoryGetUnitList(categories)))


	IssueBlueprintCommand("UNITCOMMAND_BuildFactory", orders[1], 1)
	]]
end

function init(isReplay, parent)
	local path = modPath .. 'modules/factories.lua'
	IN_AddKeyMapTable({['Ctrl-Y'] = {action =  'ui_lua import("' .. path .. '").resetOrderQueues()'},})
	IN_AddKeyMapTable({['Ctrl-T'] = {action =  'ui_lua import("' .. path .. '").orderFactories()'},})
end
