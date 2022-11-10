function CheckForAndHandleTaunt(text)
    -- taunts start with /
    if (string.len(text) > 1) and (string.sub(text, 1, 1) == "/") then
    	local args = {}

        for w in string.gfind(string.sub(text, 2), "%S+") do
    		table.insert(args, w)
    	end

        local tauntIndex = tonumber(args[1])
        local delay = 1
        local times = 1

        if tauntIndex then
    	   if(args[2]) then
        		times = tonumber(args[2])
    	   end

    	   if(args[3]) then
        		delay = tonumber(args[3])
    	   end

    	   delay = math.max(0, delay)
        else
            for index, t in taunts do
                if string.find(string.lower(t.text), string.sub(string.lower(text), 2)) then
                    tauntIndex = index
                    break
                end
            end

            if not tauntIndex then
                return true
            end
        end

        if tauntIndex and taunts[tauntIndex] then
            	ForkThread(function()
                for i=1, times do
	            	SendTaunt(tauntIndex)
            		WaitSeconds(delay / 10)
            	end
            end)
            return true
        end
    end
    return false
end
