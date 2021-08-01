local modPath = '/mods/EM/'
local addListener = import(modPath .. 'modules/init.lua').addListener
local Units = import('/mods/common/units.lua')

local Select = import('/lua/ui/game/selection.lua')

function upgradeShields()
	local upgrades = {}
	local shields = EntityCategoryFilterDown(categories.SHIELD * categories.STRUCTURE, GetSelectedUnits())

	for i, shield in shields do
		local upgrades_to = nil

		if not shield:IsDead() then
			local bp = shield:GetBlueprint()
			upgrades_to = bp.General.UpgradesTo

			if upgrades_to then
				table.insert(upgrades, shield)
			end
		end
	end

	if upgrades then
		Select.Hidden(function()
			SelectUnits(upgrades)
			IssueBlueprintCommand("UNITCOMMAND_Upgrade", 'urb4204', 1, false)
			IssueBlueprintCommand("UNITCOMMAND_Upgrade", 'urb4205', 1, false)
			IssueBlueprintCommand("UNITCOMMAND_Upgrade", 'urb4206', 1, false)
			IssueBlueprintCommand("UNITCOMMAND_Upgrade", 'urb4207', 1, false)
		end)
	end
end

function addShields()
	local shields = Units.Get(categories.SHIELD * categories.STRUCTURE)

	for _, s in shields do
		addShield(s)
	end
end

function init(isReplay, parent)
	local path = modPath .. 'modules/shields.lua'
	IN_AddKeyMapTable({['Ctrl-Shift-S'] = {action =  'ui_lua import("' .. path .. '").upgradeShields()'},})
end
