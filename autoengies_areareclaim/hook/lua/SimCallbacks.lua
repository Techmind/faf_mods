Callbacks.AttackMove = function(data, units)
    if data.Clear then
        IssueClearCommands(units)
    end
    IssueAggressiveMove(units, data.Target)
end

function DoCallback(name, data, units)	
    local fn = Callbacks[name];
    if fn then
        fn(data, units)
    else
        error('No callback named ' .. repr(name))
    end
end