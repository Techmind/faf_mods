function tprint (tbl, indent)
  if not indent then indent = 0 end
  if (tbl == nil) then
	LOG("nil")
	return
  end
  
  if (type(tbl) == "string") then
	LOG(tbl)
	return
  end
  
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

Callbacks.AttackMove = function(data, units)
	LOG('ATTACK_MOVE_LOG')
	LOG('DATA')
	tprint(data)
	LOG('UNITS')
	tprint(units)
	LOG('REST')
    if data.Clear then
        IssueClearCommands(units)
    end
    IssueAggressiveMove(units, data.Target)
end

function DoCallback(name, data, units)
	LOG('DoCallback, name')
	tprint(name)
	LOG('DoCallback, data')
	tprint(data)
	LOG('DoCallback, units')
	tprint(units)
	
    local fn = Callbacks[name];
    if fn then
        fn(data, units)
    else
        error('No callback named ' .. repr(name))
    end
end