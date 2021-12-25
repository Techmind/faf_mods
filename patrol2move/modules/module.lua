local trackedUnits = {}
local catCache = {}
local numrepeat = 20

function tLOG (tbl, indent)	
  if not indent then indent = 0 end
  formatting = string.rep("  ", indent)
  if type(tbl) == "nil" then
	LOG(formatting .. "nil")
	return
  end
  if type(tbl) == "string" then
	LOG(formatting .. tbl)
	return
  end
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

function convert()
	local units = GetSelectedUnits() or {}	
	
	for index, unit in units do
		local commands = {}
		local comQ = unit:GetCommandQueue()
		
		local patrolCommands = {}
		
	
		for _, command in comQ do
			if (command.type == 'Patrol') then
				-- convert to Move				
				table.insert(patrolCommands,{
					["CommandType"] = "Move", 
					["Position"] = command.position
				})
			else
				local target = command.Target or {["EntityId"] = 0}
				table.insert(command,{
					["CommandType"] = command.type, 
					["Position"] = command.position,
					["EntityId"] = target.EntityId
				})
			end
		end
		
		if (table.getn(patrolCommands) > 1) then
			local i = 1
			while (i < numrepeat) do
				for _,v in ipairs(patrolCommands) do 
					table.insert(commands, v)
				end
				i =  i + 1
			end
			
			SimCallback( {
				Func = "GiveOrders",
				Args = { 
					unit_orders = commands,
					unit_id     = unit:GetEntityId(),
					From = GetFocusArmy()
				}
			}, true)
		end
	end
end
