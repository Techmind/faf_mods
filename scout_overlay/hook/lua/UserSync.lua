local oldOnSync = OnSync

local code = import('/mods/scout_overlay/modules/code.lua')

function OnSync()
	if (Sync.Reclaim) then
	end
	if (Sync.UnitData) then
	end
    oldOnSync()
end