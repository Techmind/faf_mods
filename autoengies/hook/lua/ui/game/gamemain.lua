local GameMain = import('/lua/ui/game/gamemain.lua')
local reclaim = import('/mods/autoengies/modules/reclaim.lua')
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
end

GameMain.AddBeatFunction(AE_OnBeat)

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      LOG(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      LOG(formatting .. tostring(v))      
    else
      LOG(formatting)
	  LOG(v)
    end
  end
end

local originalCreateUI = CreateUI
function CreateUI(isReplay)
	originalCreateUI(isReplay)
	import('/mods/Area Commands/areacommands.lua').Init()
	local oldEvent = gameParent.HandleEvent
	gameParent.HandleEvent = function(self, event)
		if event.Type == 'ButtonPress' and event.Modifiers.Right and event.Modifiers.Ctrl then
			reclaim.DragStart()
		elseif event.Type == 'ButtonRelease'  then
			reclaim.DragEnd()
		end
		oldEvent(event)
		--LOG("EVENT")
		--tprint(event)		
	end
end