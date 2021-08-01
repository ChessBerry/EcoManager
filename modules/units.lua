local modPath = '/mods/EM/'

local boolstr = import(modPath .. 'modules/utils.lua').boolstr
local addListener = import(modPath .. 'modules/init.lua').addListener

local econ_cache = {}

function econData(unit)
	local id = unit:GetEntityId()
	local econ = unit:GetEconData()

	if econ['energyRequested'] ~= 0 then
		if unit:GetFocus() and GetIsPaused({unit}) then
			-- upgrading paused unit but still use energy (i.e. mex), use cached value
		else
			econ_cache[id] = econ
		end
	end

	if not econ_cache[id] then
		local bp = unit:GetBlueprint()

		if bp.Economy then

			if bp.Economy.ProductionPerSecondMass > 0 then
				econ['massProduced'] = bp.Economy.ProductionPerSecondMass
			end

			if bp.Economy.MaintenanceConsumptionPerSecondEnergy > 0 then
				econ['energyRequested'] = bp.Economy.MaintenanceConsumptionPerSecondEnergy
			end

			if bp.Economy.MaintenanceConsumptionPerSecondMass > 0 then
				econ['massRequested'] = bp.Economy.MaintenanceConsumptionPerSecondMass
			end
		end

		if econ['energyRequested'] and econ['energyRequested'] ~= 0 then
			econ_cache[id] = econ
		end
	end

	return econ_cache[id] or {}
end
