-- hooks.lua - Hooks

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false

hook.Add( "CalcView", "ARCBank ATMCalcView",function( ply, pos, angles, fov ) --Good
	if ply.ARCBank_UsingATM && IsValid(ply.ARCBank_ATM) --[[&& LocalPlayer().ARCBank_ATM.WaitDelay < math.huge ]]&& ply.ARCBank_ATM.MoneyMsg == 0 && ply.ARCBank_FullScreen then
		local atm = ply.ARCBank_ATM
		local view = {}
		view.origin = ply.ARCBank_ATM:LocalToWorld(ply.ARCBank_ATM.ATMType.FullScreen)
		view.angles = ply.ARCBank_ATM:LocalToWorldAngles(ply.ARCBank_ATM.ATMType.FullScreenAng)
		view.fov = fov
		if atm.ATMType.UseTouchScreen then
			local pos = util.IntersectRayWithPlane( view.origin, gui.ScreenToVector( gui.MousePos() ), atm:LocalToWorld(atm.ATMType.Screen), atm:LocalToWorldAngles(atm.ATMType.ScreenAng):Up() ) 
			if pos then
				pos = WorldToLocal( pos, atm:LocalToWorldAngles(atm.ATMType.ScreenAng), atm:LocalToWorld(atm.ATMType.Screen), atm:LocalToWorldAngles(atm.ATMType.ScreenAng) ) 
				atm.TouchScreenX = math.Round(pos.x/atm.ATMType.ScreenSize)
				atm.TouchScreenY = math.Round(pos.y/-atm.ATMType.ScreenSize)
			end
		end
		return view
	end
end)
hook.Add( "CalcViewModelView", "ARCBank ATMCalcViewModel",function( wep, vm, oldpos, oldang, pos, ang ) --Good
	local ply = LocalPlayer()
	if ply.ARCBank_UsingATM && IsValid(ply.ARCBank_ATM) --[[&& LocalPlayer().ARCBank_ATM.WaitDelay < math.huge ]]&& ply.ARCBank_ATM.MoneyMsg == 0 && ply.ARCBank_FullScreen then
		return Vector(0,0,1337),ang
	end
end)