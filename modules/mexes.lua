local modPath = '/mods/EcoManagerCBT/'
local Select = import('/mods/common/select.lua')
local Units = import('/mods/common/units.lua')

local addOptionsListener = import(modPath .. 'modules/options.lua').addOptionsListener
local triggerEvent = import(modPath .. 'modules/events.lua').triggerEvent
local addListener = import(modPath .. 'modules/init.lua').addListener

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local Pause = import(modPath .. 'modules/pause.lua').Pause
local CanUnpause = import(modPath .. 'modules/pause.lua').CanUnpause

local pause_queue = {}
local overlays = {}

local options = {
	['em_mexes']='auto',
	['em_mexoverlay']=1
}

function SetPaused(units, state)
    Pause(units, state, 'mexes')
end

function isMexBeingBuilt(mex)
	if mex:GetEconData().energyRequested ~= 0 then
		return false
	end

	if mex:GetHealth() == mex:GetMaxHealth() then
		return false
	end

	return true
end

function getMexes()
	local all_mexes = Units.Get(categories.MASSEXTRACTION * categories.STRUCTURE)
	local mexes = {all={}, upgrading={}, idle={}, assisted={}}

	mexes['all'] = all_mexes

	for _, mex in all_mexes do
		if not mex:IsDead() then
			data = Units.Data(mex)

			if data['is_idle'] then -- Idling mex, should be upgraded / paused
				for _, category in {categories.TECH1, categories.TECH2} do
					if EntityCategoryContains(category, mex) then
						if category == categories.TECH1 or data['bonus'] >= 1.5 then -- upgrade T1 and T2 with MS
							table.insert(mexes['idle'], mex)
						end
					end
				end
			elseif mex:GetFocus() then
				table.insert(mexes['upgrading'], mex)

				if data['assisting'] > 0 and GetIsPaused({mex}) and CanUnpause(mex, 'mexes') then
					table.insert(mexes['assisted'], mex)
				end
			end
		end
	end

	return mexes
end

function upgradeMexes(mexes, unpause)
	if not mexes or table.getsize(mexes) == 0 then
		return false
	end

	local upgrades = {}

	for _, mex in mexes do
		-- Changed by CheeseBerry to only automatically upgrade/pause t1 mexes
		-- if m:IsIdle() then
		if mex:IsIdle() and EntityCategoryContains(categories.TECH1, mex) then
			local bp = mex:GetBlueprint()
			local upgrades_to = bp.General.UpgradesTo

			if not unpause then
				queuePause(mex)
			end

			if not upgrades[upgrades_to] then
				upgrades[upgrades_to] = {}
			end

			table.insert(upgrades[upgrades_to], mex)
		end
	end

	if table.getsize(upgrades) > 0 then
		Select.Hidden(function()
			for upgrades_to, up_mexes in upgrades do
				SelectUnits(up_mexes)
				IssueBlueprintCommand("UNITCOMMAND_Upgrade", upgrades_to, 1, false)
			end
		end)
	end

	if unpause then
		SetPaused(mexes, false)
	end

	return true
end

function upgradeMexById(id)
	local units = Units.Get()

	for k, u in units do
		if u:IsDead() then
			units[k] = nil
		end
	end

	if not units then return end

	local all_mexes = EntityCategoryFilterDown(categories.MASSEXTRACTION * categories.STRUCTURE, units)

	for _, m in all_mexes do
		if m:GetEntityId() == id then
			if not m:GetFocus() then
				upgradeMexes({m})
			end

			return
		end
	end
end

function queuePause(mex)
	table.insert(pause_queue, mex)
end

function pauseMexes()
	local pause = {}

	for k, mex in pause_queue do
		if mex:IsDead() then
			-- remove mex from queue if it is dead, otherwise it seems there are edge cases where it stays here forever
			pause_queue[k] = nil
		elseif mex:GetFocus() then
			-- if the mex is not dead and fully constructed, we put it into the to-be-paused list and Then remove it 
			-- from the queue
			table.insert(pause, mex)
			pause_queue[k] = nil
		end
	end

	if table.getsize(pause) > 0 then
		triggerEvent('toggle_pause', pause, true)
		SetPaused(pause, true)
	end
end

function CreateMexOverlay(unit)
	local worldView = import('/lua/ui/game/worldview.lua').viewLeft
	local overlay = Bitmap(GetFrame(0))

	overlay.id = unit:GetEntityId()
	overlay.destroy = false
	overlay:SetSolidColor('black')
	overlay.Width:Set(10)
	overlay.Height:Set(10)

	local pos = worldView:Project(unit:GetPosition())
	LayoutHelpers.AtLeftTopIn(overlay, worldView, pos.x - overlay.Width() / 2, pos.y - overlay.Height() / 2 + 1)

	overlay.OnFrame = function(_, _)
		if not unit:IsDead() then
			local frameWorldView = import('/lua/ui/game/worldview.lua').viewLeft
			local framePos = frameWorldView:Project(unit:GetPosition())
			LayoutHelpers.AtLeftTopIn(overlay, frameWorldView, framePos.x - overlay.Width() / 2, framePos.y - overlay.Height() / 2 + 1)
		else
			overlay.destroy = true
			overlay:Hide()
		end
	end

	overlay.text = UIUtil.CreateText(overlay, '0', 10, UIUtil.bodyFont)
	overlay.text:SetColor('green')
	overlay.text:SetDropShadow(true)
	LayoutHelpers.AtCenterIn(overlay.text, overlay, 0, 0)
	overlay:SetNeedsFrameUpdate(true)

	return overlay
end

function UpdateMexOverlay(mex)
	local id = mex:GetEntityId()
	local data = Units.Data(mex)
	local tech = 0
	local color = 'green'

	if isMexBeingBuilt(mex) then
		return false
	end

	if not overlays[id] then
		overlays[id] = CreateMexOverlay(mex)
	end

	local overlay = overlays[id]

	if EntityCategoryContains(categories.TECH1, mex) then
		tech = 1
	elseif EntityCategoryContains(categories.TECH2, mex) then
		tech = 2
	else
		tech = 3
	end

	if data['is_idle'] or (mex:GetWorkProgress() < 0.02) then
		if tech >= 2 and data['bonus'] < 1.5 then
			color = 'red'
		elseif tech == 3 then
			color = 'white'
		else
			color = 'green'
		end
	else
		color = 'yellow'
	end

	overlay.text:SetColor(color)
	overlay.text:SetText(tech)
end

function mexOverlay()
	mexes = getMexes()

	if options['em_mexoverlay'] == 1 then
		for _, m in mexes['all'] do
			if m:IsIdle() or m:GetFocus() then
				UpdateMexOverlay(m)
			end
		end
	end

	for id, overlay in overlays do
		if not overlay or overlay.destroy or options['em_mexoverlay'] == 0 then
			overlay:Destroy()
			overlays[id] = nil
		end
	end
end

function checkMexes()
	local mexes

	mexes = getMexes()

	if table.getsize(mexes['idle']) > 0 then
		local auto_upgrade = options['em_mexes'] == 'auto';

		if auto_upgrade then
			upgradeMexes(mexes['idle'])
		end
	end

	if table.getsize(mexes['assisted']) > 0 then
		Pause(mexes['assisted'], false, 'user') -- unpause assisted mexes
	end
end

function init(isReplay, _)
	if not isReplay then
		addListener(checkMexes, 0.5)
		addListener(pauseMexes, 0.1)
	end

	addListener(mexOverlay, 0.5)
	addOptionsListener(options)
end
