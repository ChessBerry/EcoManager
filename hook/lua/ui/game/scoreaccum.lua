local modPath = '/mods/EM/'

local originalUpdateScoreData = UpdateScoreData
function UpdateScoreData(newData)
  	originalUpdateScoreData(newData)
	import(modPath .. 'modules/score.lua').UpdateScoreData(newData)
end
