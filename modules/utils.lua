local options

function reloadOptions()
	local Prefs = import('/lua/user/prefs.lua')
	options = Prefs.GetFromCurrentProfile('options')
end

function getOptions(reload)
	if not options or reload then
		reloadOptions()
	end

	return options
end

function saveOptions(optionsToSave)
	local Prefs = import('/lua/user/prefs.lua')

	Prefs.SetToCurrentProfile('options', optionsToSave)
    Prefs.SavePreferences()
end

function optionsListener(callback)
	addEventListener('options_changed', callback)
	callback(options)
end

function boolstr(bool)
	if bool then
		return "true"
	else
		return "false"
	end
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function unum(n, unit)
	local units = {"", "k", "m", "g"}
  	local pos = 1

  	n = math.abs(n)

  	if n < 99999 then
  		return math.floor(n+.5)
  	end

	while n >= 1000 do
        if unit and units[pos] == unit then break end
    	n = n / 1000
    	pos = pos + 1
	end

	n = math.floor(n+.5)

	if pos > 1 then return n..units[pos]
	else return n end;

end
