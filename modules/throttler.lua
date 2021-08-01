local modPath = '/mods/EM/'
local addListener = import(modPath .. 'modules/init.lua').addListener

local manager



local EcoManager = import(modPath .. 'modules/throttler/EcoManager.lua').EcoManager

function manageEconomy()
	manager:manageEconomy()
end

function init()
	manager = EcoManager()
	--manager:addPlugin('Storage')
	--manager:addPlugin('Mass')
	manager:addPlugin('Energy')
	addListener(manageEconomy, 1)
end


