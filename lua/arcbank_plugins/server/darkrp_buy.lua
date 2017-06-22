-- darkrp_buy.lua - Allows you to pay for shipments and stuff using your ARCBank account

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2017 Aritz Beobide-Cardinal All rights reserved.

util.AddNetworkString( "arcbank_buyshit" )
local hooks = {
	"canBuyCustomEntity",
	"canBuyShipment",
	"canBuyAmmo",
	"canBuyPistol"
}
local commandParts = {
	"",
	"buyshipment",
	"buyammo",
	"buy"
}

local commands = {
	"darkrp ",
	"darkrp buyshipment ",
	"darkrp buyammo ",
	"darkrp buy "
}
local cmd = {
	"cmd",
	"name",
	"ammoType",
	"name"
}
local itemPrices = {
	{},
	{},
	{},
	{}
}
local function clearCooldownCommand(ply,i,itemcmd) -- Using Internal SHIT here.
	local cmd
	if (i==1) then
		cmd = itemcmd
	else
		cmd = commandParts[i]
	end
	ply.DrpCommandDelays[cmd] = 0
end

for i=1,4 do
	hook.Add(hooks[i],"ARCBank PayWithAccount",function(ply,item)
		if not ARCBank.Settings.darkrp_f4_menu then return end
		if not ply._ARCBank_F4Error then
			ply._ARCBank_F4Error = {{},{},{},{}}
		end
		
		local itemcmd = item[cmd[i]]
		local errcode = ply._ARCBank_F4Error[i][itemcmd]
		if (errcode == nil) then
			itemPrices[i][itemcmd] = item.price
			net.Start("arcbank_buyshit")
			net.WriteUInt(i-1,2) --MICRO OPTIMIZATRION!!!
			net.WriteString(itemcmd)
			net.Send(ply)
			return false,true,"ARCBank confirmation"
		elseif (errcode == ARCBANK_ERROR_DOWNLOADING) then
			return false,false,ARCBANK_ERRORSTRINGS[ARCBANK_ERROR_BUSY]
		elseif (errcode == ARCBANK_ERROR_UNDERLING) then
			ply._ARCBank_F4Error[i][itemcmd] = nil
			return -- Use wallet
		elseif (errcode == ARCBANK_ERROR_NONE) then
			ply._ARCBank_F4Error[i][itemcmd] = nil
			return true,nil,nil,0 -- Player already paid with ARCBank account, no need to charge them again
		else
			return false,false,ARCBank.Settings.name..": "..ARCBANK_ERRORSTRINGS[errcode]
		end
	end)
end

net.Receive("arcbank_buyshit",function(len,ply)
	local i = net.ReadUInt(2)+1
	local account = net.ReadString()
	local itemcmd = net.ReadString()
	if not ply._ARCBank_F4Error then return end -- This could not be possible without getting the notification first.
	if account == "_" then -- This will always be an invalid ARCBank account
		ply._ARCBank_F4Error[i][itemcmd] = ARCBANK_ERROR_UNDERLING --ARCBank.AddMoney will never throw this error, but you are an UNDERLING for not using ARCBank :^)
		print(commands[i]..itemcmd)
		timer.Simple(0.1,function()
			clearCooldownCommand(ply,i,itemcmd)
			ply:ConCommand(commands[i]..itemcmd)
			
		end)
		
		return
	end
	if not itemPrices[i][itemcmd] then return end
	ply._ARCBank_F4Error[i][itemcmd] = ARCBANK_ERROR_DOWNLOADING
	ARCBank.AddMoney(ply, account, -itemPrices[i][itemcmd], ARCBANK_TRANSACTION_TRANSFER, "F4 Menu: "..itemcmd, function(errorcode)
		if not IsValid(ply) then return end -- They lost money I guess ¯\_(ツ)_/¯
		ply._ARCBank_F4Error[i][itemcmd] = errorcode
		clearCooldownCommand(ply,i,itemcmd)
		ply:ConCommand(commands[i]..itemcmd)
	end)
	itemPrices[i][itemcmd] = nil
end)
