do
local modPath = '/mods/EM/'
local replayID = -1


function unum(n, unit)
	local units = {"", "k", "m", "g"}
	local pos = 1

	n = math.abs(n)

	if (n < 99999) then
		return math.floor(n+.5)
	end

	while (n >= 1000) do
		if(unit and units[pos] == unit) then break end
		n = n / 1000
		pos = pos + 1
	end

	n = math.floor(n+.5)

	if(pos > 1) then return n..units[pos]
	else return n end;
end

function SetupPlayerLines()
	local function CreateArmyLine(data, armyIndex)
		local group = Group(controls.bgStretch)
		local sw = 42

		if (armyIndex ~= 0 and SessionIsReplay() or true) then
			group.faction = Bitmap(group)
			if armyIndex ~= 0 then
				group.faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
			else
				group.faction:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
			end
			group.faction.Height:Set(14)
			group.faction.Width:Set(14)
			group.faction:DisableHitTest()
			LayoutHelpers.AtLeftTopIn(group.faction, group, -4)

			group.color = Bitmap(group.faction)
			group.color:SetSolidColor(data.color)
			group.color.Depth:Set(function() return group.faction.Depth() - 1 end)
			group.color:DisableHitTest()
			LayoutHelpers.FillParent(group.color, group.faction)

			group.name = UIUtil.CreateText(group, data.nickname, 12, UIUtil.bodyFont)
			group.name:DisableHitTest()
			LayoutHelpers.AtLeftIn(group.name, group, 12)
			LayoutHelpers.AtVerticalCenterIn(group.name, group)
			group.name:SetColor('ffffffff')

			group.score = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
			group.score:DisableHitTest()
			LayoutHelpers.AtRightIn(group.score, group, sw * 2)
			LayoutHelpers.AtVerticalCenterIn(group.score, group)
			group.score:SetColor('ffffffff')

			group.name.Right:Set(group.score.Left)
			group.name:SetClipToWidth(true)

			group.mass = Bitmap(group)
			group.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
			LayoutHelpers.AtRightIn(group.mass, group, sw * 1)
			LayoutHelpers.AtVerticalCenterIn(group.mass, group)
			group.mass.Height:Set(14)
			group.mass.Width:Set(14)

			group.energy = Bitmap(group)
			group.energy:SetTexture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
			LayoutHelpers.AtRightIn(group.energy, group, sw * 0)
			LayoutHelpers.AtVerticalCenterIn(group.energy, group)
			group.energy.Height:Set(14)
			group.energy.Width:Set(14)

			group.mass_in = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
			group.mass_in:DisableHitTest()
			LayoutHelpers.AtRightIn(group.mass_in, group, sw * 1+14)
			LayoutHelpers.AtVerticalCenterIn(group.mass_in, group)
			group.mass_in:SetColor('ffb7e75f')

			group.energy_in = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
			group.energy_in:DisableHitTest()
			LayoutHelpers.AtRightIn(group.energy_in, group, sw * 0+14)
			LayoutHelpers.AtVerticalCenterIn(group.energy_in, group)
			group.energy_in:SetColor('fff7c70f')
		else
			group.faction = Bitmap(group)
			if armyIndex ~= 0 then
				group.faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
			else
				group.faction:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
			end
			group.faction.Height:Set(14)
			group.faction.Width:Set(14)
			group.faction:DisableHitTest()
			LayoutHelpers.AtLeftTopIn(group.faction, group)

			group.color = Bitmap(group.faction)
			group.color:SetSolidColor(data.color)
			group.color.Depth:Set(function() return group.faction.Depth() - 1 end)
			group.color:DisableHitTest()
			LayoutHelpers.FillParent(group.color, group.faction)

			group.name = UIUtil.CreateText(group, data.nickname, 12, UIUtil.bodyFont)
			group.name:DisableHitTest()
			LayoutHelpers.AtLeftIn(group.name, group, 16)
			LayoutHelpers.AtVerticalCenterIn(group.name, group)
			group.name:SetColor('ffffffff')

			group.score = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
			group.score:DisableHitTest()
			LayoutHelpers.AtRightIn(group.score, group)
			LayoutHelpers.AtVerticalCenterIn(group.score, group)
			group.score:SetColor('ffffffff')

			group.name.Right:Set(group.score.Left)
			group.name:SetClipToWidth(true)
		end

		group.Height:Set(group.faction.Height)
		group.Width:Set(262)
		group.armyID = armyIndex

		if SessionIsReplay() then
			group.bg = Bitmap(group)
			group.bg:SetSolidColor('00000000')
			group.bg.Height:Set(group.faction.Height)
			group.bg.Left:Set(group.faction.Right)
			group.bg.Right:Set(group.Right)
			group.bg.Top:Set(group.faction.Top)
			group.bg:DisableHitTest()
			group.bg.Depth:Set(group.Depth)
			group.HandleEvent = function(self, event)
				if event.Type == 'MouseEnter' then
					group.bg:SetSolidColor('ff777777')
				elseif event.Type == 'MouseExit' then
					group.bg:SetSolidColor('00000000')
				elseif event.Type == 'ButtonPress' then
					ConExecute('SetFocusArmy '..tostring(self.armyID-1))
				end
			end
		else
			group:DisableHitTest()
		end
		return group
	end

	local index = 1
	for armyIndex, armyData in GetArmiesTable().armiesTable do
		if armyData.civilian or not armyData.showScore then continue end
		if not controls.armyLines then
			controls.armyLines = {}
		end
        controls.armyLines[index] = CreateArmyLine(armyData, armyIndex)
        index = index + 1
    end

    if SessionIsReplay() then
    	observerLine = CreateArmyLine({color = 'ffffffff', nickname = LOC("<LOC score_0003>Observer")}, 0)
    	observerLine.name.Top:Set(observerLine.Top)
    	observerLine.Height:Set(40)
    	observerLine.speedText = UIUtil.CreateText(controls.bgStretch, '', 14, UIUtil.bodyFont)
    	observerLine.speedText:SetColor('ff00dbff')
    	LayoutHelpers.AtRightIn(observerLine.speedText, observerLine)
    	observerLine.speedSlider = IntegerSlider(controls.bgStretch, false, -10, 10, 1,
    		UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
    		UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
    		UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
    		UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))

    	observerLine.speedSlider.Left:Set(function() return observerLine.Left() + 5 end)
    	observerLine.speedSlider.Right:Set(function() return observerLine.Right() - 20 end)
    	observerLine.speedSlider.Bottom:Set(function() return observerLine.Bottom() - 5 end)
    	observerLine.speedSlider._background.Left:Set(observerLine.speedSlider.Left)
    	observerLine.speedSlider._background.Right:Set(observerLine.speedSlider.Right)
    	observerLine.speedSlider._background.Top:Set(observerLine.speedSlider.Top)
    	observerLine.speedSlider._background.Bottom:Set(observerLine.speedSlider.Bottom)
    	observerLine.speedSlider._thumb.Depth:Set(function() return observerLine.Depth() + 5 end)
    	Tooltip.AddControlTooltip(observerLine.speedSlider._thumb, 'Lobby_Gen_GameSpeed')
    	observerLine.speedSlider._background.Depth:Set(function() return observerLine.speedSlider._thumb.Depth() - 1 end)
    	LayoutHelpers.AtVerticalCenterIn(observerLine.speedText, observerLine.speedSlider)

    	observerLine.speedSlider.OnValueChanged = function(self, newValue)
    		observerLine.speedText:SetText(string.format("%+d", math.floor(tostring(newValue))))
    	end

    	observerLine.speedSlider.OnValueSet = function(self, newValue)
    		ConExecute("WLD_GameSpeed " .. newValue)
    	end
    	observerLine.speedSlider:SetValue(gameSpeed)
    	controls.armyLines[index] = observerLine
    	index = index + 1
    end

    local function CreateMapNameLine(data, armyIndex)
    	local group = Group(controls.bgStretch)

    	local mapnamesize = string.len(data.mapname)
    	local mapoffset = 131 - (mapnamesize * 2.7)
    	if (sessionInfo.Options.Ranked) then
    		mapoffset = mapoffset + 10
    	end
    	group.name = UIUtil.CreateText(group, data.mapname, 10, UIUtil.bodyFont)
    	group.name:DisableHitTest()
    	LayoutHelpers.AtLeftIn(group.name, group, mapoffset)
    	LayoutHelpers.AtVerticalCenterIn(group.name, group, 1)
    	group.name:SetColor('ffffffff')

    	if (sessionInfo.Options.Ranked) then
    		group.faction = Bitmap(group)
    		group.faction:SetTexture("/textures/ui/powerlobby/rankedscore.dds")
    		group.faction.Height:Set(14)
    		group.faction.Width:Set(14)
    		group.faction:DisableHitTest()
    		LayoutHelpers.AtLeftTopIn(group.faction, group.name, -15)
    	end

    	group.score = UIUtil.CreateText(group, '', 10, UIUtil.bodyFont)
    	group.score:DisableHitTest()
    	LayoutHelpers.AtRightIn(group.score, group)
    	LayoutHelpers.AtVerticalCenterIn(group.score, group)
    	group.score:SetColor('ffffffff')

    	group.name.Right:Set(group.score.Left)
    	group.name:SetClipToWidth(true)

    	group.Height:Set(18)
    	group.Width:Set(262)

    	group:DisableHitTest()

    	return group
    end

    for _, line in controls.armyLines do
    	local playerName = line.name:GetText()
    	local playerRating = sessionInfo.Options.Ratings[playerName]
    	if (playerRating) then
    		playerNameLine = playerName..' ['..math.floor(playerRating+0.5)..']'
    		line.name:SetText(playerNameLine)
    	end
    end

    mapData = {}
    mapData.mapname = LOCF("<LOC gamesel_0002>Map: %s", sessionInfo.name)
	if replayID == -1 then -- only do this once
    	if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") and
	   	   GetFrontEndData('syncreplayid') ~= nil and GetFrontEndData('syncreplayid') ~= 0 then
			replayID = GetFrontEndData('syncreplayid')
	    elseif HasCommandLineArg("/savereplay") then
        	local url = GetCommandLineArg("/savereplay", 1)[1]
        	local lastpos = string.find(url, "/", 20)
        	replayID = string.sub(url, 20, lastpos-1)
    	elseif HasCommandLineArg("/replayid") then
	        replayID =  GetCommandLineArg("/replayid", 1)[1]
	    end
	end

    if tonumber(replayID) > 0 then mapData.mapname = mapData.mapname .. ', ID: ' .. replayID end
	controls.armyLines[index] = CreateMapNameLine(mapData, 0)
end

function _OnBeat()
	local eco = import(modPath .. 'modules/autoshare.lua').getPlayersEco()
	local quality = '?%'

	if(sessionInfo.Options.Quality) then
		quality = string.format("%.2f%%", sessionInfo.Options.Quality)
	end

	controls.time:SetText(string.format("%s (%+d / %+d) Q: %s", GetGameTime(), gameSpeed, GetSimRate(), quality))

	if sessionInfo.Options.NoRushOption and sessionInfo.Options.NoRushOption ~= 'Off' then
		if tonumber(sessionInfo.Options.NoRushOption) * 60 > GetGameTimeSeconds() then
			local time = (tonumber(sessionInfo.Options.NoRushOption) * 60) - GetGameTimeSeconds()
			controls.time:SetText(LOCF('%02d:%02d:%02d', math.floor(time / 3600), math.floor(time/60), math.mod(time, 60)))
		end
		if not issuedNoRushWarning and tonumber(sessionInfo.Options.NoRushOption) * 60 == math.floor(GetGameTimeSeconds()) then
			import('/lua/ui/game/announcement.lua').CreateAnnouncement('<LOC score_0001>No Rush Time Elapsed', controls.time)
			issuedNoRushWarning = true
		end
	end

	local armiesInfo = GetArmiesTable().armiesTable

	if currentScores then
		for index, scoreData in currentScores do
			for _, line in controls.armyLines do
				if line.armyID == index then
					if line.OOG then break end
					if SessionIsReplay() then
						if (scoreData.resources.massin.rate) then
							line.mass_in:SetText(fmtnum(scoreData.resources.massin.rate * 10))
							line.energy_in:SetText(fmtnum(scoreData.resources.energyin.rate * 10))
						end
					else
						local array = {MASS='mass_in', ENERGY='energy_in'}

						if(eco[line.armyID]) then
							for t, k in array do
								v = eco[line.armyID][t]['overflow'] or 0
								line[k]:SetText(fmtnum(v))
								if(v < 0) then
									line[k]:SetColor('red')
								else
									line[k]:SetColor('ffb7e75f')
								end
							end

							line['mass']:Show()
							line['energy']:Show()
							line['mass_in']:Show()
							line['energy_in']:Show()
						else
							line['mass']:Hide()
							line['energy']:Hide()
							line['mass_in']:Hide()
							line['energy_in']:Hide()
						end
					end

					if scoreData.general.score == -1 then
						line.score:SetText(LOC("<LOC _Playing>Playing"))
						line.scoreNumber = -1
					else
						line.score:SetText(fmtnum(scoreData.general.score))
						line.scoreNumber = scoreData.general.score

					end
					if GetFocusArmy() == index then
						line.name:SetColor('ffff7f00')
						line.score:SetColor('ffff7f00')
						line.name:SetFont('Arial Bold', 12)
						line.score:SetFont('Arial Bold', 12)
						if scoreData.general.currentcap.count > 0 then
							SetUnitText(scoreData.general.currentunits.count, scoreData.general.currentcap.count)
						end
					else
						line.name:SetColor('ffffffff')
						line.score:SetColor('ffffffff')
						line.name:SetFont(UIUtil.bodyFont, 12)
						line.score:SetFont(UIUtil.bodyFont, 12)
					end
					if armiesInfo[index].outOfGame then
						if scoreData.general.score == -1 then
							line.score:SetText(LOC("<LOC _Defeated>Defeated"))
							line.scoreNumber = -1
						end
						line.OOG = true
						line.faction:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
						line.color:SetSolidColor('ff000000')
						line.name:SetColor('ffa0a0a0')
						line.score:SetColor('ffa0a0a0')
						if SessionIsReplay() then
							line.mass_in:SetColor('ffa0a0a0')
							line.energy_in:SetColor('ffa0a0a0')
						end
					end
					break
				end
			end
		end
	end

	if observerLine then
		if GetFocusArmy() == -1 then
			observerLine.name:SetColor('ffff7f00')
			observerLine.name:SetFont('Arial Bold', 14)
		else
			observerLine.name:SetColor('ffffffff')
			observerLine.name:SetFont(UIUtil.bodyFont, 14)
		end
	end

	table.sort(controls.armyLines, function(a,b)
		if a.armyID == 0 or b.armyID == 0 then
			return a.armyID >= b.armyID
		else
			if tonumber(a.scoreNumber) == tonumber(b.scoreNumber) then
				return a.name:GetText() < b.name:GetText()
			else
				return tonumber(a.scoreNumber) > tonumber(b.scoreNumber)
			end
		end
	end)

	import(UIUtil.GetLayoutFilename('score')).LayoutArmyLines()
	end
end
