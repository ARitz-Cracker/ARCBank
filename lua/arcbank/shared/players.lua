-- hooks.lua - Player utilities

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2016 Aritz Beobide-Cardinal All rights reserved.

ARCBank.PlayerIDPrefix = "STEAM_"
if (nut) then
	ARCBank.PlayerIDPrefix = "NUT_"
end

ARCBank.GetCustomPlayerID = false

function ARCBank.GetPlayerID(plyy)
	if (plyy._ARCBankID) then
		return plyy._ARCBankID
	end
	if (type(ARCBank.GetCustomPlayerID) == "function") then
		return ARCBank.GetCustomPlayerID(ply)
	elseif (nut) then
		return ARCBank.PlayerIDPrefix..plyy:getChar():getID()
	else
		return plyy:SteamID()
	end
end

function ARCBank.GetPlayerByID(id)
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

function ARCBank.PlayerAddMoney(ply,amount)
	if (nut) then
		if amount > 0 then
			ply:getChar():giveMoney(amount)
		else
			amount = amount * -1
			ply:getChar():takeMoney(amount)
		end
	elseif string.lower(GAMEMODE.Name) == "gmod day-z" then
		if amount > 0 then
			ply:GiveItem("item_money", amount)
		else
			amount = amount * -1
			ply:TakeItem("item_money", amount)
		end
	elseif string.lower(GAMEMODE.Name) == "underdone - rpg" then
		if amount > 0 then
			ply:AddItem("money", amount)
		else
			amount = amount * -1
			ply:RemoveItem("money", amount)
		end
	elseif ply.addMoney then -- DarkRP 2.5+
		ply:addMoney(amount)
	elseif ply.AddMoney then -- DarkRP 2.4
		ply:AddMoney(amount)
	else
		ply:SendLua("notification.AddLegacy( \"I'm going to pretend that your wallet is unlimited because this is an unsupported gamemode.\", 0, 5 )")
	end
end
	
function ARCBank.PlayerCanAfford(ply,amount)
	if (nut) then
		return ply:getChar():getMoney() >= amount
	elseif string.lower(GAMEMODE.Name) == "gmod day-z" then
		return ply:HasItemAmount("item_money", amount)
	elseif string.lower(GAMEMODE.Name) == "underdone - rpg" then
		return ply:HasItem("money", amount)
	elseif ply.canAfford then -- DarkRP 2.5+
		return ply:canAfford(amount)
	elseif ply.CanAfford then -- DarkRP 2.4
		return ply:CanAfford(amount)
	else
		return false
	end
end

function ARCBank.PlayerGetMoney(ply)
	if (nut) then
		return ply:getChar():getMoney()
	elseif string.lower(GAMEMODE.Name) == "gmod day-z" then
		return ply:GetItem("item_money")
	elseif string.lower(GAMEMODE.Name) == "underdone - rpg" then
		return ply:GetMoney()
	elseif ply.canAfford then -- DarkRP 2.5+
		return ply:getDarkRPVar("money")
	elseif ply.CanAfford then -- DarkRP 2.4
		return ply.DarkRPVars["money"]
	else
		return 0
	end
end
