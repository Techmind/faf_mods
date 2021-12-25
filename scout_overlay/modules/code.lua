local ScoutBySquare = {}
local squareSize = 40
-- seconds
local times = {30, 90, 240}
-- textures for scout times
local timesToDots = {
	[30] = 'green_dots.dds',
	[90] = 'orange_dots.dds',
	[240] = 'red_dots.dds'
}

local Decal = import('/lua/user/userdecal.lua').UserDecal

function tprint (tbl, indent)
  if not indent then indent = 0 end
  if (not (type(tbl) == 'table')) then
	  LOG(tbl)
	  return
  end
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
      LOG(formatting .. v)
    end
  end
end

function init()
	local sessionInfo    = SessionGetScenarioInfo()

	local size = {sessionInfo.size[1], sessionInfo.size[2]}
	--tprint("map_size:" .. size[1] .. ',' .. size[2])
	for i = 0, math.floor(size[1] / squareSize) do
		for j = 0, math.floor(size[2] / squareSize) do
			if (not ScoutBySquare[i]) then
				ScoutBySquare[i] = {}
			end
			ScoutBySquare[i][j] = 0
		end
	end
	--tprint(ScoutBySquare)
end

local Select = import('/mods/common/select.lua')

function OnBeat(ScanTimes)
	predictScoutCoverage(ScanTimes)
	createSquares()
end

function predictScoutCoverage(ScanTimes)
	Select.Hidden(function()
        UISelectionByCategory('SCOUT', false, false, false, false)
		--("", addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle)

		local selectedUnits = GetSelectedUnits() or {}

		if (selectedUnits) then
			for _, unit in selectedUnits do

				--print("idles:" .. table.getn(selectedUnits))
				if (not unit:IsDead()) then
					local ux,uy,uz = unpack(unit:GetPosition())

					local uBp = unit:GetBlueprint()
					local comQ = unit:GetCommandQueue()
					local currentCommand = comQ[0]

					local visionRadiusSquared = math.min(1, math.floor(uBp.Intel.VisionRadius / squareSize))

					local predictTimes = 1
					local xSpeed = 0
					local zSpeed = 0

					if (currentCommand and (currentCommand.type == 'Move' or currentCommand.type == 'Patrol')) then
						predictTimes =  math.floor(ScanTimes - 1)
						destination = currentCommand.position
						xDiff = destination[1] - ux
						zDiff = destination[3] - uz
						xDiff2 = xDiff * xDiff
						zDiff2 = zDiff * zDiff
						squareDiff = xDiff * xDiff + zDiff * zDiff
						xSpeed = math.sqrt(uBp.Physics.MaxSpeed * uBp.Physics.MaxSpeed / squareDiff * xDiff2)
						zSpeed = math.sqrt(uBp.Physics.MaxSpeed * uBp.Physics.MaxSpeed / squareDiff * zDiff2)
					end

					for i = 0, predictTimes do
						local predictedX = math.floor((ux + i * xSpeed) / squareSize)
						local predictedZ = math.floor((uz + i * zSpeed) / squareSize)
						for j = -visionRadiusSquared, visionRadiusSquared do
							if not ScoutBySquare[predictedX + j] then
								ScoutBySquare[predictedX + j] = {}
							end
							for k = -visionRadiusSquared, visionRadiusSquared do
								ScoutBySquare[predictedX + j][predictedZ + k] = GameTick()
							end
						end
					end
				end
			end
		end
    end)
end

local decalData = {}
local prefix = '/mods/scout_overlay/textures/'
local scaleVect = {squareSize, 0, squareSize}

local labelsData = {}

function createSquares()
	--print("SIZE" .. table.getn(ScoutBySquare))
	--tprint("SCOUTS SQUARE")
	--tprint(ScoutBySquare)
	for sX, row in ScoutBySquare do
		--tprint("sX" .. sX)
		--tprint("row")
		--tprint(row)
		for sZ, tick in row do
			local tickDiff = math.floor((GameTick() - tick) / 10)
			local path = nil

			for index, time in times do
				if (tickDiff >= time) then
					path = prefix .. timesToDots[time]
				end
			end
			--renderDecal(sX,sZ, tickDiff, path)
			markLabel(sX,sZ, tickDiff, path)
		end
	end

	renderLabels()
end

function markLabel(sX, sZ, tickDiff, path)
	if (not labelsData[sX]) then
		labelsData[sX] = {}
	end

	if (not labelsData[sX][sZ]) then
		labelsData[sX][sZ] = {tickDiff = tickDiff, path = path}
	else
		labelsData[sX][sZ].tickDiff =  tickDiff
		labelsData[sX][sZ].path =  path
	end
end

local LabelPool = {}
local labelIndex = 1

function renderLabels()
	local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera

	--tprint("LABELS DATA")
	--tprint(labelsData)

	if (view.ShowingReclaim and view.ReclaimGroup) then
		local reclaim = import('/lua/ui/game/reclaim.lua')
		local onScreenSquareIndex = 1
		local onScreenSquared = {}

		-- create all labels and mark those onScreen
		for sX, row in labelsData do
			for sZ, r in row do
				local position = {sX * squareSize, 25, sZ * squareSize}
				if (r.path) then
					if (not r.label) then
						-- last parameter in monitor pixels, need to change with zoom somehow =(
						r.label = reclaim.CreateScoutLabel(view.ReclaimGroup, r.path, squareSize)
						r.position = position
						r.labelIndex = labelIndex
						LabelPool[labelIndex] = r.label
						labelIndex = labelIndex + 1
					end

					r.onScreen = reclaim.OnScreen(view, position)
					if r.onScreen then
						onScreenSquared[onScreenSquareIndex] = r
						onScreenSquareIndex = onScreenSquareIndex + 1
						--tprint(r.position)
					else
						r.label:Hide()
					end

					labelsData[sX][sZ] = r
				else
					if (LabelPool[r.labelIndex]) then
						LabelPool[r.labelIndex]:Destroy()
						LabelPool[r.labelIndex] = nil
					end
					labelsData[sX][sZ].label = nil
				end
			end
		end

		for _, r in onScreenSquared do
			r.label:DisplayScouted(r)
		end
	end
end

-- :SetPosition is buggy and only workswith "GetMouseWorldPos"
function renderDecal(sX,sZ,tickDiff,path)
	if (not decalData[sX]) then
		decalData[sX] = {}
	end
	if (tickDiff < times[1]) then
		if (decalData[sX][sZ]) then
			decalData[sX][sZ]:Destroy()
			decalData[sX][sZ] = nil
		end
	else
		local created = false
		if (not decalData[sX][sZ]) then
			--tprint("CREATING DECAL")
			decalData[sX][sZ] = Decal(GetFrame(0))
			created = true
		end

		--tprint("CREATING DECAL SET TEXTURE")
		print(sX .. "," .. sZ .. ',' .. tickDiff .. ',' .. path)
		decalData[sX][sZ]:SetTexture(path)

		if (created) then
			--tprint("CREATING DECAL SET SCALE")
			decalData[sX][sZ]:SetScale(scaleVect)
			--tprint("CREATING DECAL SET POSITION")
			local posCopy = Vector(pos[1], pos[2], pos[3])
			--pos[1] = sX * squareSize
			--pos[3] = sZ * squareSize
			--tprint(pos)
			--tprint(posCopy)
			decalData[sX][sZ]:SetPosition(posCopy)
		end
	end
end