local oldOnSync = OnSync

local reclaim = import('/mods/autoengies/modules/reclaim.lua')

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

-- Here's an opportunity for user side script to examine the Sync table for the new tick
function OnSync()
	if (Sync.Reclaim) then
		reclaim.UpdateReclaim(Sync.Reclaim)
	end
	if (Sync.UnitData) then
	end
    oldOnSync()
end