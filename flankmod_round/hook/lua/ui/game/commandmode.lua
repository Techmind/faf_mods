local flanking = import("/mods/flankmod_round/modules/flank.lua")

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

local lastCommand

local oldOnCommandIssued = OnCommandIssued
function OnCommandIssued(command)
	-- we are attacking something
	local target = command.Target;
	
	if (IsKeyDown('CONTROL') and (command.CommandType == 'Attack' or command.CommandType == 'FormAttack') and target.Type == 'Entity' and (target.EntityId > 0)) then
		flanking.ProcessAttackCommand(command)						
	else
		oldOnCommandIssued(command)
	end
	
	--oldOnCommandIssued(command)	
	lastCommand = command
end