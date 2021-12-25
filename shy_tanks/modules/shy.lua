local trackedUnits = {}
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
      LOG(formatting .. v)
    end
  end
end

function isGroupDamaged(unitsTuple)
	local groupIsDamaged = false
	for unitIndex, unit in unitsTuple.Units do			
		if (unit) then
			if (unit:IsDead()) then
				flankingUnits[index].Units[unitIndex] = nil
			end
		end
		if (unit and not unit:IsDead()) then
			local id = unit:GetEntityId()
			local currentHp = unit:GetHealth()
							
			if (currentHp < unitsTuple.HpMap[id]) then					
				groupIsDamaged = true
			end
			unitsTuple.HpMap[id] = currentHp
		end
	end
	
	return groupIsDamaged
end

function TrackDamagedAndRetreat(tick)
	local damagedUnit = nil
	for index, unitsTuple in trackedUnits do		
		local groupIsDamaged = isGroupDamaged(unitsTuple)
		
		if (groupIsDamaged) then
			-- issue fallback ~1 second move and attack move command, if there is only attackmove command
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

function ProcessAttackCommand(command, entityId, units, angle, gameTick, trackingUnit, damage, targetName, iteration)	
	local iteration = (iteration) or 1
	local currentTick = GameTick()
	local target = command.Target;
	local targetX, targetY, targetZ = unpack(target.Position or command.position)
	local unitsTable = command.Units or units
	local numUnits = table.getn(unitsTable)
	local curAngle
	damage = damage or 0

	for index, unit in unitsTable do
		if (not unit:IsDead()) then
			--tprint(unit:GetBlueprint())
			local bp = unit:GetBlueprint()
			local maxSpeed = bp.Physics.MaxSpeed or 10;
			local wpnRange = bp.Weapon[1].MaxRadius or 1;
			local x, y, z = unpack(unit:GetPosition())			
			--maxSpeed = maxSpeed * 0.8
	end
	
	
	
	if units == nil then
		addTracked(command.Units)
	end
	return targetName
end


function addTracked(units, entityId, angle)
	table.insert(trackedUnits, {["Units"] = units, ["GameTick"] = nil, ["PositionsMap"] = {}, ["HpMap"] = {}});
end
