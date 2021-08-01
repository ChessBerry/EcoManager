local modPath = '/mods/EM/'
local triggerEvent = import('/mods/EM/modules/events.lua').triggerEvent

function SetPaused(units, state)
    import(modPath .. 'modules/pause.lua').Pause(units, state, 'user')
end
