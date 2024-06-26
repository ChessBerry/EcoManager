local modPath = '/mods/EcoManagerCBT/'
local Units = import("/mods/common/units.lua")
local addListener = import(modPath .. "modules/init.lua").addListener
local addOptionsListener = import(modPath .. 'modules/options.lua').addOptionsListener
local GetScore = import(modPath .. 'modules/score.lua').GetScore

local deathShared = false
local em_shareOnDeath = false
local options = {['em_shareOnDeath'] = 0}

local my_army
local my_acu

function getAllies()
    local allies = {}
    local scoreData = GetScore()
    local ratings = SessionGetScenarioInfo().Options.Ratings
    local me = my_army

    for id, army in GetArmiesTable().armiesTable do
        if IsAlly(me, id) and id ~= me and not army.outOfGame then
            local ally = {id = id, score = 0, rating = 0}

            if scoreData[id] and scoreData[id].general.score then
                ally["score"] = scoreData[id].general.score
            end

            if ratings[army.nickname] then
                ally["rating"] = ratings[army.nickname]
            end

            table.insert(allies, ally)
        end
    end

    table.sort(
        allies,
        function(a, b)
            if (a["rating"] == b["rating"]) then
                return a["score"] > b["score"]
            else
                return a["rating"] > b["rating"]
            end
        end
    )

    return allies
end

function shareAllResources()
    local allies

    allies = getAllies()

    for _, ally in allies do
        shareResource(ally["id"], {MASS = 1, ENERGY = 1})
    end
end

function shareResource(player, share)
	local army = GetFocusArmy()

	if not share then
		share = {MASS= 0.1, ENERGY=0.1};
	end

	local _ = SimCallback({
        Func="GiveResourcesToPlayer",
        Args={ From=army, To=player, Mass=share['MASS'], Energy=share['ENERGY']}
    })
end

function giveAllUnits()
    local allies = getAllies()
    local units
    local me = my_army

    UISelectionByCategory("ALLUNITS", false, false, false, false)
    units = GetSelectedUnits()

    if not units then
        return
    end

    units = EntityCategoryFilterDown(categories.ALLUNITS - categories.SILO, units)
    SelectUnits(units)

    for _, ally in allies do
        SimCallback({Func = "GiveUnitsToPlayer", Args = {From = me, To = ally["id"]}}, true)
    end
end

function autoshareThread()
    if em_shareOnDeath then
        checkIfDead()
    else
    end
end

function getAcu()
    local acus = Units.Get(categories.COMMAND)

    if acus then
        return acus[1]
    end
end

function checkIfDead()
    if GetFocusArmy() ~= -1 then
        if my_army ~= GetFocusArmy() then
            my_acu = nil
        end
        my_army = GetFocusArmy()
    end

    if not my_acu then
        my_acu = getAcu()

        if not my_acu then
            return
        end
    end

    if my_acu:IsDead() and em_shareOnDeath and not deathShared then
        deathShared = true
        shareAllResources()
        WaitSeconds(0.2)
        giveAllUnits()
    end
end

function onOptionsChanged(changed)
    options = changed
    if options['em_shareOnDeath'] == 1 then
        em_shareOnDeath = true
    else
        em_shareOnDeath = false
    end
end

function init(_, _)
    -- for some reason this autoshare module was disabled for all game modes except demoralization
    -- now it's enabled for all game modes, but adjustable, defaulting to off
    --local gameMode = SessionGetScenarioInfo().Options.Victory
    --if gameMode ~= "demoralization" then
    --    return
    --end

    addListener(autoshareThread, 0.5)
    addOptionsListener(options, onOptionsChanged)
end
