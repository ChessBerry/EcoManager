local modPath = '/mods/EM/'

-- The original WAIT_SECONDS = 0.1 possibly was supposed to be analogous to ingame ticks, which actually take 0.1s if 
-- the game runs at +0, but in practice the ecomanager-mod-ticks count down significantly slower than ingame ticks 
-- if you set WAIT_SECONDS to 0.1. So we may as well lean in on that, and counter faster than ingame, to make sure that
-- our stuff runs on time. Hence me setting WAIT_SECONDS to 0.08 as a rough guess for what might be good here.
local WAIT_SECONDS = 0.08
local current_tick = 0  -- weird internal ticks the EM mod uses for some reason, out of sync with ingame ticks 
local watch_tick = nil
local listeners = {}
local current_second = 0 -- weird internal seconds the EM mod uses for some reason, out of sync with both ingame and real time 
local gametime = 0 -- ingame time the faf game overall uses

local mThread = nil
local wait_seconds_till_mod_does_anything = 120

function currentTick()
	return current_tick
end

function addListener(callback, wait)
	table.insert(listeners, {callback=callback, wait=wait})
end

function incrementModTick()
	current_tick = current_tick + 1
end

function updateModTime()
	current_second = current_tick * WAIT_SECONDS --
end

function updateGameTime()
	gametime = GetGameTimeSeconds()
end

function mainThread()
	-- Wait a while before the mod does anything to avoid it taking actions that could screw up very optimized or 
	-- fragile build orders like the standard hydro rush.
	while gametime < wait_seconds_till_mod_does_anything do
		updateModTime()
		incrementModTick()
		updateGameTime()
		WaitSeconds(WAIT_SECONDS)
	end
	while true do
		for _, l in listeners do
			updateModTime()
			-- This is a really dangerous way to determine wait times, due to the mod function really only being well
			-- behaved with integers. I try to make this a bit less dangerous here with the floor function, 
			-- but really just rewriting this entirely to not specify seconds, but ecomanager-mod-ticks/-steps or 
			-- something similar instead would be a lot better.
			if math.mod(math.floor(current_second*10), math.floor(l['wait']*10)) == 0 then
				l.callback()
			end
		end
		incrementModTick()
		WaitSeconds(WAIT_SECONDS)
	end
end

function watchdogThread()
	while true do
		if watch_tick == current_tick then -- main thread has died
			if mThread then
				KillThread(mThread)
			end

			mThread = ForkThread(mainThread)
		end

		watch_tick = current_tick

		WaitSeconds(1)
	end
end

function setup(isReplay, parent)
	local mods = {'options', 'economy', 'pause', 'mexes', 'buildoverlay'}

	if not isReplay then
		table.insert(mods, 'autoshare');
		-- table.insert(mods, 'throttlemass');
		table.insert(mods, 'throttle');
	end

	for _, m in mods do
		import(modPath .. 'modules/' .. m .. '.lua').init(isReplay, parent)
	end
end

function initThreads()
	ForkThread(mainThread)
	ForkThread(watchdogThread)
end

function init(isReplay, parent)
	setup(isReplay, parent)
	ForkThread(initThreads)
end

