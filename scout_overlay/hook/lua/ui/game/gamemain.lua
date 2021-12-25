local GameMain = import('/lua/ui/game/gamemain.lua')
local code = import('/mods/scout_overlay/modules/code.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimit = 50 -- 10 ticks ~ 1 second
local inited = false

function SO_OnBeat()
	if (not inited) then
		code.init()
		inited = true
	end
	tick = tick + 1
	if tick == ticklimit then
		code.OnBeat(ticklimit / 10)
		tick = 0
	end
end

GameMain.AddBeatFunction(SO_OnBeat)