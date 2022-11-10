local modPath = '/mods/EM/'
local addListener = import(modPath .. 'modules/init.lua').addListener

local pause_prios = {
	mexes={pause=80, unpause=50},
	throttle={pause=90, unpause=60},
	throttlemass={pause=70},
	user={pause=100},
	unpause={pause=90, unpause=90},
}

local states = {}

function init()
end

function Pause(units, pause, module)
	local prio
	local paused = {}
	local unpaused = {}

	if pause then
		prio = pause_prios[module]['pause']
	else
		prio = pause_prios[module]['unpause'] or pause_prios[module]['pause']
	end

	if not prio then
		prio = 50
	end

	for _, u in units do
		local id = u:GetEntityId()

		if not states[id] or states[id]['paused'] ~= pause then
			if not states[id] or states[id]['module'] == module or prio >= states[id]['prio'] then
				if pause and not states[id]['paused'] then
					if not states[id] then
						states[id] = {unit=u,prio=prio,module=module}
					end

					states[id]['paused'] = pause
					table.insert(paused, u)
				elseif(not pause) then
					table.insert(unpaused, u)
					states[id] = nil
				end


			end
		end
	end

	SetPaused(paused, true)
	SetPaused(unpaused, false)
end

function CanUnpause(unit, module)
	local id
	local prio = pause_prios[module]['unpause'] or pause_prios[module]['pause']

	return not states[id] or module == states[id]['module'] or states[id]['prio'] <= prio or u:IsIdle() or u:GetWorkProgress() == 0
end

function CanUnpauseUnits(units, module)
	local id
	local prio = pause_prios[module]['unpause'] or pause_prios[module]['pause']
	local filtered = {}

	for _, u in units do
		if not u:IsDead() then
			id = u:GetEntityId()
			if not states[id] or module == states[id]['module'] or states[id]['prio'] <= prio or u:IsIdle() or u:GetWorkProgress() == 0 then
				table.insert(filtered, u)
			end
		end
	end

	return filtered
end
