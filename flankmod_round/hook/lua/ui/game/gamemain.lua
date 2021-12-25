local CommonUnits = import('/mods/common/score.lua')

local GameMain = import('/lua/ui/game/gamemain.lua')
local flanking = import('/mods/flankmod_round/modules/flank.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimit = 10 -- 10 ticks ~ 1 second

function FM_OnBeat()	
	tick = tick + 1	
	-- spider attscks too fast (1 second tracking is too slow)
	if tick == ticklimit / 2 then
		flanking.TrackDamage()
	end
	
	-- giving move command every second is fine, units lag a bit each tiem they receive command, so we don't want them to be given rapidly
	if tick == ticklimit then
		--GameMain.RemoveBeatFunction(FM_OnBeat)
		flanking.TrackMovingTargets()
		--flanking.sendBaits()
		
		tick = 0
	end
end

GameMain.AddBeatFunction(FM_OnBeat)