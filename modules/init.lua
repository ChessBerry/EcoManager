local modPath = '/mods/EM/'

local WAIT_SECONDS = 0.1
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
			local current_second = current_tick * WAIT_SECONDS

			if math.mod(current_second*10, l['wait']*10) == 0 then
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
		table.insert(mods, 'throttlemass');
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

