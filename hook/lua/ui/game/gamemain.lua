local modPath = '/mods/EcoManagerCBT/'
local Select = import('/lua/ui/game/selection.lua')

local originalCreateUI = CreateUI
local Units = import('/mods/common/units.lua')

local originalOnSelectionChanged = OnSelectionChanged
function OnSelectionChanged(oldSelection, newSelection, added, removed)
    if table.getsize(added) > 0 and table.getsize(newSelection) == 1 and not Select.IsHidden() then
        local mexes = EntityCategoryFilterDown(categories.MASSEXTRACTION * categories.STRUCTURE, newSelection)

        if mexes and table.getsize(mexes) == 1 then
            local options = import(modPath .. 'modules/options.lua').getOptions()
            local mex = mexes[1]
            local data = Units.Data(mex)

            if options['em_mexes'] == 'click' and (EntityCategoryContains(categories.TECH1, mex) or data['bonus'] >= 1.5) then
                import(modPath ..'modules/mexes.lua').upgradeMexes(mexes, true)
			end
		end
    end

    originalOnSelectionChanged(oldSelection, newSelection, added, removed)
end

function CreateUI(isReplay, _)
    originalCreateUI(isReplay)

    import(modPath .. "modules/init.lua").init(isReplay, import('/lua/ui/game/borders.lua').GetMapGroup())
end
