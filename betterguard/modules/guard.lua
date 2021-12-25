local trackedUnits = {}
local catCache = {}
local Select = import('/mods/common/select.lua')

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      LOG(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      LOG(formatting .. tostring(v))      
    else
      LOG(formatting)
	  LOG(v)
    end
  end
end

-- 1 - engi or shield or air
-- 0 - else
-- 2 - sniper/arty
function isIgnored(bp)
	if (bp.CategoriesHash.STRUCTURE or bp.CategoriesHash.AIR or bp.CategoriesHash.ENGINEER or (bp.CategoriesHash.OVERLAYDEFENSE and bp.CategoriesHash.DEFENSE and bp.CategoriesHash.SHIELD )) then
		catCache[bp.Description] = 1
		return 1
	end	
	if (bp.CategoriesHash.SNIPER or (bp.CategoriesHash.ARTILLERY and bp.CategoriesHash.TECH3)) then
		catCache[bp.Description] = 2
		return 2
	end	
	local is = 0
	if (not (catCache[bp.Description] == nil)) then
		return catCache[bp.Description]
	end
	for _, cat in bp.Categories do
		if (cat == 'ENGINEER') then			
			is = is + 3
		end
		if (cat == 'AIR') then			
			is = is + 3
		end
		if (cat == 'SNIPER') then			
			is = is + 6
		end
		if (cat == 'ARTILLERY' or cat == 'TECH3') then			
			is = is + 4
		end
		-- in case harbingers or obsidians will get correct tags
		if (cat == 'SHIELD' or cat == 'DEFENSE' or cat == 'OVERLAYDEFENSE') then			
			is = is + 1
		end
	end
	
	catCache[bp.Description] = 0	
	if (is == 3) then
		catCache[bp.Description] = 1
	end
	if (is == 6 or is == 8) then
		catCache[bp.Description] = 2
	end
	
	return catCache[bp.Description]
end

function toAngle(targetX, targetZ, unitX, unitZ) 
	local vectX = targetX - unitX
	local vectZ = targetZ - unitZ
	
	local vectX2 = vectX * vectX
	local vectZ2 = vectZ * vectZ
	
	local sum2 = vectX2 + vectZ2
			
	local curAngle = math.asin(vectX / math.pow(sum2, 0.5))
	if (unitX < targetX and unitZ < targetZ) then
	
	elseif (unitX < targetX and unitZ > targetZ) then
			curAngle = math.pi - curAngle			
	elseif (unitX < targetX and unitZ > targetZ) then
			--curAngle = math.abs(curAngle) + math.pi
	elseif (targetX < unitX  and targetZ < unitZ) then
			curAngle = math.pi + math.abs(curAngle)
	end
	
	return curAngle
end

function TrackTargets()
	if (math.random() > 0.8) then
		--LOG("TrackTargets: " .. table.getn(trackedUnits))
	end
	for index, unitsTuple in trackedUnits do
		if ((not unitsTuple.Units[1]) or (unitsTuple.Units[1]:IsDead()) or unitsTuple.TargetUnit:IsDead()) then
			--LOG("1:" .. (not unitsTuple.Units[1]) .. "2:" ..(unitsTuple.Units[1]:IsDead())  .. "3:" ..(unitsTuple.TargetUnit:IsDead()))
			trackedUnits[index] = nil
			--LOG("TrackRemoved - 1")
		else
			local comQ = unitsTuple.Units[1]:GetCommandQueue()
			if (comQ[1] == nil) then
				trackedUnits[index] = nil
				--LOG("TrackRemoved - 2")
			end		
		end
	end
	
	for index, unitsTuple in trackedUnits do		
		local uBp = unitsTuple.Units[1]:GetBlueprint()		
		local comQ = unitsTuple.Units[1]:GetCommandQueue()
		local lastCommand = comQ[table.getn(comQ)]
		
		--tprint(lastCommand)
		if (lastCommand.type == 'Guard') then
			ProcessGuardCommand(lastCommand, unitsTuple.EntityId, unitsTuple.Units, unitsTuple.TargetUnit, unitsTuple.Angle, unitsTuple.Tick, index)
		-- only clear command for snipers/arty if not guard or 'attackmove'
		elseif (isIgnored(uBp) == 2 and (lastCommand.type == 'Guard' or lastCommand.type == 'AttackMove' or lastCommand.type == 'AggressiveMove')) then
			ProcessGuardCommand(lastCommand, unitsTuple.EntityId, unitsTuple.Units, unitsTuple.TargetUnit, unitsTuple.Angle, unitsTuple.Tick, index)
		else
			--LOG("TrackRemoved - 3")
			trackedUnits[index] = nil
		end
	end	
end

function ProcessGuardCommand(command, entityId, units, targetUnit, Angle, TickIn, index)
	local target = targetUnit or command.Target
	local unitsTable = command.Units or units
	local numUnits = table.getn(unitsTable)
	
	local entId = target.EntityId or entityId or targetUnit:GetEntityId()
	local targetUnit = GetUnitById(entId)
	local tX, tY, tZ = unpack(targetUnit:GetPosition())			
	local tBp = targetUnit:GetBlueprint() 
	-- wpn Radius of followed unit
	local minRadius = tBp.Weapon[1].MaxRadius or tBp.Intel.VisionRadius or 16
	-- follow stealth field	
	local followAngle = Angle

	--tprint(tBp)	
	for index, unit in unitsTable do
		local uBp = unit:GetBlueprint()
		if (unit == nil or unit:IsDead()) then
			unitsTable[index] = nil
			return true
		end

		-- if we have engi selected do nothing	
		if (isIgnored(uBp) == 1) then
			return true
		end
	end
	
	local unitCount = table.getn(unitsTable)	
	-- circle radius becomes too big, no point in doing something
	if (unitCount >= 15) then
		return true
	end
	
	local Tick = GameTick()
	
	if (not TickIn) then
		TickIn = 0
	end
	
	local trackedDiff = VDist2(tX, tZ, trackedUnits[index].tX or 0 , trackedUnits[index].tZ or 0)
	--print(trackedDiff .. "-" .. Tick .. "-" .. TickIn)
	-- re-issue commands only if target has moved or more than 50 seconds passed
	if (index and (
		((Tick - TickIn) < 50) 
		and
		(trackedDiff < 1)
		)) then
		return
	end
	
	if (index) then
		trackedUnits[index].Tick = Tick
		trackedUnits[index].tX = tX
		trackedUnits[index].tZ = tZ
	end
	
	if (not followAngle) then
		local counter = 0
		local avgX = 0
		local avgZ = 0
		for index, unit in unitsTable do
			if (not unit:IsDead()) then
				local uX, uY, uZ = unpack(unit:GetPosition())
				avgX = avgX + uX
				avgZ = avgZ + uZ
				counter = counter + 1
			end
		end
		followAngle = toAngle(avgX / counter, avgZ / counter, tX, tZ)
	end
	
	for index, unit in unitsTable do
		if (unit:IsDead()) then
			unitsTable[index] = nil
		end
		
		local optimalRadius2
		
		-- idea, calculate 'usefull' follow range and make a bunch of move/attackmove commands so scouts wont follow in 10-15 range and won't be killed and long-range stuff like snipers will follow in much longer range
		if (not unit:IsDead()) then
			local uBp = unit:GetBlueprint()
			local uX, uY, uZ = unpack(unit:GetPosition())
			
			if (not optimalRadius2) then
				local uSize = math.max(uBp.SizeX, uBp.SizeZ)
				optimalRadius2 = unitCount * uSize
			end
			
			--tprint(uBp)
						
			local usefullRange = math.max(
				math.max(uBp.Intel.RadarRadius, uBp.Intel.RadarStealthFieldRadius),
				math.max(uBp.Weapon[2].MaxRadius or 16, uBp.Weapon[1].MaxRadius or 16)
			);
			
			if (optimalRadius2 > usefullRange) then
				optimalRadius2 = usefullRange * 0.8
			end
			
			--LOG("uR" .. usefullRange .. "mR" .. minRadius .. "oR" .. optimalRadius2)
			local followDist = (usefullRange - minRadius - optimalRadius2 * 0.5) * 0.6;			
			
			if (tBp.Intel.RadarStealthFieldRadius > 0) then
				followDist = 0
				optimalRadius2 = (tBp.Intel.RadarStealthFieldRadius - 8) * 0.8
			end
			
			-- make antiair follow closer
			if (uBp.CategoriesHash.ANTIAIR) then
				followDist = 5
			end
			
			if (tBp.Defense.Shield.ShieldSize > 0) then
				followDist = 0
				optimalRadius2 = (tBp.Defense.Shield.ShieldSize / 2 - 5) * 0.8
			end
			
			if (followDist < 2) then
				followDist = 2
			end
						
			local minCicleAngle = -45
			local cicleAngle = 90
			local ciclePiAngle = math.pi / 2
			
				
			if (not followAngle) then
				followAngle = toAngle(uX, uZ, tX, tZ)
			end
							
			while (followAngle > 2 * math.pi) do
				followAngle = followAngle - 2*math.pi
			end
						
			local newX = tX + (followDist * math.sin(followAngle))			
			local newZ = tZ + (followDist * math.cos(followAngle))
												
			local rotateAngle = (minCicleAngle + (index / numUnits) * cicleAngle)/ cicleAngle * ciclePiAngle
			if (numUnits == 1) then
				rotateAngle = 0
			end
				
			local circleX = math.sin(followAngle + rotateAngle) * optimalRadius2
			local circleZ = math.cos(followAngle + rotateAngle) * optimalRadius2
			local disiredX = newX + circleX
			local disiredZ = newZ + circleZ			
			local distToTarget = VDist2(disiredX, disiredZ, uX, uZ)
			
			if (isIgnored(uBp) == 2) and (distToTarget < 10) then
				local comQ = unit:GetCommandQueue()
				local comLen = table.getn(comQ)
				local lastCommand = comQ[comLen]
				
				--tprint(lastCommand)
				
				if (comLen > 1 and lastCommand.type == "AttackMove" or lastCommand.type == "AggressiveMove" and (VDist2(disiredX, disiredZ, lastCommand.position[1] or 0, lastCommand.position[3] or 0) < 10)) then
				else
					-- do not move arty or snipers if less than 5 units, this will break siege mode or targeting, issue attack move instead				
					Select.Hidden(
						function()
							local a = math.random()
							local b = math.random()
							if ((math.abs(a - 0.5) + math.abs(b - 0.5)) < 0.25) then
								local divider = 0.5 / (math.abs(a - 0.5) + math.abs(b - 0.5))
								
								a = (a - 0.5) * divider + 0.5
								b = (b - 0.5) * divider + 0.5
							end
							local unit_id = unit:GetEntityId()
							SelectUnits({unit})
							local position = {disiredX, uY, disiredZ}
							local position2 = {disiredX + (20 * math.sin(followAngle)), uY, disiredZ + (20 * math.cos(followAngle))}
							-- issue attack-move command
							local cb = {Func = "AttackMove", Args = {["Target"] = position, ["unit_id"] = unit_id, ["ids"] = {unit_id}, Clear = true, From = GetFocusArmy(), [2] = {unit_id}}}
							SimCallback( cb, true)
							
							local cb = {Func = "AttackMove", Args = {["Target"] = position2, ["unit_id"] = unit_id, ["ids"] = {unit_id}, Clear = false, From = GetFocusArmy(), [2] = {unit_id}}}
							SimCallback( cb, true)
							
							local cb = {Func = "AttackMove", Args = {["Target"] = position, ["unit_id"] = unit_id, ["ids"] = {unit_id}, Clear = false, From = GetFocusArmy(), [2] = {unit_id}}}
							SimCallback( cb, true)
						end
					)				
				end
			elseif (isIgnored(uBp) == 2) then
				local orders = {
					-- position and circle a bit
					{
						["CommandType"] = "Move", 
						["Position"] = {disiredX, tY, disiredZ}
					},
					-- follow after
					{
						["CommandType"] = "Guard", 
						["EntityId"] = entId
					},
				}
				
				SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = orders,
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true) 
			else
				local orders = {
					-- position and circle a bit
					{
						["CommandType"] = "Move", 
						["Position"] = {disiredX, tY, disiredZ}
					},
					{
						["CommandType"] = "Move", 
						["Position"] = {newX + circleX - 2, tY, newZ + circleZ + 2}
					},
					{
						["CommandType"] = "Move", 
						["Position"] = {newX + circleX - 2, tY, newZ + circleZ - 2}
					},
					{
						["CommandType"] = "Move", 
						["Position"] = {newX + circleX + 2, tY, newZ + circleZ - 2}
					},
					{
						["CommandType"] = "Move", 
						["Position"] = {newX + circleX + 2, tY, newZ + circleZ + 2}
					},
					{
						["CommandType"] = "Move", 
						["Position"] = {newX + circleX - 2, tY, newZ + circleZ + 2}
					},
					-- follow after
					{
						["CommandType"] = "Guard", 
						["EntityId"] = entId
					},
				}
				
				SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = orders,
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true) 
				
				--unit:SetCustomName("fA:" .. followAngle .. " rA:" .. rotateAngle .. "fD:" .. followDist .. "oR:" .. optimalRadius2)
			end
		end
	end
	
	
	
	if units == nil then
		table.insert(trackedUnits, 
			{
				["Units"] = unitsTable, 
				["EntityId"] = entId, 
				["TargetUnit"] = targetUnit,
				["Tick"] = Tick,
				["tX"] = tX,
				["tZ"] = tZ,
				["Angle"] = followAngle 
			}
		);
	end
end