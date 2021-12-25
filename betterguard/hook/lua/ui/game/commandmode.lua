local guardMod = import("/mods/betterguard/modules/guard.lua")

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

local ONCE = false

local oldOnCommandIssued = OnCommandIssued
function OnCommandIssued(command)
	local target = command.Target;
	
	local units = GetSelectedUnits() or {}
	local unit = units[1]
	
	--local cmd = {["Clear"] = true, ["CommandType"] = 'BuildMobile', ["Target"] = {["Type"] = 'Position', ["Position"] = {7.5,21.078125,56.5}},["Blueprint"] = 'urb1103', ["Units"] = {unit}}
	--local cmd2 = {["Target"] = {["Type"] = 'Position', ["Position"] = {7.5,21.078125,56.5}},["Blueprint"] = 'urb1103'}
	--local location = {7.5,21.078125,56.5}
	--local blueprint = 'urb1103'
	--oldOnCommandIssued(cmd)
	--IssueBuildMobile({unit}, {7.5,21.078125,56.5},   'urb1103', {})	
	--if (not ONCE) then
		--ONCE = true
--		IssueUnitCommand({unit}, "UNITCOMMAND_BuildMobile", cmd2, false)		
	--end
	
	if (IsKeyDown('CONTROL') and (command.CommandType == 'Guard') and target.Type == 'Entity' and (target.EntityId > 0)) then
		--LOG("PG - 1")
		-- if engi selected - do not do anything
		if (guardMod.ProcessGuardCommand(command)) then
			oldOnCommandIssued(command)
		end
	else
		oldOnCommandIssued(command)
	end
	
	lastCommand = command
end