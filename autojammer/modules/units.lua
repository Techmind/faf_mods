local modPath = '/mods/autojammer/'
local CommonUnits = import('/mods/common/units.lua')
local returnObject = {}

-- https://supcom.fandom.com/wiki/Radar_Jamming
local filter = categories.ues0103 -- t1 frigate
		+ categories.xel0209 -- t2 eng
		-- + categories.xra0305 -- Wailer/t3 gunship, but it was nerfed in FAF i guess (patch of ~2017) ?
		+ categories.RadarJammer -- just in case some sim mod uses it
		+ categories.uel0301 + categories.uel0301_IntelJammer -- subcoms
		
local units

function OnBeat(isDisable, lastdisabled)
	--LOG(categories)
	--for k,v in pairs(categories) do
--		LOG(k)
		--LOG(v)
    --end
	-- https://supcom.fandom.com/wiki/Radar_Jamming, 
	-- uef t1 frigate
	-- uef t2 field engineer
	-- cybran t3 air
	-- uef t3 commander
	-- DEBUG uel0301_IntelJammer
	--LOG("UNITS  LEN:")
	--LOG(table.getn(units))

	-- 2 - jamming
	-- disable jamming
		
	if (isDisable) then
		units = CommonUnits.Get(filter)
		
		--LOG("UNITS DISABLE LEN:")
		--LOG(table.getn(units))
		
		ToggleScriptBit(units, 2, false)
		return units
	else
		units = CommonUnits.Get(filter)
		lastdisabled = units -- no idea whay passing variable & return dont work(
		
		--LOG("UNITS ENABLE LEN:")
		--LOG(table.getn(lastdisabled))
	
		ToggleScriptBit(units, 2, true)
		return lastdisabled
	end
end


