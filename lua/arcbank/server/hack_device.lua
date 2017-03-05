-- hack_device.lua - Non-entity functions for the ATM hacking device.

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016-2017 Aritz Beobide-Cardinal All rights reserved.

util.AddNetworkString( "arcbank_add_hacking_device" )

local HACKDEV = {}
HACKDEV.Name = "A hackable device"
HACKDEV.Class = "sent_arc_atm"
HACKDEV.Side = false -- "x", "y", or "z" or "-x","+x", etc.
HACKDEV.AddonTab = "ARCBank"
HACKDEV.AddonInherent = "ARCBank"

HACKDEV.MoneyMax = "atm_hack_max"
HACKDEV.MoneyMin = "atm_hack_min"

HACKDEV.TimeMax = "atm_hack_time_max"
HACKDEV.TimeMin = "atm_hack_time_min"
HACKDEV.TimeCurve = "atm_hack_time_curve"
HACKDEV.TimeStealth = "atm_hack_time_stealth_rate"

ARCBank.HackableDevices = {}


--[[
ARCBank.NewHackableDevice = function()
	local tab = table.FullCopy(HACKDEV)
	return tab
end
]]

hook.Add( "PlayerInitialSpawn", "ARCBank AddHackingDevice", function(ply)
	for i=1,#ARCBank.HackableDevices do
		net.Start("arcbank_add_hacking_device")
		net.WriteTable(ARCBank.HackableDevices[i])
		net.Send(ply)
	end
end)

ARCBank.RegisterHackableDevice = function(obj)
	assert(#ARCBank.HackableDevices<255,"There can only be 255 hackable devices")
	ARCLib.TableMergeOptimized( table.FullCopy(HACKDEV) , obj )
	ARCBank.HackableDevices[#ARCBank.HackableDevices + 1] = obj
	obj._i = #ARCBank.HackableDevices
	if (obj._i > 255) then
		error("There can only be up to 255 hackable devices.")
	end
	net.Start("arcbank_add_hacking_device")
	net.WriteTable(obj)
	net.Broadcast()
	
end

--Kinda useless if the ATMs are unhackable :)
local ATM = {}
ATM.Side = "y"
ATM.Name = "ARCBank ATM"
ATM.Class = "sent_arc_atm"

ARCBank.RegisterHackableDevice(ATM)
