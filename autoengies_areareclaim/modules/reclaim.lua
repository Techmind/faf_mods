local CommonUnits = import('/mods/common/units.lua')
local returnObject = {}

local Reclaim = {}
local ReclaimBySquare = {}
local reclaimLimit = {0,0,0,0}
local autoReclaimUnits = {}
autoReclaimUnitsTarget = {}
local autoReclaimUnitsCnt = 0

local Decal = import('/lua/user/userdecal.lua').UserDecal

local filter = categories.TECH1 * categories.ENGINEER

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

function UpdateReclaim(syncTable)
    for id, data in syncTable do
		local position = data.position
		if not data.position then
			if (Reclaim[id].position) then
				position = Reclaim[id].position
			else
				return
			end
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
				if (Reclaim[id] and data) then
					if (Reclaim[id].mass and data.mass) then
						ReclaimBySquare[xP][zP].mass = ReclaimBySquare[xP][zP].mass - (Reclaim[id].mass - data.mass)
					end
				end
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
local scanRangeDiff = (scanRangeEnd - scanRangeStart) * 10 / 4 

local Select = import('/mods/common/select.lua')

function InRange(ux, uz)
	return (math.abs(ux - reclaimLimit[1]) > 0) and 
						(math.abs(uz - reclaimLimit[2]) > 0) and 
						(math.abs(reclaimLimit[3] - ux) > 0) and 
						(math.abs(reclaimLimit[4] - uz) > 0)
end

local eco_types = {'MASS', 'ENERGY'}


function OnBeatCheckOverflow()
	local data = GetEconomyTotals()
	local overflow = data['stored']['MASS'] > (data['maxStorage']['MASS'] * 0.99)
	
	if (overflow and autoReclaimUnits and autoReclaimUnitsCnt > 0) then
		-- we don't want selection changing for command issuing to overwrite user's
		Select.Hidden(
			function()
				for unit_id, unit in autoReclaimUnits do
					if (not unit or unit:IsDead()) then
						autoReclaimUnits[unit_id] = nil
						autoReclaimUnitsTarget[unit_id] = nil
						autoReclaimUnitsCnt = autoReclaimUnitsCnt - 1
					end
					
					local cq = unit:GetCommandQueue()
					if (cq and table.getn(cq) > 0) then
						-- check if 1st command is attack-move (assume it's auto-reclaim)
						if cq[1].type == 'AggressiveMove' then
							local position = cq[1].position
							local unitTarget = autoReclaimUnitsTarget[unit_id]
							-- if actual target is same as original
							if (unitTarget and (position[1] == unitTarget[1])) then
								-- move it a bit from target (issuing attack-move under yourself gets cancelled by game)
								position[1] = position[1] + 3
								position[3] = position[3] + 3
								SelectUnits({unit})
								-- issue attack-move command so we stop recliming
								local cb = {Func = "AttackMove", Args = {["Target"] = position, ["unit_id"] = unit_id, ["ids"] = {unit_id}, Clear = true, From = GetFocusArmy(), [2] = {unit_id}}}
								SimCallback( cb, true)
							end
						else
							-- some other command - remove from watched units
							autoReclaimUnits[unit_id] = nil
							autoReclaimUnitsTarget[unit_id] = nil
							autoReclaimUnitsCnt = autoReclaimUnitsCnt - 1
						end
					end
				end
			end
		)
	end	
end
	
function OnBeat(isDisable, lastdisabled)
	if (reclaimLimit[1] == 0 and reclaimLimit[2] == 0 and reclaimLimit[3] == 0 and reclaimLimit[4] == 0) then
		return
	end

	Select.Hidden(function()
        UISelectionByCategory('ENGINEER TECH1', false, false, false, true)
		--("", addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle)
		
		local idleUnits = GetSelectedUnits() or {}
		
		if (idleUnits) then
			for _, unit in idleUnits do 
			
				--print("idles:" .. table.getn(idleUnits))
				
				if (not unit:IsDead() and not unit:IsInCategory('COMMAND') and not unit:IsInCategory('SUBCOMMANDER')) then
					
					local ux,uy,uz = unpack(unit:GetPosition())
									
					if (InRange(ux, uz)) then
										
						local uxP = math.floor(ux / 10) - 6
						local uzP = math.floor(uz / 10) - 6
						
						local desiredxP = nil
						local desiredzP = nil
												
						local minRange = nil
						local square = nil
												
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
							local position = nil
							for _, target in pairs(square.targets) do
								position = target.position
							end
							
													
							SelectUnits({unit})
							local cb = {Func = "AttackMove", Args = {["Target"] = position, ["unit_id"] = unit_id, ["ids"] = {unit_id}, Rotation = rotation, Clear = false, From = GetFocusArmy(), [2] = {unit_id}}}
							local res = SimCallback( cb, true)
							autoReclaimUnits[unit_id] = unit
							autoReclaimUnitsTarget[unit_id] = position
							autoReclaimUnitsCnt = autoReclaimUnitsCnt + 1
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
	local prefix = '/mods/autoengies_areareclaim/textures/'
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
	if (dragStart) then
		reclaimLimit[1] = dragStart[1]
		reclaimLimit[2] = dragStart[3]
		local mPos = GetMouseWorldPos()
		reclaimLimit[3]	= mPos[1]
		reclaimLimit[4]	= mPos[3]
		
		if (reclaimLimit[3] < reclaimLimit[1]) then
			reclaimLimit[3] = dragStart[1]
			reclaimLimit[1] = mPos[1]
		end
		
		if (reclaimLimit[4] < reclaimLimit[2]) then
			reclaimLimit[4] = dragStart[3]
			reclaimLimit[2] = mPos[3]
		end
		
		
		dragStart = nil
	end
	--Sdata[1]:Destroy()
	--Sdata[2]:Destroy()
	--Sdata[3]:Destroy()
	--Sdata[4]:Destroy()
end