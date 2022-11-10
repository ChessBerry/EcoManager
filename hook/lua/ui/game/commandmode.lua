modPath = "/mods/EM/"
local queuePause = import(modPath .. 'modules/mexes.lua').queuePause
local Select = import('/lua/ui/game/selection.lua')

function UpgradeMex(mex, bp)
	Select.Hidden(function()
        SelectUnits({mex})
        IssueBlueprintCommand("UNITCOMMAND_Upgrade", bp, 1, false)
        queuePause(mex)
    end)
end

--- Allows us to detect a double / triple click
local pStructure1 = nil
local pStructure2 = nil
function CapStructure(command)

    -- retrieve the option in question, can have values: 'off', 'only-storages-extractors' and 'full-suite'
    local option = Prefs.GetFromCurrentProfile('options.structure_capping_feature_01')
    
    -- bail out - we're not interested
    if option == 'off' then 
        return 
    end

    -- check if we have engineers
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end

    -- check if we have a building that we target
    local structure = GetUnitById(command.Target.EntityId)
    if not structure or IsDestroyed(structure) then return end

    -- various conditions written out for maintainability
    local isShiftDown = IsKeyDown('Shift')

    local isDoubleTapped = structure ~= nil and (pStructure1 == structure)
    local isTripleTapped = structure ~= nil and (pStructure1 == structure) and (pStructure2 == structure) 

    local isUpgrading = structure:GetFocus() ~= nil

    local isTech1 = structure:IsInCategory('TECH1')
    local isTech2 = structure:IsInCategory('TECH2')
    local isTech3 = structure:IsInCategory('TECH3')

    -- only run logic for structures
    if structure:IsInCategory('STRUCTURE') then 

        -- try and create storages and / or fabricators around it
        if structure:IsInCategory('MASSEXTRACTION') then 
            local options = import(modPath .. 'modules/options.lua').getOptions()
            -- check what type of buildings we'd like to make
            local buildFabs = 
                option == 'full-suite'
                and (
                    (isTech2 and isUpgrading and isTripleTapped and isShiftDown) 
                    or (isTech3 and isDoubleTapped and isShiftDown)
                )  

            local buildStorages = 
                (
                    (isTech1 and isUpgrading and isDoubleTapped and isShiftDown) 
                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and not isUpgrading)
                    or isTech3
                ) and not buildFabs

            local upgradeMex = options['em_mexes'] == 'click' and not isUpgrading and (isTech1 or isTech2)

            if upgradeMex then
                local eco = structure:GetEconData()
                local bp = structure:GetBlueprint()
                local is_capped = eco.massProduced == bp.Economy.ProductionPerSecondMass * 1.5
    
                if isTech1 or is_capped then
                    local prefix = string.sub(command.Blueprint, 0, 3)
                    local postfix = isTech1 and '1202' or '1302'
                        
                    UpgradeMex(structure, prefix .. postfix)
                end
            end    

            if buildStorages then 

                -- prevent consecutive calls 
                local gametime = GetGameTimeSeconds()
                if structure.RingStoragesStamp then 
                    if structure.RingStoragesStamp + 0.75 > gametime then
                        return 
                    end
                end

                structure.RingStoragesStamp = gametime

                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id = "b1106" }}, true)

                -- only clear state if we can't make fabricators 
                if (isTech1 and isUpgrading) or (isTech2 and not isUpgrading) then 
                    structure = nil
                    pStructure1 = nil
                    pStructure2 = nil
                end
            end

            if buildFabs then 

                -- prevent consecutive calls 
                local gametime = GetGameTimeSeconds()
                if structure.RingFabsStamp then 
                    if structure.RingFabsStamp + 0.75 > gametime then
                        return 
                    end
                end

                structure.RingFabsStamp = gametime

                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 2, id = "b1104" }}, true)
                
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil
            end

        -- only apply these if we're interested in them
        elseif option == 'full-suite' then 

                -- prevent consecutive calls 
                local gametime = GetGameTimeSeconds()
                if structure.RingStamp then 
                    if structure.RingStamp + 0.75 > gametime then
                        return 
                    end
                end

                structure.RingStamp = gametime

            -- if we have a t3 fabricator, create storages around it
            if structure:IsInCategory('MASSFABRICATION') and isTech3 then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id = "b1106" }}, true)

                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a t2 artillery, create t1 pgens around it
            elseif structure:IsInCategory('ARTILLERY') and isTech2 then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)

                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a radar, create t1 pgens around it
            elseif 
                structure:IsInCategory('RADAR')  
                and (
                       (isTech1 and isUpgrading and isDoubleTapped and isShiftDown) 
                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown) 
                    or (isTech2 and not isUpgrading)
                    )
                or structure:IsInCategory('OMNI') 
                then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)

                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a t1 point defense, create walls around it
            elseif structure:IsInCategory('DIRECTFIRE') and isTech1 then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b5101" }}, true)

                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil
            end
        end
    end

    -- keep track of previous structure to identify a 2nd / 3rd click
    pStructure2 = pStructure1
    pStructure1 = structure

    -- prevent building up state when upgrading but shift isn't pressed
    if isUpgrading and not isShiftDown then 
        structure = nil
        pStructure1 = nil
        pStructure2 = nil
    end
end