local flankingUnits = {}

function TrackDamage()
	for index, unitsTuple in flankingUnits do
		local damagedUnit = nil
		local lastMinHp = unitsTuple.MinHp;
		
		if ((unitsTuple.TrackingUnit == nil) or (unitsTuple.TrackingUnit and unitsTuple.TrackingUnit:IsDead())) then
			lastMinHp = 1
		end
			
		for unitIndex, unit in unitsTuple.Units do			
			if (not unit:IsDead()) then
				local hpRatio = unit:GetHealth() / unit:GetMaxHealth() * 1.01
				if (unit:GetShieldRatio() > 0) then
					hpRatio = hpRatio / 10 + unit:GetShieldRatio() * 0.91
				end
				
				if (hpRatio < lastMinHp) then
					lastMinHp = hpRatio
					damagedUnit = unit
				end			
			end
		end
		
		--LOG("hpRatio" .. lastMinHp)
        
        if (damagedUnit) then
		
            local dCommands = damagedUnit:GetCommandQueue()
            local dx,dy,dz = unpack(damagedUnit:GetPosition())
            local tx,ty,tz = unpack(dCommands[table.getn(dCommands)].position)
            local turretAngle = toAngle(tx, tz, dx, dz)
            
            flankingUnits[index].TrackingUnit = damagedUnit
            flankingUnits[index].MinHp = lastMinHp
			flankingUnits[index].GameTick = GameTick()
			flankingUnits[index].Angle = turretAngle
            --LOG("onDamage" .. turretAngle)
            damagedUnit:SetCustomName("dmg, angle:" .. turretAngle)
        end
	end
end

function toAngle(targetX, targetZ, unitX, unitZ) 
	local vectX = unitX - targetX
	local vectZ = unitZ - targetZ
	
	local vectX2 = vectX * vectX
	local vectZ2 = vectZ * vectZ
	
	local sum2 = vectX2 + vectZ2
			
	local curAngle = math.asin(math.min(math.abs(vectZ), math.abs(vectX)) / math.pow(sum2, 0.5))
	
	if (vectX > 0 and vectZ > 0) then
	elseif (vectX > 0 and vectZ < 0) then
		curAngle = curAngle + 0.5*math.pi;
	elseif (vectX < 0 and vectZ < 0) then
		curAngle = curAngle + math.pi;
	elseif (vectX < 0 and vectZ > 0) then
		curAngle = curAngle + 1.5*math.pi;
	end
	return curAngle
end

function TrackMovingTargets()
	-- cleanup flankingUnits if first unit does not have any command (it means they destroyed their target)
	
	for index, unitsTuple in flankingUnits do
		if (not unitsTuple.Units[1] or unitsTuple.Units[1]:IsDead()) then
			flankingUnits[index] = nil
		else
			local comQ = unitsTuple.Units[1]:GetCommandQueue()
			if (comQ[1] == nil) then
				flankingUnits[index] = nil
			end		
		end
	end
	
	for index, unitsTuple in flankingUnits do
		local comQ = unitsTuple.Units[1]:GetCommandQueue()
		local lastCommand = comQ[table.getn(comQ)]
		
		ProcessAttackCommand(lastCommand, unitsTuple.EntityId, unitsTuple.Units, unitsTuple.Angle, unitsTuple.GameTick, unitsTuple.TrackingUnit)
	end	
end

function ProcessAttackCommand(command, entityId, units, angle, gameTick, trackingUnit)
	local target = command.Target;
	local targetX, targetY, targetZ = unpack(target.Position or command.position)
	local unitsTable = command.Units or units
	local numUnits = table.getn(unitsTable)
	local curAngle
	
	local entId = target.EntityId or entityId;
	local targetUnit = GetUnitById(entId)
	local tBp = targetUnit:GetBlueprint() 
	-- todo: only surround units in the 'back' or they don't have 'crush/collsion damage'
	local targetYawSpeed = tBp.Weapon[1].TurretYawSpeed / 180 * math.pi
	local minRadius = tBp.Weapon[1].MinRadius
	
	local unitCount = table.getn(unitsTable)
	for index, unit in unitsTable do
		if (unit:IsDead()) then
			unitsTable[index] = nil
		end
		if (not unit:IsDead()) then
			local uBp = unit:GetBlueprint()
			local wpnRange = uBp.Weapon[1].MaxRadius or 1;			
			local x, y, z = unpack(unit:GetPosition())			
			
			local uSize = math.max(uBp.SizeX, uBp.SizeZ)
			
			local vectX = targetX - x
			local vectZ = targetZ - z
			
			local vectX2 = vectX * vectX
			local vectZ2 = vectZ * vectZ
			
			local sum2 = vectX2 + vectZ2
			
			local optimalRadius = wpnRange * 0.3
			local optimalRadius2 = unitCount * uSize
			local minCicleAngle = -45
			local cicleAngle = 90
			local ciclePiAngle = math.pi / 2
			
			-- make units close enought to fire
			if (optimalRadius2 + optimalRadius > wpnRange) then
				optimalRadius2 = (wpnRange - optimalRadius) * 0.9
			end
			
			
			local curAngle = (angle) or (toAngle(targetX, targetZ, x, z) + math.pi)
			local baseAngle = curAngle
			local modifiedAngle = ""
						
			if (gameTick) then
				modifiedAngle = (GameTick() - gameTick) * targetYawSpeed
				
				curAngle = curAngle + modifiedAngle
			end
			
			while (curAngle > 2 * math.pi) do
				curAngle = curAngle - 2*math.pi
			end
			
			-- surround if minRadius is available
			if (minRadius and minRadius < optimalRadius) then
				--optimalRadius = minRadius
				optimalRadius2 = minRadius * 0.95
				optimalRadius = 0
				minCircleAngle = -180
				circleAngle = 360
				ciclePiAngle = math.pi * 2
				curAngle = 0
			end			
			
			local newX = 0
			local newY = 0
			local newX = targetX + (optimalRadius * math.sin(curAngle))			
			local newZ = targetZ + (optimalRadius * math.cos(curAngle))
					
			--LOG("x,y,z" .. targetX .. "," .. targetY .. "," .. targetZ )
			--LOG("NEW: x,y,z" .. newX .. "," .. targetY .. "," .. newZ )
								
			local rotateAngle = (minCicleAngle + (index / numUnits) * cicleAngle)/ cicleAngle * ciclePiAngle
			
			local circleX = math.sin(curAngle + rotateAngle) * optimalRadius2
			local circleZ = math.cos(curAngle + rotateAngle) * optimalRadius2
			
			local orders = {
				-- side 
				{
					["CommandType"] = "Move", 
					["Position"] = {newX + circleX, targetY, newZ + circleZ}
				},
				-- behind
				{
					["CommandType"] = "Move", 
					["Position"] = {newX, targetY, newZ}
				},
				-- queue attack last, so we can follow unit if he moves
				{
					["CommandType"] = "Attack", 
					["EntityId"] = (target.EntityId or entityId)
				},
			}
			
			if (optimalRadius == 0) then
					orders = {
					{
						["CommandType"] = "Move", 
						["Position"] = {newX + circleX, targetY, newZ + circleZ}
					},
					{
						["CommandType"] = "Attack", 
						["EntityId"] = (target.EntityId or entityId)
					},
				}
			end
			
			SimCallback( {
				Func = "GiveOrders",
				Args = { 
					unit_orders = orders,
					unit_id     = unit:GetEntityId(),
					From = GetFocusArmy()
				}
			}, true) 
			
			if (not (trackingUnit and not (trackingUnit:IsDead()) and (unit:GetEntityId() == trackingUnit:GetEntityId()))) then
				unit:SetCustomName("bA:" .. curAngle .. " mA:" .. modifiedAngle .. " tYSPD" .. targetYawSpeed)
			end
			
			lastX = x
			lastZ = z
		end
	end
	
	
	
	if units == nil then
		addFlankers(command.Units, target.EntityId, curAngle)
	end
end


function addFlankers(units, entityId, angle)
	table.insert(flankingUnits, {["Units"] = units, ["EntityId"] = entityId, ["Angle"] = angle, ["MinHp"] = 1, ["TrackingUnit"] = units[1],
		["GameTick"] = nil
	});
end
