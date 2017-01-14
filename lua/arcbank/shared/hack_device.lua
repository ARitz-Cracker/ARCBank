-- hack_device.lua - Non-entity functions for the ATM hacking device.

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2017 Aritz Beobide-Cardinal All rights reserved.

ARCBank.HackTimeGetSetting = function(device,setting)
	if (!istable(_G[device.AddonTab].Settings)) then
		error(device.AddonTab..".Settings is not a table")
	end
	if (!istable(_G[device.AddonInherent].Settings)) then
		error(device.AddonInherent..".Settings is not a table")
	end
	return _G[device.AddonTab].Settings[device[setting]] || _G[device.AddonInherent].Settings[device[setting]]
end

ARCBank.HackTimeOffset = function(device,time)
	return math.Round(time^0.725)
end

ARCBank.HackTimeCalculate = function(device,money,stealth)
	if isstring(device) then
		for i=1,#ARCBank.HackableDevices do
			if ARCBank.HackableDevices[i].class == device then
				device = ARCBank.HackableDevices[i]
				break
			end
		end
	elseif !istable(device) then
		error("ARCBank.HackTimeCalculate bad argument #1 table or valid entity expected got "..type(device))
	end
	local relTimeMax = ARCBank.HackTimeGetSetting(device,"TimeMax") - ARCBank.HackTimeGetSetting(device,"TimeMin")
	return (ARCBank.HackTimeGetSetting(device,"TimeMin") + ARCLib.BetweenNumberScale(ARCBank.HackTimeGetSetting(device,"MoneyMin"),money,ARCBank.HackTimeGetSetting(device,"MoneyMax")) ^ ARCBank.HackTimeGetSetting(device,"TimeCurve") * relTimeMax)*(1+ARCLib.BoolToNumber(stealth)*ARCBank.HackTimeGetSetting(device,"TimeStealth"))
end
