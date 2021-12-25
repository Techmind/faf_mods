local GameMain = import('/lua/ui/game/gamemain.lua')
local reclaim = import('/mods/autoengies_areareclaim/modules/reclaim.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimit = 50 -- 10 ticks ~ 1 second

function AE_OnBeat()	
	reclaim.DragUpdate()
	tick = tick + 1		
	if tick == ticklimit then
		reclaim.OnBeat()		
		tick = 0
	end
	-- every 1.5,3,4.5 seconds check if we need to stop reclaiming, cause overflow occured
	if ((tick == 45) or (tick == 30) or (tick == 15)) then
		reclaim.OnBeatCheckOverflow()
	end
end

GameMain.AddBeatFunction(AE_OnBeat)

local originalCreateUI_RECLAIM = CreateUI
function CreateUI(isReplay)
	originalCreateUI_RECLAIM(isReplay)
	local oldEvent = gameParent.HandleEvent
	gameParent.HandleEvent = function(self, event)
	
		local curSelection = GetSelectedUnits()
		
		if not curSelection then
			if event.Type == 'ButtonPress' and event.Modifiers.Right and event.Modifiers.Ctrl then
				reclaim.DragStart()
			elseif event.Type == 'ButtonRelease'  then
				reclaim.DragEnd()
			end			
		end
		
		oldEvent(self, event)
	end
end