local CommonUnits = import('/mods/common/score.lua')

local GameMain = import('/lua/ui/game/gamemain.lua')
local guardMod = import('/mods/betterguard/modules/guard.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimitBG = 20 -- 10 ticks ~ 1 second

function BG_OnBeat()	
	tick = tick + 1		
	-- giving move command every second is fine, units lag a bit each tiem they receive command, so we don't want them to be given rapidly
	if tick == ticklimitBG then
		guardMod.TrackTargets()
		
		tick = 0
	end
end

GameMain.AddBeatFunction(BG_OnBeat)