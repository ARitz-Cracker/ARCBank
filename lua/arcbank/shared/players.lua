-- hooks.lua - Player utilities

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2016 Aritz Beobide-Cardinal All rights reserved.

ARCBank.PlayerIDPrefix = "STEAM_"
if (nut) then
	ARCBank.PlayerIDPrefix = "NUT_"
end

function ARCBank.GetPlayerID(plyy)
	if (plyy._ARCBankID) then
		return plyy._ARCBankID
	end
	if (nut) then
		return "NUT_"..plyy:getChar():getID()
	else
		return plyy:SteamID()
	end
end

function ARCLib.GetPlayerByID(id) -- Gets a player by their SteamID
	local ply = {}
	if !isstring(id) then return NULL end
	for _, v in pairs( player.GetHumans() ) do
		if ARCBank.GetPlayerID(v) == id then
			ply = v
		end
	end
	if !IsValid(ply) then
		ply._ARCBankID = id
		function ply:Nick() return "[Player Offline]" end
		function ply:IsPlayer() return false end
		function ply:IsValid() return false end
	end
	return ply
end

