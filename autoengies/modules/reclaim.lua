local modPath = '/mods/autojammer/'
local CommonUnits = import('/mods/common/units.lua')
local returnObject = {}

local Reclaim = {}
local ReclaimBySquare = {}
local reclaimLimit = {0,0,0,0}

local Decal = import('/lua/user/userdecal.lua').UserDecal

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
	local kstring = ''
	if type(k) == "table" then
		kstring = '{table}'
	else
		kstring = k
	end
	
    formatting = string.rep("  ", indent) .. kstring .. ": "
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

local filter = categories.TECH1 * categories.ENGINEER

function UpdateReclaim(syncTable)
    for id, data in syncTable do
		local position = data.position
		if not data.position then
			position = Reclaim[id].position
		end
		
		local x,y,z = unpack(position)
		local xP = math.floor(x / 10)
		local zP = math.floor(z / 10)
        if not data.mass then
			if (ReclaimBySquare[xP][zP]) then
				ReclaimBySquare[xP][zP].mass = ReclaimBySquare[xP][zP].mass - Reclaim[id].mass
				ReclaimBySquare[xP][zP].targets[id] = nil
				
				if (ReclaimBySquare[xP][zP].mass < 10) then
					ReclaimBySquare[xP][zP] = nil
					if (table.getn(ReclaimBySquare[xP]) == 0) then
						ReclaimBySquare[xP] = nil
					end
				end
			end
			
            Reclaim[id] = nil
        else
			if (not Reclaim[id]) then
				if (not ReclaimBySquare[xP]) then
					ReclaimBySquare[xP] = {}
				end
				
				if (not ReclaimBySquare[xP][zP]) then
					ReclaimBySquare[xP][zP] = {mass = 0, targets = {}}
				end
				
				ReclaimBySquare[xP][zP].mass = ReclaimBySquare[xP][zP].mass + data.mass
				ReclaimBySquare[xP][zP].targets[id] = data
			else
				-- something was reclaimed/destroyed here
				ReclaimBySquare[xP][zP].mass = ReclaimBySquare[xP][zP].mass - (Reclaim[id].mass - data.mass)
			end
			
			if (ReclaimBySquare[xP][zP].mass < 10) then
				ReclaimBySquare[xP][zP] = nil
				if (table.getn(ReclaimBySquare[xP]) == 0) then
					ReclaimBySquare[xP] = nil
				end
			end
		
			Reclaim[id] = data
        end
    end
end

local scanRangeStart = 1
local scanRangeEnd = 11
local scanRangeDiff = (scanRangeEnd - scanRangeStart) * 10

local Select = import('/mods/common/select.lua')

function InRange(ux, uz)
	return (math.abs(ux - reclaimLimit[1]) < scanRangeDiff + 10) and 
						(math.abs(uz - reclaimLimit[2]) < scanRangeDiff + 10) and 
						(math.abs(ux - reclaimLimit[3]) < scanRangeDiff + 10) and 
						(math.abs(uz - reclaimLimit[4]) < scanRangeDiff + 10)
end

	
function OnBeat(isDisable, lastdisabled)
	Select.Hidden(function()
        UISelectionByCategory('ENGINEER', false, false, false, true)
		--("", addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle)
		
		local idleUnits = GetSelectedUnits() or {}
		
		if (idleUnits) then
			for _, unit in idleUnits do 
				if (not unit:IsDead() and not unit:IsInCategory('COMMAND') and not unit:IsInCategory('SUBCOMMANDER')) then
					
					local ux,uy,uz = unpack(unit:GetPosition())
					
					if (InRange(ux, uz)) then
										
						local uxP = math.floor(ux / 10) - 6
						local uzP = math.floor(uz / 10) - 6
						
						local desiredxP = nil
						local desiredzP = nil
						
						--LOG("ReclaimBySquare")
						--tprint(ReclaimBySquare)
						
						local minRange = nil
						local square = nil
						
						--LOG('UNIT')
						--tprint(unit:GetPosition())
						
						for i = scanRangeStart, scanRangeEnd do
							for j = scanRangeStart, scanRangeEnd do
								local scanXp = uxP + i
								local scanZp = uzP + j
								local scanX = scanXp * 10
								local scanZ = scanZp * 10
								if (ReclaimBySquare[scanXp][scanZp] and InRange(scanX, scanZ)) then
									local minRangeCheck = VDist2Sq(scanXp * 10, scanZp*10, ux,uz)
									if ((not minRange) or (minRangeCheck < minRange)) then
										square = ReclaimBySquare[uxP + i][uzP + j]
										desiredxP = scanXp
										desiredzP = scanZp
										minRange = minRangeCheck
										--LOG(uxP .. "-" .. uzP .. "-" .. minRange)
									end
								end
							end
						end		
						
						if (desiredxP) then
							local unit_id = unit:GetEntityId()
							local rotation = math.atan(desiredxP/desiredzP)
							rotation = rotation * 180 / math.pi
							--local position = {desiredxP * 10 + 5.1, uy + 1.1, desiredzP * 10 + 5.1}
							--LOG("SQUARE")
							--tprint(square)
							local position = nil
							for _, target in pairs(square.targets) do
								position = target.position
							end
							
							--[[SimCallback( {
									Func = "GiveOrders",
									Args = { 
										unit_orders = {
											{
												["CommandType"] = "Move", 
												["Position"] = position
											},
										},
										unit_id     = unit:GetEntityId(),
										From = GetFocusArmy()
									}
								}, true)
							]]--
							
							--local cb = {Func="AttackMove", Args={Target=command.Target.Position, Rotation = rotation, Clear=command.Clear}}
							
							SelectUnits({unit})
							local cb = {Func = "AttackMove", Args = {["Target"] = position, ["unit_id"] = unit_id, ["ids"] = {unit_id}, Rotation = rotation, Clear = false, From = GetFocusArmy(), [2] = {unit_id}}}
							--tprint(cb)
							SimCallback( cb, true)
						end
					end
				end
			end
		end
    end)
end

local dragStart = nil
local Sdata = {}
function DragStart()
	dragStart = GetMouseWorldPos()
	createSquares()
end

function createSquares(texture)
	local prefix = '/mods/autoengies/textures/'
	if (Sdata[1]) then
		Sdata[1]:Destroy()
	end
	if (Sdata[3]) then
		Sdata[3]:Destroy()
	end
	if (Sdata[4]) then
		Sdata[4]:Destroy()
	end
	
	Sdata[1] = Decal(GetFrame(0))
	--Sdata[2] = Decal(GetFrame(0))
	Sdata[3] = Decal(GetFrame(0))
	Sdata[4] = Decal(GetFrame(0))
	--Sdata[1]:SetTexture(prefix .. "0-90.dds")
	--Sdata[2]:SetTexture(prefix .. "90-180.dds")
	--Sdata[3]:SetTexture(prefix .. "180-270.dds")
	--Sdata[4]:SetTexture(prefix .. "270-360.dds")
	Sdata[1]:SetTexture(prefix .. "0-90.dds")
	--Sdata[2]:SetTexture(prefix .. "square-2.dds")
	Sdata[3]:SetTexture(prefix .. "180-270.dds")
	Sdata[4]:SetTexture(prefix .. "square.dds")
end

function DragUpdate()	
	if (dragStart) then
		local mPos = GetMouseWorldPos()
		local x1 = dragStart[1]
		local x2 = mPos[1]
		local z1 = dragStart[3]
		local z2 = mPos[3]
		local radius1 = math.abs(x1 - x2)
		local radius2 = math.abs(z1 - z2)
		local scaleVect = {
			--{math.abs((x1 - x2)) * 2, 0, math.abs((z1 - z2)) * 2},
			{math.floor(2.03*(radius1 + 0) + 0), 0, math.floor(2.03*(radius2 + 0)) + 0},
			{(x1 - x2), 0, (z2 - z1)},
			{math.floor(2.03*(radius1 + 0) + 0), 0, math.floor(2.03*(radius2 + 0)) + 0},
			{(x2 - x1), 0, (z2 - z1)},
		}		
		
		--Sdata[2]:SetPosition(GetMouseWorldPos())
		--Sdata[3]:SetPosition(GetMouseWorldPos())	
		Sdata[1]:SetScale(scaleVect[1])
		--Sdata[2]:SetScale(scaleVect[2])
		Sdata[3]:SetScale(scaleVect[3])
		Sdata[1]:SetPosition(GetMouseWorldPos())
		
		
		if ((z2 > z1 and x2 > x1) or (z2 < z1 and x2 < x1)) then
			Sdata[1]:SetScale({0,0,0})
			Sdata[3]:SetScale({0,0,0})
			Sdata[4]:SetPosition(GetMouseWorldPos())
			Sdata[4]:SetScale(scaleVect[4])
		elseif (z2 < z1 and x2 > x1) then
			Sdata[1]:SetScale({0,0,0})
			Sdata[4]:SetScale({0,0,0})
						
			Sdata[3]:SetScale(scaleVect[3])
			Sdata[3]:SetPosition(GetMouseWorldPos())
		end
	end
end

function DragEnd()
	reclaimLimit[1] = dragStart[1]
	reclaimLimit[2] = dragStart[3]
	local mPos = GetMouseWorldPos()
	reclaimLimit[3]	= mPos[1]
	reclaimLimit[4]	= mPos[3]
	dragStart = nil
	--Sdata[1]:Destroy()
	--Sdata[2]:Destroy()
	--Sdata[3]:Destroy()
	--Sdata[4]:Destroy()
end