local flankingUnits = {}
local lastDamage = 0

function tLOG (tbl, indent)	
  if not indent then indent = 0 end
  formatting = string.rep("  ", indent)
  if type(tbl) == "nil" then
	LOG(formatting .. "nil")
	return
  end
  --LOG(type(tbl))
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
	if type(v) == "nil" then
	  LOG(formatting .. "NIL")
    elseif type(v) == "table" then
      LOG(formatting)
      tLOG(v, indent+1)
    elseif type(v) == 'boolean' then
      LOG(formatting .. tostring(v))      
    else
      LOG(formatting)
	  LOG(v)
    end
  end
end

function tprint (tbl, indent)	
  if not indent then indent = 0 end
  formatting = string.rep("  ", indent)
  if type(tbl) == "nil" then
	print(formatting .. "nil")
	return
  end
  if type(tbl) != "table" then
	print(formatting .. tbl)
	return
  end
  --LOG(type(tbl))
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
	if type(v) == "nil" then
	  print(formatting .. "NIL")
    elseif type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(v)
    end
  end
end

function TrackDamage(tick)
	local damagedUnit = nil
	for index, unitsTuple in flankingUnits do		
		local damage = 0
		local lastMinHp = unitsTuple.MinHp;
		
		if ((unitsTuple.TrackingUnit == nil) or (unitsTuple.TrackingUnit and unitsTuple.TrackingUnit:IsDead())) then
			lastMinHp = 1
		end
		local deadUnit = nil
		local aliveUnit = nil
			
		for unitIndex, unit in unitsTuple.Units do			
			if (unit) then
				if (unit:IsDead()) then
					deadUnit = unit
					lastMinHp = 0
					flankingUnits[index].Units[unitIndex] = nil
					damage = unit:GetMaxHealth() or 100
				else
					aliveUnit = unit
				end
			end
			if (unit and not unit:IsDead()) then
				local hpRatio = unit:GetHealth() / unit:GetMaxHealth() * 1.01
				if (unit:GetShieldRatio() > 0) then
					hpRatio = hpRatio / 10 + unit:GetShieldRatio() * 0.91
				end
								
				if (hpRatio < lastMinHp) then					
					damagedUnit = unit
					damage = (lastMinHp - hpRatio) * unit:GetMaxHealth()
					lastMinHp = hpRatio
				end			
			end
		end
		
		if (not damagedUnit and deadUnit) then
			damagedUnit = deadUnit
		end
        
        if (damagedUnit) then
		    local turretAngle = 0
            local dx,dy,dz = unpack(damagedUnit:GetPosition())
			if (not damagedUnit:IsDead()) then
				local dCommands = damagedUnit:GetCommandQueue()
				local tx,ty,tz = unpack(dCommands[table.getn(dCommands)].position)
			
				turretAngle = toAngle(tx, tz, dx, dz)
				--damagedUnit:SetCustomName("dmg, angle:" .. turretAngle .. "dmg" .. damage .. 'tick' .. tick)
			elseif (aliveUnit and not aliveUnit:IsDead()) then
				local dCommands = aliveUnit:GetCommandQueue()
				local tx,ty,tz = unpack(dCommands[table.getn(dCommands)].position)
			
				turretAngle = toAngle(tx, tz, dx, dz)
				--aliveUnit:SetCustomName("alive, angle:" .. turretAngle)
			end
						
			flankingUnits[index].Angle = turretAngle + math.pi
                        
            --LOG("onDamage" .. turretAngle)
			
			flankingUnits[index].TrackingUnit = damagedUnit
            flankingUnits[index].MinHp = lastMinHp
			flankingUnits[index].GameTick = GameTick()
			if (damage > 0) then
				flankingUnits[index].Damage = damage
			end
        end
	end
	
	return damagedUnit != nil
end

function toAngle(targetX, targetZ, unitX, unitZ) 
	local vectX = unitX - targetX
	local vectZ = unitZ - targetZ
	
	local vectX2 = vectX * vectX
	local vectZ2 = vectZ * vectZ
	
	local sum2 = vectX2 + vectZ2
			
	--local curAngle = math.asin(math.min(math.abs(vectZ), math.abs(vectX)) / math.pow(sum2, 0.5))
	local curAngle = math.atan2(unitX - targetX, unitZ - targetZ)
	--print("curAngle" .. curAngle .. "unitX" .. unitX .. "targetX" .. targetX .. "unitZ" .. unitZ .. "targetZ" .. targetZ)
	
	if (vectX > 0 and vectZ > 0) then
	elseif (vectX > 0 and vectZ < 0) then
		--curAngle = curAngle + 0.5*math.pi;
	elseif (vectX < 0 and vectZ < 0) then
		--curAngle = curAngle + math.pi;
	elseif (vectX < 0 and vectZ > 0) then
		--curAngle = curAngle + 1.5*math.pi;
	end
	
	while (curAngle > 2 * math.pi) do
		curAngle = curAngle - 2*math.pi
	end
	
	return curAngle
end

function findAlive(units)
	for index, unit in units do
		if (unit and not (unit:IsDead())) then			
			return unit
		end
	end	
	return nil
end

-- 
local iteration = 1
local iterationlimit = 4
-- global variables =(
local damagetick = 0
local tick = 0

function TrackMovingTargets(damagetick_, tick_)
	-- cleanup flankingUnits if first unit does not have any command (it means they destroyed their target or got near)	
	tick = tick_
	damagetick = damagetick_
	
	for index, unitsTuple in flankingUnits do
		local unit = findAlive(unitsTuple.Units)
		if (unit and not (unit:IsDead())) then
			local comQ = unit:GetCommandQueue()
			
			--tprint(comQ)
			if (comQ[1] == nil) then
				flankingUnits[index] = nil
				--print("command lost 1")
			end		
		else
			flankingUnits[index] = nil
			--print("command lost 2")
		end
	end
	
	for index, unitsTuple in flankingUnits do
		local unit = findAlive(unitsTuple.Units)
		if (unit) then
			local comQ = unit:GetCommandQueue()
			local lastCommand = comQ[table.getn(comQ)]
			
			local targetEstimate = ProcessAttackCommand(lastCommand, unitsTuple.EntityId, unitsTuple.Units, unitsTuple.Angle, unitsTuple.GameTick, unitsTuple.TrackingUnit, unitsTuple.Damage, unitsTuple.Target, iteration)
			if (targetEstimate == nil) then
				flankingUnits[index] = nil
				--print("command lost 3")
			else
				flankingUnits[index].Target = targetEstimate
			end
		else
			flankingUnits[index] = nil
		end
	end	
	
	-- used for tracking time for newOrders shufflings
	iteration = iteration + 1
	
	if (iteration > iterationlimit) then
		iteration = 1
	end
end

function ProcessAttackCommand(command, entityId, units, angle, gameTick, trackingUnit, damage, targetName, iteration)	
	local iteration = (iteration) or 1
	local currentTick = GameTick()
	local target = command.Target;
	if (command.CommandType != "Attack" and command.type != "Attack" and command.CommandType != "FormAttack") then
		--tLOG(command)
		--tprint(command)
		--print("target is nil")
		return
	end
	local targetX, targetY, targetZ = unpack(target.Position or command.position)
	local unitsTable = command.Units or units
	local numUnits = table.getn(unitsTable)
	local curAngle
	damage = damage or 0
	targetName = targetName or "COM"
	--print("PROCESS COMMAND")
	--print("units:" .. table.getn(unitsTable))
	for index, unit in unitsTable do
		repeat
		if (not unit:IsDead()) then
			--tprint(unit:GetBlueprint())
			local bp = unit:GetBlueprint()
			local maxSpeed = bp.Physics.MaxSpeed or 10;
			local wpnRange = bp.Weapon[1].MaxRadius or 1;
			local x, y, z = unpack(unit:GetPosition())			
			--maxSpeed = maxSpeed * 0.8
			
			local vectX = targetX - x
			local vectZ = targetZ - z
			
			local vectX2 = vectX * vectX
			local vectZ2 = vectZ * vectZ
			
			local sum2 = vectX2 + vectZ2

			local curAngleOld = (toAngle(targetX, targetZ, x, z) + math.pi)
			local curAngle = (angle) or (toAngle(targetX, targetZ, x, z) + math.pi)
			--print("curAngle" .. curAngle  .. "angle_in" .. (angle or "") .. "targetX" .. targetX .. "targetZ" .. targetZ ..  "x" .. x  .. "z" .. z)
			local baseAngle = curAngle
			local modifiedAngle = 0					
			
			-- t1 land scout 
			if (bp.CategoriesHash.TECH1 and bp.CategoriesHash.SCOUT and bp.CategoriesHash.LAND) then
				if (targetX > 0) then
					--unit:SetCustomName("track:" .. targetX .. "," .. targetZ)

					-- 
					SimCallback( {
						Func = "GiveOrders",
						Args = { 
							unit_orders = {{
									["CommandType"] = "Attack", 
									["EntityId"] = (target.EntityId or entityId)
								}, {
									["CommandType"] = "Move", 
									["Position"] = {targetX - 1, targetY, targetZ - 1}
								},{
									["CommandType"] = "Attack", 
									["EntityId"] = (target.EntityId or entityId)
								}},
							unit_id     = unit:GetEntityId(),
							From = GetFocusArmy()
						}
					}, true)
					
				end
				do break end -- goes to next iteration of for (continue-like hack)
			end
			
			-- non cybran tank probably
			if (damage >= 24 and damage <= 40) then
				targetName = 'TANK'
			end
			
			if (damage >= 8 and damage <= 9) then
				targetName = 'MANTIS'
			end
			
			if (damage >= 50 and damage <= 51) then
				targetName = 'T1PD'
			end
			
			if (damage >= 99 and damage <= 101) then
				targetName = 'COM'
			end
			
			
			local targetYawSpeed = 90 / 180 * math.pi -- comm
			if (targetName == 'TANK') then
				targetYawSpeed = 100 / 180 * math.pi
			end
			if (targetName == 'T1PD') then
				targetYawSpeed = 90 / 180 * math.pi
			end
			if (gameTick) then										
				
				if (damage >= 400) then
					targetYawSpeed = 40 / 180 * math.pi -- spiderbot
					targetName = "MK"
				end
				
				--print("Current " .. currentTick .. " gameTick " .. gameTick .. " damage " .. damage .. " angle " .. angle )
				
				modifiedAngle = (currentTick - gameTick) * targetYawSpeed / 10
				
				curAngle = curAngle + modifiedAngle
			end
			
			local stayAway = (targetName == "TANK" or targetName == "COM" or targetName == "T1PD" or targetName == "MANTIS") or (wpnRange > 60)
						
			if (stayAway) then
				-- do not try to circle if we fighting tank/com just run around
				curAngle = curAngle - modifiedAngle
				modifiedAngle = 0
			end
			
			while (curAngle > 2 * math.pi) do
				curAngle = curAngle - 2*math.pi
			end
			
			
			local newX = targetX + (wpnRange * math.sin(curAngle) * 0.3)			
			local newZ = targetZ + (wpnRange * math.cos(curAngle) * 0.3)
					
			--LOG("x,y,z" .. targetX .. "," .. targetY .. "," .. targetZ )
			--LOG("NEW: x,y,z" .. newX .. "," .. targetY .. "," .. newZ )
								
			local rotateAngle = (- 45 + (index / numUnits) * 90)/ 90 * math.pi / 2
			
			local circleX = math.sin(curAngle + rotateAngle) * wpnRange * 0.3
			local circleZ = math.cos(curAngle + rotateAngle) * wpnRange * 0.3
			local flipX = 0
			local flipZ = 0
			local flipX2 = 0
			local flipZ2 = 0
					
			flipX = math.sin(curAngleOld + (math.pi / 6)) * maxSpeed * 0.8
			flipZ = math.cos(curAngleOld + (math.pi / 6)) * maxSpeed * 0.8
			flipX2 = math.sin(curAngleOld - (math.pi / 6)) * maxSpeed * 0.8
			flipZ2 = math.cos(curAngleOld - (math.pi / 6)) * maxSpeed * 0.8

			--while (flipX > -1 and flipX < 1 and flipZ > -1 and flipZ < 1) do
				--flipX = flipX * 2
				--flipZ = flipZ * 2
				--flipX2 = flipX2 * 2
				--flipZ2 = flipZ2 * 2
			--end	
			--tprint({["stayAway"] = stayAway, ["wpnRange"] = wpnRange, ["maxSpeed"] =maxSpeed});
			if (math.mod(currentTick, 2) == 1) then
				-- swap
				local temp = flipX
				flipX = flipX2
				flipX2 = temp
				temp = flipZ
				flipZ = flipZ2
				flipZ2 = temp
			end

			local distA = VDist2(x, z, targetX, targetZ)

			-- do not try to doodge too close - pointless
			--print("distA" .. distA .. "target:" .. targetName .. 'sp:' .. maxSpeed)
			--tprint("flipX" .. flipX .. "flipZ" .. flipZ)			
			
			
			-- try doddging and running behind unit
			if (false and (distA < 30) and (distA > (maxSpeed * 3)) and (maxSpeed >= 3.0) and (targetName == "COM" or targetName == 'T1PD')) then
				local orders = {}
				
				local index = 0
				local num = math.ceil(distA / math.sqrt(maxSpeed * 0.8));
				
				if (distA > maxSpeed) then
					local xChange = (newX - x) / num;
					local zChange = (newZ - z) / num;
					while (index < num) do
						table.insert(orders, {
								["CommandType"] = "Move", 
								["Position"] = {x + flipX  + xChange * index, targetY, z + flipZ + zChange * index}
							}
						);
						table.insert(orders, {
								["CommandType"] = "Move", 
								["Position"] = {x + flipX2 + xChange * (index + 1), targetY, z + flipZ2 + zChange * (index + 1)}
							}
						);
						
						index = index + 2
					end
				end
				
				-- behind
				table.insert(orders,{
								["CommandType"] = "Move", 
								["Position"] = {newX, targetY, newZ}
							});
				table.insert(orders,-- queue attack last, so we can follow unit if he moves
							{
								["CommandType"] = "Attack", 
								["EntityId"] = (target.EntityId or entityId)
							});
			
				SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = orders,
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true) 				
			-- probably arty/sniper/fatboy
			elseif (
			--((distA < 25) or (distA > wpnRange)) 
			true
			and (maxSpeed >= 1.8) and (wpnRange >= 29) and stayAway) then
				-- TODO don't issue commands to frequntly or units dont ahve time to fire (read reload cycle ?)
				local orders = {}
				local flag = false
			
				local newXwpnRng = targetX - (wpnRange * math.sin(curAngle) * 0.9)			
				local newZwpnRng = targetZ - (wpnRange * math.cos(curAngle) * 0.9)	
												
				if (math.abs(newXwpnRng - targetX) > 1 and math.abs(newZwpnRng - targetZ) and distA < (wpnRange - 3)) then
					table.insert(orders,{
						["CommandType"] = "Move", 
						["Position"] = {newXwpnRng, targetY, newZwpnRng}
					});
					flag = true
				end
				if (units == nil or flag) then
					table.insert(orders,
					{
						["CommandType"] = "Attack", 
						["EntityId"] = (target.EntityId or entityId)
					});
				end
				
				SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = orders,
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true)				
				
			-- run till weapon range and run in circles after taht
			elseif ((distA < 30) and (maxSpeed >= 3) and stayAway) then
				local orders = {}
				local maxSpeed8X = maxSpeed * 0.6 * math.sin(curAngle)
				local maxSpeed8Z = maxSpeed * 0.6 * math.cos(curAngle)
								
				-- run till wpnRange and circle after								
				local newXwpnRng = targetX - (wpnRange * math.sin(curAngle) * 0.8)			
				local newZwpnRng = targetZ - (wpnRange * math.cos(curAngle) * 0.8)				
				
				local index = 0
				local num = math.ceil(distA / math.sqrt(maxSpeed * 0.8));
				
				local xChange = (newXwpnRng - x) / num;
				local zChange = (newZwpnRng - z) / num;
				
				if (distA > maxSpeed and distA > wpnRange * 1.1) then					
					while (index < num) do
						table.insert(orders, {
								["CommandType"] = "Move", 
								["Position"] = {x + flipX  + xChange * index, targetY, z + flipZ + zChange * index}
							}
						);
						table.insert(orders, {
								["CommandType"] = "Move", 
								["Position"] = {x + flipX2 + xChange * (index + 1), targetY, z + flipZ2 + zChange * (index + 1)}
							}
						);
						
						index = index + 2
					end
				end
				
				local newSpeed = maxSpeed * 3
				
				local newOrders = {}
				
				table.insert(newOrders, {["CommandType"] = "Move", ["Position"] = {
					newXwpnRng + newSpeed * math.sin(curAngle + math.pi * (3/6)), targetY, 
					newZwpnRng + newSpeed * math.cos(curAngle + math.pi * (3/6))}
				})

				if (distA > wpnRange * 0.95) then
					table.insert(newOrders, {["CommandType"] = "Move", ["Position"] = {
						newXwpnRng + newSpeed * math.sin(curAngle + math.pi * (5/6)), targetY, 
						newZwpnRng + newSpeed * math.cos(curAngle + math.pi * (5/6))}
					})				
				
				
					table.insert(newOrders, {["CommandType"] = "Move", ["Position"] = {
						newXwpnRng + newSpeed * math.sin(curAngle + math.pi * (7/6)), targetY, 
						newZwpnRng + newSpeed * math.cos(curAngle + math.pi * (7/6))}
					})
				end
					
					table.insert(newOrders, {["CommandType"] = "Move", ["Position"] = {
						newXwpnRng + newSpeed * math.sin(curAngle + math.pi * (9/6)), targetY, 
						newZwpnRng + newSpeed * math.cos(curAngle + math.pi * (9/6))}
					})				
				
				
																
				for k, v in newOrders do
					if (k >= iteration) then
						table.insert(orders, v)
					end
				end
				
				for k, v in newOrders do
					if (k < iteration) then
						table.insert(orders, v)
					end
				end
				
				-- behind
				table.insert(orders,{
								["CommandType"] = "Move", 
								["Position"] = {newX, targetY, newZ}
							});
				table.insert(orders,-- queue attack last, so we can follow unit if he moves
							{
								["CommandType"] = "Attack", 
								["EntityId"] = (target.EntityId or entityId)
							});
			
				SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = orders,
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true)
			else 					
				SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = {
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
						},
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true) 
			end
			
			if (not (trackingUnit and not (trackingUnit:IsDead()) and (unit:GetEntityId() == trackingUnit:GetEntityId()))) then
				--unit:SetCustomName("bA:" .. curAngle .. " mA:" .. modifiedAngle .. "target:" .. targetName .. "damage" .. damage 
				--.. "iteration" .. iteration .. "dmgtick" .. damagetick .. "tick" .. tick)
			end
			
			lastX = x
			lastZ = z
		end
		until true
	end
	
	
	
	if units == nil then
		addFlankers(command.Units, target.EntityId, curAngle)
	end
	return targetName
end


function addFlankers(units, entityId, angle)
	table.insert(flankingUnits, {["Units"] = units, ["EntityId"] = entityId, ["Angle"] = angle, ["MinHp"] = 1, ["TrackingUnit"] = units[1],
		["GameTick"] = nil, ["Damage"] = 0, ["Target"] = "COM"
	});
end
