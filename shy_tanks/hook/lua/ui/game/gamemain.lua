local CommonUnits = import('/mods/common/score.lua')

local GameMain = import('/lua/ui/game/gamemain.lua')
local shy = import('/mods/shy_tanks/modules/shy.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimit = 11 -- 10 ticks ~ 1 second
local damagetrack = {[5] = true}

function SHY_OnBeat()	
	tick = tick + 1	
	
	if damagetrack[tick] then
		shy.TrackDamagedAndRetreat(tick)
		shy.TrackStoppedAndDodge(tick)
	end
	
	if tick == ticklimit then
		shy.AttackMove(damagetick, tick)
		tick = 0
	end
end

GameMain.AddBeatFunction(SHY_OnBeat)