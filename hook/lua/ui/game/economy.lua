local modPath = '/mods/EcoManagerCBT/'
local getCurrentThrottle = import(modPath .. 'modules/throttle.lua').getCurrentThrottle

local oldCreateUI = CreateUI
function CreateUI()
    oldCreateUI()

    for _, t in {'mass', 'energy'} do
        GUI[t].overflow = UIUtil.CreateText(GUI.energy, '', 18, UIUtil.bodyFont)
        GUI[t].overflow:SetDropShadow(true)
    end
end

local function round(num, idp)
    if(idp > 0) then
        return string.format("%."..idp.. "f", num)
    else
        return string.format("%d", num)
    end
end

local function unum(n, decimals, unit)
    local units = {"", "k", "m", "g"}
    local pos = 1

    local value = math.abs(n)

    if value > 9999 then
        while value >= 1000 do
            if unit and units[pos] == unit then break end
            value = value / 1000
            pos = pos + 1
        end
    end

    if decimals then
        value = round(value, decimals)
    end

    local str = string.format("%s%g", n < 0 and '-' or '+', value)

    if pos > 1 then
        return str .. units[pos]
    else
        return str
    end
end

local oldConfigureBeatFunction = ConfigureBeatFunction
function ConfigureBeatFunction()
    oldConfigureBeatFunction()
    
    local old_BeatFunction = _BeatFunction
    _BeatFunction = function()
        old_BeatFunction()
        
        local overflowTxt = GUI.energy.overflow
        local overflow = -getCurrentThrottle()
        if overflow ~= 0 then
            local color = overflow < 0 and 'red' or 'ffb7e75f'
            overflowTxt:Show()
            overflowTxt:SetText(unum(overflow, 1))
            overflowTxt:SetColor(color)
        else
            overflowTxt:Hide()
        end
    end
end
