table.insert(options.ui.items,
    {
        title = "EM: Show MEX-overlay",
        key = 'em_mexoverlay',
        type = 'toggle',
        default = 1,
        custom = {
            states = {
                {text = "<LOC _Off>", key = 0 },
                {text = "<LOC _On>", key = 1 },
            },
        },
    })

table.insert(options.gameplay.items,
    {
        title = "EM: MEX upgrade-pause",
        key = 'em_mexes',
        type = 'toggle',
        default = 0,
        custom = {
            states = {
                {text = "<LOC _Off>", key = 0 },
                {text = "On click", key = 'click' },
                {text = "Auto", key = 'auto' },
            },
        },
    })
    
table.insert(options.gameplay.items,
    {
        title = "EM: Throttle energy",
        key = 'em_throttle',
        type = 'toggle',
        default = 0,
        custom = {
            states = {
                {text = "<LOC _Off>", key = 0 },
                {text = "<LOC _On>", key = 1 },
                {text = "Mass fabs only", key = 2 },
            },
        },
    })

table.insert(options.gameplay.items,
    {
        title = "EM: MEX Upgrade Optimization",
        key = 'em_mexOpti',
        type = 'toggle',
        default = 0,
        custom = {
            states = {
                {text = "<LOC _Off>", key = 0 },
                {text = "Auto", key = 'auto' },
                {text = "Simple", key = 'simple' },
                {text = "Optimize Time", key = 'optimizeTime' },
                {text = "Optimize Mass Efficiency", key = 'optimizeMass' },
                {text = "Optimize Energy Efficiency", key = 'optimizeEnergy' },
            },
        },
    })
