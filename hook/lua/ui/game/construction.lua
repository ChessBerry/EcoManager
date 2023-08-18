local modPath = '/mods/EcoManagerCBT/'

function SetPaused(units, state)
    import(modPath .. 'modules/pause.lua').Pause(units, state, 'user')
end
