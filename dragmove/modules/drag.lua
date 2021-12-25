local Decal = import('/lua/user/userdecal.lua').UserDecal
local isDragging = false
local dragTable = {}
local length = 0
local movementsTable = {}
local count = 0

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

function calcMoveBlips()
	local size = table.getn(dragTable);
	
	local spread = length / (count + 1);
	local remainSpread = spread;
	
	--print("spread" .. spread .. "length" .. length .. "count" .. count);
	
	local i = 2;
	
	if (not dragTable[i]) then
		--print("small drag table");
		return
	end
	
	movementsTable = {}

	local segLen = dragTable[i][2];
	local startX = dragTable[i - 1][1][1];
	local y = dragTable[i - 1][1][2];
	local startZ = dragTable[i - 1][1][3];
	local dx = dragTable[i][1][1] - startX;
	local dz = dragTable[i][1][3] - startZ;
	
	--LOG("CALC")
	
	while (i <= size) do		
		--LOG("i"..i.."startX" .. startX .. "startZ" .. startZ .. "dx" .. dx .. "dz" .. dz .. "segLen" .. segLen .. "remainSpread" .. remainSpread)
		if (segLen >= remainSpread) then
			local locationPct = remainSpread / segLen;						
			-- move segment start Point
			startX = startX + dx * locationPct;
			startZ = startZ + dz * locationPct;
			
			-- change segment size
			dx = dragTable[i][1][1] - startX;
			dz = dragTable[i][1][3] - startZ;
			-- change remaining length
			segLen = math.sqrt(dx*dx + dz*dz);

			-- TODO check how hills work (make y in the air by default?)
			-- add movement point
			table.insert(movementsTable, {startX, y, startZ});			

			remainSpread = spread;			
			--LOG("CHANGE-1:locationPct"..locationPct.."startX" .. startX .. "startZ" .. startZ .. "dx" .. dx .. "dz" .. dz .. "segLen" .. segLen .. "remainSpread" .. remainSpread)
		else
			-- move to next line segment
			remainSpread = remainSpread - segLen;			
			i = i + 1;
			if (i <= size) then
				segLen = dragTable[i][1][2];
				startX = dragTable[i - 1][1][1];
				y = dragTable[i - 1][1][2];
				startZ = dragTable[i - 1][1][3];
				dx = dragTable[i][1][1] - dragTable[i - 1][1][1];
				dz = dragTable[i][1][3] - dragTable[i - 1][1][3];
			end
			--LOG("CHANGE-2:i"..i.."startX" .. startX .. "startZ" .. startZ .. "dx" .. dx .. "dz" .. dz .. "segLen" .. segLen .. "remainSpread" .. remainSpread)
		end			
	end	
	
	--print("mtSize " .. table.getn(movementsTable) .. "dtSize" .. table.getn(dragTable))
end

function drawDragBlips()
	  for k, pos in pairs(dragTable) do
		AddCommandFeedbackBlip(
			{
				Position = pos[1],
				MeshName = '/meshes/game/crosshair02d_lod0.scm',
				TextureName = '/meshes/game/crosshair02d_albedo.dds',
				ShaderName = 'CommandFeedback2',
				UniformScale = 0.5,
			}, 
			0.75
		)
	  end
end

function drawMoveBlips()
	local last = table.getn(movementsTable)
	  for k, pos in pairs(movementsTable) do
		-- last one is to spread units from edges, don't draw it
		if (k != last) then
			AddCommandFeedbackBlip(
				{
					Position = pos,
					MeshName = '/meshes/game/flag02d_lod0.scm',
					TextureName = '/meshes/game/flag02d_albedo.dds',
					ShaderName = 'CommandFeedback',
					UniformScale = 0.5,
				}, 
				0.7
			)
		end
	  end
end

function moveUnits()
	for k, unit in pairs(GetSelectedUnits()) do	
		SimCallback( {
					Func = "GiveOrders",
					Args = { 
						unit_orders = {{
									["CommandType"] = "Move", 
									["Position"] = {movementsTable[k][1], movementsTable[k][2], movementsTable[k][3]}
								}},
						unit_id     = unit:GetEntityId(),
						From = GetFocusArmy()
					}
				}, true)

	end
end

function savePos(force)
	if (not isDragging) then
		return
	end
	
	--print("drag beat")
	
	local pos = GetMouseWorldPos();
	local len = table.getn(dragTable);	
		
	local dx = dragTable[len][1][1] - pos[1];
	local dz = dragTable[len][1][3] - pos[3];
	local segment = math.sqrt(dx*dx + dz*dz)	
	
	-- save position to points table, DO NOT SAVE empty segment unless it's last one
	if (force or segment > 0) then
		table.insert(dragTable, {pos, segment});
		
		length = length + segment;
	end
	
	-- draw current points somehow for debug
end

function OnBeat()
	if (not isDragging) then
		return
	end
	savePos(false)
	
	-- draw movement points
	calcMoveBlips()
	drawMoveBlips()
	drawDragBlips()
end

function DragStart(countIn)
	--print("drag start")
	isDragging = true;
	dragTable = {};
	movementsTable = {};
	count = countIn;
	length = 0;
	table.insert(dragTable, {GetMouseWorldPos(), 0});
	
	-- draw a command blip on current position
end

function DragEnd()
	if (isDragging) then
		savePos(true);
		
		--print("drag end")
		
		-- issue commands using simcallback
		calcMoveBlips();
		
		--tLOG(dragTable);
		--tLOG(movementsTable);
		
		moveUnits();
		isDragging = false
	end
end