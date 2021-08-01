
local modPath = '/mods/EM/'
local Units = import('/mods/common/units.lua')
local addListener = import(modPath .. 'modules/init.lua').addListener
local getEconomy = import(modPath ..'modules/economy.lua').getEconomy
local addCommand = import(modPath .. 'modules/commands.lua').addCommand
local Pause = import(modPath .. 'modules/pause.lua').Pause
local CanUnpause = import(modPath .. 'modules/pause.lua').CanUnpause

--/settings
local logEnabled=false
local preventM_Stall=1
local preventE_Stall=1
--\settings

local unitsPauseList={}
--local excluded = {}

function init()
	addCommand('mm', setMassStallMexesOnCount)
	addCommand('me', setEnergyStallMexesOnCount)
	addListener(manageAssistedUpgrade, 0.6, 'em_mexOpti')
end
function ILOG(str)
	if logEnabled then
		LOG(str)
	end
end

function SetPaused(units, state)
	Pause(units, state, 'throttlemass')
end

function getUnitsPauseList()
	local units={}
	for k, m in unitsPauseList do
		if(m:IsDead()) then
			unitsPauseList[k] = nil
		else
			units[m:GetEntityId()]=m
		end
	end
	return units
end

function setMassStallMexesOnCount(args)
	if not args then
		preventM_Stall=1
	else
		local str = string.lower(args[2])
		preventM_Stall=tonumber(str)
	end

	local eco=getEconomy()
	print("Number of mass production upgrades to keep on during mass stall set to:" , preventM_Stall, "Stalling eco: ", "mass = ", eco['MASS']['stall_seconds'],"energy = ", eco['ENERGY']['stall_seconds'])
end

function setEnergyStallMexesOnCount(args)
	if not args then
		preventE_Stall=0
	else
		local str = string.lower(args[2])
		preventE_Stall=tonumber(str)
	end

	local eco=getEconomy()
	print("Number of mass production upgrades to keep on during energy stall set to:" , preventE_Stall, "Stalling eco: ", "mass = ", eco['MASS']['stall_seconds'],"energy = ", eco['ENERGY']['stall_seconds'])
end

local mexCappedMsgPrinted=false
function manageAssistedUpgrade()
	ILOG("started")
	-- create table
	local AllUnits={}
	local mexPositions = {}
	for _, u in Units.Get() do
		table.insert(AllUnits,u)
	end

	local mexes=EntityCategoryFilterDown(categories.MASSEXTRACTION,AllUnits)

	-- map mexes to positions
	for _, m in mexes do
		local pos = m:GetPosition()
		if(not mexPositions[pos[1]]) then
			mexPositions[pos[1]] = {}
		end

		mexPositions[pos[1]][pos[3]] = m
	end


	-- find upgrading mexes, check if eco is capped
	local AllMEXT3Capped=false
	if table.getsize(mexes)>0 then
		AllMEXT3Capped=true
	end

	engineers = EntityCategoryFilterDown(categories.ENGINEER,AllUnits)
	for _, m in mexes do
		if not m:IsIdle() then --and not excluded[m:GetEntityId()]
			table.insert(engineers,m)
		end

		local data=m:GetEconData()
		if data['massProduced']~=27 then
			AllMEXT3Capped =false
		end

	end

	if AllMEXT3Capped and not mexCappedMsgPrinted then
		local minutes=math.floor(GetGameTimeSeconds()/60)
		print("All Mexes upgraded to t3 and capped at", minutes .. ":" .. GetGameTimeSeconds()-minutes*60)
		mexCappedMsgPrinted=true
	end

	-- find the mex assisting and grab id from there
	assisting = {}
	for _, e in engineers do
		if not e:IsDead() then
			local m
			local is_idle = e:IsIdle()
			local focus = e:GetFocus()
			local assist = true

			if(focus) then
				m = focus
			else -- engineer isn't focusing, walking towards mex?
				local queue = e:GetCommandQueue()
				local p = queue[1].position


				if(queue[1].type == 'Guard') then
					if(mexPositions[p[1]] and mexPositions[p[1]][p[3]]) then
						local mex = mexPositions[p[1]][p[3]]
						m = mex:GetFocus()

						if(m and VDist3(p, e:GetPosition()) > 20) then -- 10 -> buildrange of engineer maybe?
							assist = false
						end
					end
				end
			end

			if m and (m:IsInCategory("MASSEXTRACTION") or m:IsInCategory("MASSSTORAGE")) and assist then --and not excluded[e:GetEntityId()]
				if not m:IsInCategory("MASSSTORAGE") or  e:GetWorkProgress() > 0.05 then
					if (not assisting[m]) then
						assisting[m] = {}
					end
					table.insert(assisting[m], e)
				end
			end
		end
	end

	--gather economical data for sort list
	local eco = getEconomy()
	local assistersExist=false
	local sortTable={}
	local counter=0
	local combinedMassDrain=0
	local combinedEnergyDrain=0

	for k, engineers in assisting do
		local combinedBuildRate = 0
		local lastE
		local br
		for _, e in engineers do
			br = e:GetBuildRate()
			if(not br) then
				br = e:GetBlueprint().Economy.BuildRate
			end

			if not GetIsPaused({e}) then
				local eco=e:GetEconData()
				combinedMassDrain = combinedMassDrain + eco['massRequested']
				combinedEnergyDrain = combinedEnergyDrain + eco['energyRequested']
			end

			combinedBuildRate = combinedBuildRate + br
			lastE=e
		end

		local bp = k:GetBlueprint()
		local mProduction=0
		if k:IsInCategory("MASSSTORAGE") then
			local pos=k:GetPosition()
			local mexMassProduction=0

	    	for _, mex in mexes do
	    		local pos2=mex:GetPosition()
	    		if pos2 then
		    		if VDist3(pos,pos2)<3 then
	                	local mexBP=mex:GetBlueprint()
	                	mexMassProduction=mexBP.Economy.ProductionPerSecondMass
	                	break
	    			end
				end
	    	end

	        if mexMassProduction==18 then
	        	mProduction=2.25
        	elseif mexMassProduction==6 then
	        	mProduction=0.75
	        end
		else
			mProduction=bp.Economy.ProductionPerSecondMass
		end

		if mProduction > 0 then
			local buildTime=bp.Economy.BuildTime
			local workProgress=lastE:GetWorkProgress()
			local workRemaining=(1-workProgress)
			local buildTimeRemaining=buildTime*workRemaining
			local timeRemaining=buildTimeRemaining/combinedBuildRate

			local res = {MASS={}, ENERGY={}}
			res['MASS']['Cost']=bp.Economy.BuildCostMass
			res['ENERGY']['Cost']=bp.Economy.BuildCostEnergy

			for _, resType in res do
				local Cost=resType.Cost
				resType['CostRemaining']=Cost*workRemaining
				resType['Efficiency']=resType['CostRemaining']/mProduction
				resType['TimeEfficiency']=resType['Efficiency']+timeRemaining
				resType['Drain']=Cost/(buildTime/combinedBuildRate)
			end

			table.insert(sortTable, {unit=k,res=res, combinedBuildRate=combinedBuildRate,timeRemaining=timeRemaining,workRemaining=workRemaining})
			assistersExist=true

		end
	end

	-- decide if stuff needs to be paused
	if assistersExist  then

		local pausedByMe=getUnitsPauseList()
		local pausedByMeForPower=getUnitsPauseList()
		local pausedByClickOrAssist = {}

		table.sort(sortTable, function(a, b) return a['res']['MASS']['TimeEfficiency'] < b['res']['MASS']['TimeEfficiency'] end)
		optimizeECO(eco, pausedByMe,pausedByClickOrAssist,sortTable,combinedMassDrain,combinedEnergyDrain)

	end
	ILOG("finished")
end

function optimizeECO(eco, pausedByMe,pausedByClickOrAssist,sortTable,mProd_mDrain,mProd_eDrain,mProd)

	--detect mass problem
	local mPossibleProjects=detectProblem("MASS",sortTable,eco,mProd_mDrain,5,preventM_Stall)

	--detect power problem
	local ePossibleProjects=detectProblem("ENERGY",sortTable,eco,mProd_eDrain,5,preventE_Stall)

	--decide how many projects to unpause
	local PossibleProjects=math.min(mPossibleProjects,ePossibleProjects)

	--pausing
	local lastUnitsPauseList=unitsPauseList
	unitsPauseList={}

	for i = PossibleProjects+1, table.getsize(sortTable) do
		local m = sortTable[i].unit
		for _, e in assisting[m] do
			table.insert(unitsPauseList, e)
		end
	end

	-- check if unit switched focus and needs to be unpaused
	local unitsUnPauseList={}
	local scheduledForPausingNextCycle=getUnitsPauseList()
	for _, u in lastUnitsPauseList do
		local id = u:GetEntityId()
		if not scheduledForPausingNextCycle[id] then
			--LOG("Unit has slipped out of my control, I will unpause")
			if pausedByMe[id] and CanUnpause(u) then
				table.insert(unitsUnPauseList, u) --This apparently does not work? WHY?
			end
		end
	end

	-- execute pausing and unpausing
	SetPaused(unitsPauseList, true)
	SetPaused(unitsUnPauseList, false)
end

function detectProblem(mode,sortTable,eco,mProd_Drain,BufferTime,MaxStallingEntities)

	local res=eco[mode]
	local DrainRequested=res['net_income']*GetSimTicksPerSecond()
	local NetIncome=res['net_income']*GetSimTicksPerSecond()+mProd_Drain
	local Stored=res['stored']
	local Max=res['max']

	local PossibleProjects=0
	local OrdersCount=table.getsize(sortTable)
	local CalcStored=Stored

	--check how many projects can be started efficiently
	local lastProjectTimeRemaining=sortTable[1].timeRemaining
	for j = 1, OrdersCount do
		local m = sortTable[j]

		local DrainPerSec=m.res[mode].Drain
		local CostRemaining=m.res[mode].CostRemaining

		--if the primary project can be finished without stalling then use all resources stored to do that
		local TimeToUseAllAtCurrentRate=Stored/DrainRequested*-1

		local Stalling=0
		if TimeToUseAllAtCurrentRate>=0 then
			Stalling=lastProjectTimeRemaining-TimeToUseAllAtCurrentRate
		end

		--update eco stats for following calculations
		NetIncome=NetIncome-DrainPerSec
		CalcStored=CalcStored-CostRemaining

		--calculate storedincome for current and next project
		local CalcStoredIncome=NetIncome + Stored/BufferTime

		--check if the storage is full, if so continue anyway
		local StorageLimitReached=Stored >= (Max-DrainRequested)

		--decide wether to pause or continue with upgrades
		local Problem=(j > MaxStallingEntities and CalcStoredIncome<0 and CalcStored<=0 and Stalling>=0 and not StorageLimitReached)

		--if a project is 90% completed finish it even if exceeding maximum project count at stall set by user
		if (MaxStallingEntities+1)==j then
			if m.workRemaining<0.1 then
				Problem=false
			end
		end

		--remove problematic project and stop adding new projects
		if Problem then
			--print(j,string.format("ReserveTime [%0.2f] ProjectETA [%0.2f] PredictedStall [%0.2f]",TimeToUseAllAtCurrentRate, lastProjectTimeRemaining,Stalling) )
			PossibleProjects=j-1
			break
		end

		--update eco stats for following calculations
		DrainRequested=DrainRequested-DrainPerSec
		lastProjectTimeRemaining=m.timeRemaining

		PossibleProjects=j
	end

	return PossibleProjects
end
