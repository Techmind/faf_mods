local CommonUnits = import('/mods/common/score.lua')

local GameMain = import('/lua/ui/game/gamemain.lua')
local flanking = import('/mods/flankmod/modules/flank.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimit = 11 -- 10 ticks ~ 1 second
local damagetrack = {[5] = true}
local damagetick = 0
local ticktimeout = 100

function FM_OnBeat()	
	tick = tick + 1	
	-- spider attscks too fast (1 second tracking is too slow)
	if damagetrack[tick] then
		local damaged = flanking.TrackDamage(tick)
		-- if damage tacken - track faster
		if (damaged) then
			ticklimit = 11
			damagetrack = {[3] = true, [5] = true, [7] = true}
			damagetick = tick
			ticktimeout = 100
		else			
			ticktimeout = ticktimeout - 1
			if (ticktimeout < 0) then
				ticklimit = 11
				damagetrack = {[5] = true}
				damagetick = 0
			end
			
		end		
	end
	
	-- giving move command every second is fine, units lag a bit each tiem they receive command, so we don't want them to be given rapidly
	if tick == ticklimit then
		--GameMain.RemoveBeatFunction(FM_OnBeat)
		flanking.TrackMovingTargets(damagetick, tick)
		--flanking.sendBaits()
		
		-- start next tracking iteration a bit faster
		tick = damagetick
		damagetick = 0 
	end
end

GameMain.AddBeatFunction(FM_OnBeat)