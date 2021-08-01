ControlGroup = Class({
    id = -1,
    refill = true,
    add = true,

    __init = function(self)
    end,

    addUnits = function(self, units)
        if not type(units) == 'table' then
            units = {units}
        end
    end,

    onNewUnits = function(self, units)
    end
})
