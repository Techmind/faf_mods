local oldOnSync = OnSync

local reclaim = import('/mods/autoengies_areareclaim/modules/reclaim.lua')

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

function OnSync()
	if (Sync.Reclaim) then
		reclaim.UpdateReclaim(Sync.Reclaim)
		--LOG("UPDATE RECLAIM-2")
	end
	if (Sync.UnitData) then
	end
    oldOnSync()
end