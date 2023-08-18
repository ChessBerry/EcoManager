local modPath = '/mods/EcoManagerCBT/'
local addCommand = import(modPath .. 'modules/commands.lua').addCommand
local addEventListener = import(modPath .. 'modules/events.lua').addEventListener

function printOptions(_)
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

local cachedOptions = {}
local listeners = {}
function addOptionsListener(data, callback)
	table.insert(listeners, {callback=callback, data=data})

	for k, _ in data do
		data[k] = cachedOptions[k]
	end
end

function getOptions()
	return cachedOptions
end

local function onOptionsChanged(options)
	cachedOptions = options

	for _, listener in listeners do
		for k, _ in listener.data do
			listener.data[k] = options[k]
		end

		if listener.callback then 
			listener.callback(listener.data)
		end
	end
end



function init()
	addCommand('options', printOptions)
	addEventListener('options_changed', onOptionsChanged)

	local options = import('/lua/user/prefs.lua').GetFromCurrentProfile('options')
	onOptionsChanged(options)
end
