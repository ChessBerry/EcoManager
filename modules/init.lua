local modPath = '/mods/EM/'

-- The original WAIT_SECONDS = 0.1 possibly was supposed to be analogous to ingame ticks, which actually take 0.1s if 
-- the game runs at +0, but in practice the ecomanager-mod-ticks count down significantly slower than ingame ticks 
-- if you set WAIT_SECONDS to 0.1. So we may as well lean in on that, and counter faster than ingame, to make sure that
-- our stuff runs on time. Hence me setting WAIT_SECONDS to 0.04 as a rough guess for what might be good here.
local WAIT_SECONDS = 0.04
local current_tick = 0
local watch_tick = nil
local listeners = {}

local mThread = nil

function currentTick()
	return current_tick
end

function addListener(callback, wait)
	table.insert(listeners, {callback=callback, wait=wait})
end

function mainThread()
	while true do
		for _, l in listeners do
			local current_second = current_tick * WAIT_SECONDS -- runs significantly slower than real or ingame seconds

			-- This is a really dangerous way to determine wait times, due to the mod function really only being well
			-- behaved with integers. I try to make this a bit dangerous here with the floor function, 
			-- but really just rewriting this entirely to not specify seconds, but ecomanager-mod-ticks/-steps or 
			-- something similar instead.
			if math.mod(math.floor(current_second*10), math.floor(l['wait']*10)) == 0 then
				l.callback()
			end
		end

		current_tick = current_tick + 1
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

