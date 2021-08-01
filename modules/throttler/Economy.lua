Economy = Class({
	--[[
	massIncome = 0,
	energyIncome = 0,
	massRequested = 0,
	energyRequested = 0,
	massActual = 0,
	energyActual = 0,
	massStored = 0,
	energyStored = 0,
	massMax = 0,
	energyMax = 0,
	massRatio = 0,
	energyRatio = 0,
	]]

	data = {},

	__init = function(self)
		self:Init()

		return self
	end,

	Init = function(self, data)
		local types = {'MASS', 'ENERGY'}
		local mapping = {maxStorage="Max", stored="Stored", income="Income", lastUseRequested="Requested", lastUseActual="Actual", ratio="ratio", net_income="net_income"}
		local per_tick = {income=true, lastUseRequested=true, lastUseActual=true}

		tps = GetSimTicksPerSecond()
		data = GetEconomyTotals()

		for _, t in types do
			local prefix = string.lower(t)

			for k, m in mapping do
				if per_tick[k] then -- convert data in tick -> seconds
					data[k][t] = data[k][t] * tps
				end

				self[prefix .. m] = data[k][t]
			end

			self[prefix .. "Ratio"] = data['stored'][t] / data['maxStorage'][t]

			if self[prefix .. 'Stored'] < 1 then
				self[prefix .. 'Actual'] = math.min(self[prefix .. 'Actual'], self[prefix .. 'Income']) -- mex bug
			end

			--self[prefix .. "Net"] = data['income'][t] - data['lastUseActual'][t] + data['stored'][t] / 5

		end
	end,

	net = function(self, type)
		local stored = self[type .. 'Stored']
		if stored > 0 then
			stored = stored / 5
		end

		return self[type .. 'Income'] - self[type .. 'Actual'] + stored
	end,

	massNet = function(self)
		return self:net('mass')
	end,

	energyNet = function(self)
		return self:net('energy')
	end,
})
