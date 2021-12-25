local GameMain = import('/lua/ui/game/gamemain.lua')
local units = import('/mods/autojammer/modules/units.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local enabled = true
local lastdisabled
local ticklimit = 50 -- 10 ticks ~ 1 second
local tickdisable = ticklimit - 1
local commcheckFlag = true

function AJ_OnBeat()	
	tick = tick + 1	
	if tick >= tickdisable and enabled then			
		units.OnBeat(tick == tickdisable, nil)
		if tick == ticklimit then
			-- disable code if UEF not available from start
			-- need to wait for game to start(
			--if (enabled and commcheckFlag) then
				--local commcheck = table.getn(CommonUnits.Get(categories.uel0001)) > 0 -- check uef com in game
			
				--if (not commcheck) then
--					GameMain.RemoveBeatFunction(AJ_OnBeat)
	--			end
				
				--commcheckFlag = false
			--end
			
			tick = 0
		end
	end
end

GameMain.AddBeatFunction(AJ_OnBeat)