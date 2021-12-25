local baseBeginSession = BeginSession
function BeginSession()
    baseBeginSession()
    ForkThread(function() 
		while true do
			LOG("TICK!")
			import('/mods/AutoJammer/modules/units.lua').Invoke()
			WaitTicks(100)
		end
	end)

end
