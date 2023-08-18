local modPath = '/mods/EM/'
local Units = import('/mods/common/units.lua')

local Select = import('/lua/ui/game/selection.lua')

function upgradeShields()
	local upgrades = {}
	local shields = EntityCategoryFilterDown(categories.SHIELD * categories.STRUCTURE, GetSelectedUnits())

	for _, shield in shields do
		local upgrades_to

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

function init(_, _)
	local path = modPath .. 'modules/shields.lua'
	IN_AddKeyMapTable({['Ctrl-Shift-S'] = {action =  'ui_lua import("' .. path .. '").upgradeShields()'},})
end
