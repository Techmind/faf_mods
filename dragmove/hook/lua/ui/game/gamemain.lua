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

function tLOG (tbl, indent)	
  if not indent then indent = 0 end
  formatting = string.rep("  ", indent)
  if type(tbl) == "nil" then
	LOG(formatting .. "nil")
	return
  end
  --LOG(type(tbl))
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
	if type(v) == "nil" then
	  LOG(formatting .. "NIL")
    elseif type(v) == "table" then
      LOG(formatting)
      tLOG(v, indent+1)
    elseif type(v) == 'boolean' then
      LOG(formatting .. tostring(v))      
    else
      LOG(formatting)
	  LOG(v)
    end
  end
end

GameMain.AddBeatFunction(Drag_OnBeat)

local originalCreateUI_DRAG = CreateUI
function CreateUI(isReplay)
	originalCreateUI_DRAG(isReplay)
	local oldEvent = gameParent.HandleEvent
	gameParent.HandleEvent = function(self, event)
		-- Get the currently selected units, ignore ctrl-drag with NO seleected units, used in reclaim mod already to "paint" area
		local curSelection = GetSelectedUnits()
		
		if not curSelection then
			oldEvent(self, event)
			return
		end		
		
		--tLOG(event)
		--print("size.." .. table.getn(curSelection))

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
		oldEvent(self, event)
	end
end