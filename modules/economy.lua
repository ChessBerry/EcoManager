local WAIT_TIME  = 0.1
local ECO_DATA_SIZE = 4 --save how many data points
local eco_tick = 0
local eco_data = {}
local eco_types = {'MASS', 'ENERGY'}
local eco = {MASS={}, ENERGY={}}

function updateEconomy()
	local mapping = {maxStorage="max", stored="stored", income="income", lastUseRequested="use_requested", lastUseActual="use_actual", ratio="ratio", net_income="net_income"}
	local data
	local avg

	tps = GetSimTicksPerSecond()
	data = GetEconomyTotals()

	eco_tick = eco_tick + 1
	if eco_tick > ECO_DATA_SIZE then
		eco_tick = 1
	end

	for _, type in eco_types do
		for f,t in mapping do
			local n = 1
			local avg_key = 'avg_'..t

			if t == 'ratio' then
				eco[type][t] = data['stored'][type] / data['maxStorage'][type]
			elseif t == 'net_income' then
				eco[type][t] = data['income'][type]-data['lastUseActual'][type]

				--added by SC-Account
				if eco[type]['net_income']<0 and eco[type]['stored']==0 then
					eco[type]['stall_seconds']=eco[type]['stall_seconds']+0.1
				end
				--added by SC-Account
			else
				eco[type][t] = data[f][type]
			end

			eco[type][avg_key] = eco[type][t]

			for _, ed in eco_data do
				eco[type][avg_key] = eco[type][avg_key] + ed[type][t]
				n = n + 1
			end

			eco[type][avg_key] = eco[type][avg_key] / n
		end

	end

	eco_data[eco_tick] = table.deepcopy(eco)
end

function getEconomy()
	return eco_data[eco_tick]
end

function economyThread()

	--added by SC-Account
	for _, type in eco_types do
		eco[type]['stall_seconds']=0
	end
	--added by SC-Account

	while true do
		updateEconomy()
		WaitSeconds(WAIT_TIME)
	end
end

function init()
	ForkThread(economyThread)
end

