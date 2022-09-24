local modPath = '/mods/EM/'

local Units = import('/mods/common/units.lua')

local addListener = import(modPath .. 'modules/init.lua').addListener
local addCommand = import(modPath .. 'modules/commands.lua').addCommand
local getPrefs = import(modPath .. 'modules/prefs.lua').getPrefs
local savePrefs = import(modPath .. 'modules/prefs.lua').savePrefs
local getEconomy = import(modPath ..'modules/economy.lua').getEconomy
local GetScore = import(modPath .. 'modules/score.lua').GetScore
local round = import(modPath .. 'modules/utils.lua').round
local unum = import(modPath .. 'modules/utils.lua').unum

local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local FindClients = import('/lua/ui/game/chat.lua').FindClients

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local GameMain = import('/lua/ui/game/gamemain.lua')
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Dragger = import('/lua/maui/dragger.lua').Dragger
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local Prefs = import('/lua/user/prefs.lua')--preferences
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local ToolTip = import('/lua/ui/game/tooltip.lua')
local HelpText = {
    Mass = {
        Title = "Mass threshold",
        Body = "Autoshare if mass storage contains more than this",
    },
    Energy = {
        Title = "Energy threshold",
        Body = "Autoshare if energy storage contains more than this",
    },
    OptionsBtn = {
        Title = "Options",
        Body = "Configure auto switching behaviour.",
    },
}

local options_window

local savedPrefs

local sharedMass
local sharedEnergy
local throttledEnergy

local chatChannel = 'Autoshare'

local ecotypes = {"MASS", "ENERGY"}
local share_threshold = {MASS=1, ENERGY=1}
local total_shared = {MASS=0, ENERGY=0}

--auto values
local MIN_MASS = 7000
local MIN_ENERGY = 6000
local MIN_ENERGY_RATIO = 0.7

local notifyStored = false
local players_eco = {}
local eco

local deathShared = false

local my_army
local my_acu

local share_mode = 'auto'

local throttled_energy = 0

-- START UI

function throttledEnergyText(amount)
    throttled_energy = amount
    throttledEnergy:SetText(unum(amount));
end

function initUI(isReplay)
	if isReplay then
		return
	end

	savedPrefs = Prefs.GetFromCurrentProfile("Autoshare_settings")
	savedPrefs = nil

	if not savedPrefs then
        savedPrefs = {
            top = 8,
            left = 425,
            MASS = 1,
            ENERGY = 1,
        }
        Prefs.SetToCurrentProfile("Autoshare_settings", savedPrefs)
        Prefs.SavePreferences()
    end

    AutoshareContainer = Bitmap(GetFrame(0))
    AutoshareContainer:SetTexture(modPath .. 'textures/panel.dds')
    AutoshareContainer.Depth:Set(10000)

    LayoutHelpers.AtLeftTopIn(AutoshareContainer, GetFrame(0), 425, 8)

    AutoshareContainer.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
            end

            drag.OnRelease = function(dragself)
                local tempPrefs = Prefs.GetFromCurrentProfile("Autoshare_settings")
                savedPrefs.left = self.Left()
                savedPrefs.top = self.Top()

                savePreferences();

                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        elseif event.Type == 'MouseExit' then
            --CloseToolTip()
        end
    end

    local OptionsButton = Button(AutoshareContainer, modPath .. 'textures/options_up.dds', modPath .. 'textures/options_down.dds', modPath .. 'textures/options_over.dds', modPath .. 'textures/options_up.dds', "UI_Menu_MouseDown_Sml", "UI_Tab_Rollover_01")
    LayoutHelpers.AtLeftTopIn(OptionsButton, AutoshareContainer, 19, 30)

    OptionsButton.oldHandleEvent = OptionsButton.HandleEvent
    OptionsButton.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not options_window then
                options_window = OptionsPanel(AutoshareContainer)
            end
        elseif event.Type == 'MouseEnter' then
        end
        OptionsButton.oldHandleEvent(self, event)
    end

    sharedMass = UIUtil.CreateText(AutoshareContainer, '0', 11, UIUtil.bodyFont)
    sharedMass:SetColor('ffb7e75f')
    LayoutHelpers.AtLeftTopIn(sharedMass, AutoshareContainer, 1, 0)
    sharedEnergy = UIUtil.CreateText(AutoshareContainer, '0', 11, UIUtil.bodyFont)
    sharedEnergy:SetColor('fff7c70f')
    LayoutHelpers.AtLeftTopIn(sharedEnergy, AutoshareContainer, 1, 10)
    throttledEnergy = UIUtil.CreateText(AutoshareContainer, '0', 11, UIUtil.bodyFont)
    throttledEnergy:SetColor('red')
    LayoutHelpers.AtLeftTopIn(throttledEnergy, AutoshareContainer, 1, 20)

end

function savePreferences()
    Prefs.SetToCurrentProfile("Autoshare_settings", savedPrefs)
    Prefs.SavePreferences()

    share_threshold['ENERGY'] = tonumber(savedPrefs['ENERGY'])
    share_threshold['MASS'] = tonumber(savedPrefs['MASS'])
end

function OptionsPanel(parent)
    local window = Bitmap(parent)
    window:SetTexture(modPath .. 'textures/configwindow.dds')
    LayoutHelpers.AtLeftTopIn(window, parent, 0, 100)
    window.Depth:Set(function() return parent.Depth() + 10 end)

    CreateOptionsSlider(window, "Mass", 5, 20, 100)
    CreateOptionsSlider(window, "Energy", 5, 50, 100)

    local okButton = UIUtil.CreateButtonStd(window, '/widgets/small', 'OK', 16)
    LayoutHelpers.AtLeftTopIn(okButton, window, 160, 103)
    okButton.OnClick = function(self)
        savePreferences();
        window:Destroy()
        options_window = nil
    end

    local cancelButton = UIUtil.CreateButtonStd(window, '/widgets/small', 'Cancel', 16)
    LayoutHelpers.AtLeftTopIn(cancelButton, window, 8, 103)
    cancelButton.OnClick = function(self)
        window:Destroy()
        options_window = nil
    end

    return window
end

function CreateOptionsSlider(parent, option, left, top, dividefactor)
    local title = UIUtil.CreateText(parent, option, 14, UIUtil.titleFont)
    LayoutHelpers.AtLeftTopIn(title, parent, left, top)
    title.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            --CreateToolTip(parent, {Title = HelpText[option].Title, Body = HelpText[option].Body})
        end
    end

    local gfxs = {MASS='slider-mass', ENERGY='slider-energy', DEFAULT='slider'}
    local slider_gfx =gfxs[string.upper(option)]

    local slider = IntegerSlider(parent, false, 1,100, 1,
    UIUtil.UIFile('/game/slider-btn/' .. slider_gfx .. '_btn_up.dds'),
    UIUtil.UIFile('/game/slider-btn/' .. slider_gfx .. '_btn_over.dds'),
    UIUtil.UIFile('/game/slider-btn/' .. slider_gfx .. '_btn_down.dds'),
    UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds'))

    LayoutHelpers.AtLeftTopIn(slider, parent, left + 85, top)
    local value = UIUtil.CreateText(parent, "0", 14, UIUtil.bodyFont)
    LayoutHelpers.RightOf(value, slider)

    p = round(share_threshold[string.upper(option)]*100, 2);
    slider:SetValue(p);

    if p == 100 then
        p = "auto"
    end

    value:SetText(p);

    slider.OnValueChanged = function(self, newValue)
        savedPrefs[string.upper(option)] = newValue/100
        if newValue == 100 then
            newValue = "auto"
        end
        value:SetText(newValue)
    end
end

-- END UI

function GetArmyData(army)
    local armies = GetArmiesTable()
    local result = nil
    if type(army) == 'number' then
        if armies.armiesTable[army] then
            result = armies.armiesTable[army]
        end
    elseif type(army) == 'string' then
        for i, v in armies.armiesTable do
            if v.nickname == army then
                result = v
                result.ArmyID = i
                break
            end
        end
    end
    return result
end

function getPlayersEco()
    return players_eco
end

function processStored(player, args)
    players_eco[player]['MASS'] = {overflow=tonumber(args[2]), share=tonumber(args[3])}
    players_eco[player]['ENERGY'] = {overflow=tonumber(args[4]), share=tonumber(args[5])}
end

function sendStored()
    local status = storageStatus()
    local msg
    local options = import(modPath .. 'modules/utils.lua').getOptions(true)
    local player_status = getPlayerStatus()

    for _, t in {'MASS', 'ENERGY'} do
        if options['em_autoshare'] == 0 then
            status[t]['share'] = 0
            --player_status['need'][t] = player_status['n_allies']
        end

        if status[t]['overflow'] > 0 then
            status[t]['overflow'] = status[t]['overflow'] / math.max(1, player_status['need'][t])
        end
    end


    if status['MASS']['share'] > 0 or status['ENERGY']['share'] > 0 then
        shareStored(player_status['players'], status)
    end

    local my_eco = players_eco[GetFocusArmy()]
    if not my_eco or my_eco['MASS']['share'] ~= status['MASS']['share'] or my_eco['ENERGY']['share'] ~= status['ENERGY']['share'] then
        notifyStored = true
    end

    if notifyStored then
        msg = string.format("STORED %d %d %d %d", math.ceil(status['MASS']['overflow']*10), status['MASS']['share'], math.ceil(status['ENERGY']['overflow']*10), status['ENERGY']['share'])
        sendCommand(msg)
    end
end

function sendCommand(msg, id)
    msg = { to = 'allies', text = msg}

    msg[chatChannel] = true

    SessionSendChatMessage(FindClients(), msg)
end

function processCommand(sender, msg)
    local args = {}
    local commands = {
		STORED=processStored -- STORED <m stored> <m share> <e stored> <e share>
	}

	for w in string.gfind(msg.text, "%S+") do
		table.insert(args, w)
	end

	if commands[args[1]] then
		local army = GetArmyData(sender)

		if not players_eco[army.ArmyID] then
            if army.ArmyID ~= GetFocusArmy() then
                print (army.nickname .. " autosharing resources")
            end
            players_eco[army.ArmyID] = {id=army.ArmyID, nickname=army.nickname}
        end

        commands[args[1]](army.ArmyID, args)
    end
end

function storageStatus()
	local tps = GetSimTicksPerSecond()
	local status = {}

    for _, t in ecotypes do
        status[t] = {share=0, overflow=eco[t]['income'] - eco[t]['use_requested']}
    end

    if eco['ENERGY']['stored'] < 1 then
        status['MASS']['overflow'] = eco['MASS']['income'] - eco['MASS']['use_actual']
    end

    if eco['MASS']['stored'] < 1 then
        status['ENERGY']['overflow'] = eco['ENERGY']['income'] - eco['ENERGY']['use_actual']
    end

    for _, t in ecotypes do
        local last_for
        local threshold = share_threshold[t]

        if eco[t]['avg_net_income'] >= 0 then
            last_for = 1000
        else
            last_for = round(eco[t]['stored'] / (-eco[t]['avg_net_income'] * tps))
        end

    	if threshold == 1 then  -- auto mode
            threshold = 0

            if t == 'ENERGY' then
                threshold = MIN_ENERGY_RATIO

                if eco[t]['max'] > MIN_ENERGY then
                    threshold = math.max(threshold, MIN_ENERGY / eco[t]['max'])
                end

                if throttled_energy > 0 then
                    threshold = math.max(threshold, 0.95)
                end

                if eco[t]['avg_income']*tps < 300 then
                    threshold = 1
                end

                threshold = math.min(threshold, 0.95) -- share if energy >= 95%

                if GetGameTimeSeconds() < 300  then -- no energy share before 5 min
                    threshold = 1
                end
            elseif t == 'MASS' then
                threshold = math.max(MIN_MASS / eco[t]['max'], threshold)
                threshold = math.min(threshold, 0.95) -- share if mass >= 95%

                if GetGameTimeSeconds() < 60*4 then -- no mass share first 4 min
                    threshold = 1
                end
            end

            if eco[t]['avg_net_income'] < 0 and last_for < 5 then
                threshold = 1
            end
        end


        if eco[t]['ratio'] > threshold then
            percent = math.min(1, math.max(eco[t]['ratio'] - threshold, 0.01))
            status[t]['share'] = round(eco[t]['stored'] * percent)
        else
            request_threshold = threshold-eco[t]['ratio']

            if t == 'MASS' then
                if eco[t]['ratio'] < math.min(0.10, threshold) or last_for < 3 then
                    status[t]['share'] = -eco['MASS']['max'] * math.min(0.2, request_threshold)
                end
            else
                if eco[t]['ratio'] < math.min(threshold, 0.40) or last_for < 3 or throttled_energy > 0 then
                    status[t]['share']= -eco['ENERGY']['max'] * math.min(0.5, request_threshold)
                end
            end

        end

        if status[t]['share'] > 0 then
            status[t]['overflow'] = math.max(0, status[t]['overflow'])
        elseif status[t]['share'] < 0 then
            status[t]['overflow'] = math.min(0, status[t]['overflow'])
        else
            status[t]['overflow'] = 0
        end

    end

    return status
end

function findArmy(nickname)
    local armies = GetArmiesTable().armiesTable

    nickname = string.lower(nickname)
    for id, a in armies do
        if(nickname == string.lower(a['nickname'])) then-- check abbr here
            a.ArmyID = id
            return a
        end
    end

    return nil
end

function shareWithPlayer(nickname, op)
    local prefs = getPrefs()
    local army = findArmy(nickname)

    --[[

    if(army.ArmyID == GetFocusArmy()) then
        print "You cannot autoshare with yourself"
        return
    end

    if(not players_eco[army.ArmyID]) then
        print (army.nickname .. " is not using autoshare")
        return
    end
    ]]



    nickname = army.nickname

    if(op == '+') then
        prefs['as_players'][nickname] = true
    else
        prefs['as_players'][nickname] = nil
    end

    savePrefs()

    return true
end

function sortPlayersByNeed(a, b)
    if a['ENERGY']['overflow'] ~= b['ENERGY']['overflow'] then
        return a['ENERGY']['overflow'] < b['ENERGY']['overflow']
    end

    return a['MASS']['overflow'] < b['MASS']['overflow']
end

function playersNeedShare2()
    local all = table.copy(players_eco)
    local players = {}
    local me = GetFocusArmy()
    local share = false
    local as_players = {}

    if(share_mode == 'manual') then
        local prefs = getPrefs()
        as_players = prefs['as_players']
    end

    for _, p in all do
        if(me ~= p.id and (all['MASS']['share'] < 0 or all['ENERGY']['share'] < 0)) then
            share = true

            if(share_mode == 'manual') then
                if(not as_players[p.nickname]) then
                    share = false
                end
            end

            if(share) then
                table.insert(players, p)
            end
        end
    end

    table.sort(players, sortPlayersByNeed)

    return players
end

function getPlayerStatus()
    local me = GetFocusArmy()
    local data = {n_allies=0, need={MASS=0, ENERGY=0}}
    local players = {}

    for id, army in GetArmiesTable().armiesTable do
        local p=players_eco[id]
        if me >= 0 and IsAlly(me, id) and not army.outOfGame then
            data['n_allies'] = data['n_allies'] + 1
        end

        if p then
            local add = false
            for _, t in {'MASS', 'ENERGY'} do
                if p[t]['share'] < 0 then
                    add = true
                    data['need'][t] = data['need'][t] + 1
                end
            end

            if add and me ~= id then
                table.insert(players, p)
            end
        end
    end

    table.sort(players, sortPlayersByNeed)

    data['players'] = players

    return data
end

function shareStored(players, status)
    local share = {MASS=0, ENERGY=0}
    local n = table.getsize(players)

    local stored = {MASS=eco['MASS']['stored'], ENERGY=eco['ENERGY']['stored']}

    for _, p in players do
        for _, t in ecotypes do
            if p[t]['share'] < 0 and status[t]['share'] > 0 then
                local to_share = math.floor(math.min(status[t]['share'] / n, -p[t]['share']))

                share[t] = round(to_share / stored[t], 2)
                stored[t] = stored[t] - to_share
                status[t]['share'] = status[t]['share'] - to_share

                total_shared[t] = total_shared[t] + eco[t]['stored'] * share[t]

                if t == 'MASS' then
                    sharedMass:SetText(unum(total_shared[t]))
                else
                    sharedEnergy:SetText(unum(total_shared[t]))
                end

                shareResource(p.id, share)
            end
        end
    end
end

function shareResource(player, share)
	local army = GetFocusArmy()

	if not share then
		share = {MASS= 0.1, ENERGY=0.1};
	end

	local retval = SimCallback({
        Func="GiveResourcesToPlayer",
        Args={ From=army, To=player, Mass=share['MASS'], Energy=share['ENERGY']}
    })
end

function getAllies()
    local allies = {}
    local scoreData = GetScore()
    local ratings = SessionGetScenarioInfo().Options.Ratings
    local me = my_army

    for id, army in GetArmiesTable().armiesTable do
        if IsAlly(me, id) and id ~= me and not army.outOfGame then
            local ally = {id=id, score=0, rating=0}

            if scoreData[id] and scoreData[id].general.score then
                ally['score'] = scoreData[id].general.score
            end

            if ratings[army.nickname] then
                ally['rating'] = ratings[army.nickname]
            end

            table.insert(allies, ally)
        end
    end

    table.sort(allies, function(a,b)
        if(a['rating'] == b['rating']) then
            return a['score'] > b['score']
        else
            return a['rating'] > b['rating']
        end
     end)

    return allies
end

function shareAllResources()
    local allies = getAllies
    local me = my_army

    allies = getAllies()

    for _, ally in allies do
        shareResource(ally['id'], {MASS=1, ENERGY=1})
    end
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
           SimCallback({Func="GiveUnitsToPlayer", Args={ From=me, To=ally['id']},} , true)
    end
end

function autoshareThread()
    eco = getEconomy()
    sendStored()
    checkIfDead()
end

function getAcu()
    local acus = Units.Get(categories.COMMAND)

    if acus then
        return acus[1]
    end
end

function checkIfDead()
    local mode = SessionGetScenarioInfo().Options.Victory

    if mode ~= "demoralization" then
        return
    end

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

    if my_acu:IsDead() and not deathShared then
        deathShared = true
        shareAllResources()
        WaitSeconds(0.2)
        giveAllUnits()
    end
end

function thresholdCommand(args)
    local t
    local thres

    if args[1] == 'e' then
        t = 'ENERGY'
    else
        t = 'MASS'
    end

    if string.lower(args[2]) == 'auto' then
        args[2] = 100
    end

    share_threshold[t] = math.min(math.max(0.01, tonumber(args[2])/100), 1)

    thres = round(share_threshold[t]*100)
    if thres == 100 then
        thres = "auto"
    end

    print ("Setting " .. string.lower(t) .. " threshold to " .. thres)
end

function autoshareCommand(args)
    local n_args = table.getsize(args)
    local print_players = true

    if share_mode ~= 'manual' then
        return
    end

    if n_args == 2 then
        local op = '+'
        local nickname = args[2]
        local c = string.sub(nickname, 1, 1)

        if(c == '-' or c == '+') then
            nickname = string.sub(nickname, 2)
            op = c
        end

        print_players = shareWithPlayer(nickname, op)
    end

    if print_players then
        local str = ''

        prefs = getPrefs()

        for nickname, _ in prefs['as_players'] do
            str = str .. ", " .. nickname
        end

        if str then
            str = "Autosharing with " .. string.sub(str, 3)
        end

        print (str)
    end
end

function init(isReplay, parent)
    prefs = getPrefs()

    if not prefs['as_players'] then
        prefs['as_players'] = {}
        savePrefs()
    end

    initUI(isReplay, parent)
    RegisterChatFunc(processCommand, chatChannel)
    addCommand('m', thresholdCommand)
    addCommand('e', thresholdCommand)
    addCommand('as', autoshareCommand)
    addListener(autoshareThread, 0.4)
end
