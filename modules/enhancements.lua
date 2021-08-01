local enhTable = {}

function canUpgrade(unit, enhancement)
	local enhancements = unit:GetBlueprint().Enhancements
    local e = enhancements[enhancement]

    if e then
    	local enhCommon = import('/lua/enhancementcommon.lua')
   		local existing = enhCommon.GetEnhancements(unit:GetEntityId())

   		return not existing[e.Slot] or existing[e.Slot] == e.Prerequisite
    end

    return false
end
