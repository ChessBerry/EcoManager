local Prefs = import('/lua/user/prefs.lua')  -- preferences

local PREFS_KEY = 'EM_Settings'

local preferences

function getPrefs(_)
	if preferences == nil then
		preferences = Prefs.GetFromCurrentProfile(PREFS_KEY)
		if not preferences then
			preferences = {}
		end
	end

	return preferences
end

function savePrefs()
	Prefs.SetToCurrentProfile(PREFS_KEY, preferences)
    Prefs.SavePreferences()
end
