local GameMain = import('/lua/ui/game/gamemain.lua')
local DragModule = import('/mods/dragmove/modules/drag.lua')
local CommonUnits = import('/mods/common/units.lua')

local tick = 0
local ticklimit = 10 -- 10 ticks ~ 1 second

function Drag_OnBeat()	
	tick = tick + 1		
	if tick == ticklimit then
		DragModule.OnBeat()		
		tick = 0
	end
end

GameMain.AddBeatFunction(Drag_OnBeat)

local originalCreateUI = CreateUI
function CreateUI(isReplay)
	originalCreateUI(isReplay)
	local oldEvent = gameParent.HandleEvent
	gameParent.HandleEvent = function(self, event)
		-- Get the currently selected units, ignore ctrl-drag with NO seleected units, used in reclaim mod already to "paint" area
		local curSelection = GetSelectedUnits()
		
		if not curSelection then
			oldEvent(isReplay)
			return
		end
		

		if event.Type == 'ButtonPress' and event.Modifiers.Right and event.Modifiers.Ctrl then
			-- ignore for single units
			if (table.getn(curSelection) > 1) then
				DragModule.DragStart(table.getn(curSelection))
				return
			end
		elseif event.Type == 'ButtonRelease'  then
			if (table.getn(curSelection) > 1) then
				DragModule.DragEnd()
				return
			end
		end
		oldEvent(event)
	end
end