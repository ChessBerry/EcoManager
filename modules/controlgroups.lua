ControlGroup = Class({
    id = -1,
    refill = true,
    add = true,

    __init = function(_)
    end,

    addUnits = function(_, units)
        if not type(units) == 'table' then
            units = {units}
        end
    end,

    onNewUnits = function(_, _)
    end
})
