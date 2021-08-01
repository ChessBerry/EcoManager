local modPath = '/mods/EM/'
local addCommand = import(modPath .. 'modules/commands.lua').addCommand

function printOptions(args)
	local options = SessionGetScenarioInfo()
	local keys = {'Share', 'ShareUnitCap', 'RankedGame', 'CheatsEnabled'}
	local str = ''
	options = options['Options']

	for _, k in keys do
		if options[k] then
			value = options[k]

			if k == 'Share' then
				if(value == 'no') then -- weird logic in the options
					value = 'YES'
				else
					value = 'NO'
				end
			elseif k == 'RankedGame' then
				if options['CheatsEnabled'] == 'false' and options['GameSpeed'] == 'normal' and options['Victory'] == 'demoralization' then
					value = 'YES'
				else
					value = 'NO'
				end
			elseif k == 'Victory' then
				local map = {demoralization='ASSASINATION', domination='SUPREMACY', eradication='ANNIHILATION', sandbox='SANDBOX'}
				value = map[value]
			end

			str = str .. k .. ": " .. string.upper(value) .. '\n'
		end
	end

	print (str)
end

function init()
	addCommand('options', printOptions)
end
