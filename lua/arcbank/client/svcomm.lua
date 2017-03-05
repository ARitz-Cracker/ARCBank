-- svcomm.lua - Client/Server communications for ARCBank
-- This file is under copyright, and is bound to the agreement stated in the ELUA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

local ARCBank_PingBusy = false
local ARCBank_PingCallBack = {}
local ARCBank_PingCount = 1
function ARCBank.GetStatus(callback)
	if ARCBank_PingCallBack[1] then
		ARCBank_PingCount = ARCBank_PingCount + 1
		ARCBank_PingCallBack[ARCBank_PingCount] = callback
	else
		net.Start("arcbank_comm_check")
		net.SendToServer()
		ARCBank_PingCallBack[1] = callback
	end
end


net.Receive( "arcbank_comm_check", function(length)
	local ready = tobool(net.ReadBit())
	local outdated = tobool(net.ReadBit())
	for k,v in pairs(ARCBank_PingCallBack) do
		v(ready)
	end
	ARCBank.Loaded = ready
	ARCBank.Outdated = outdated
	ARCBank_PingCallBack = {}
end)


-- Account Properties
local ARCBank_AccountProp_Args = {}
local ARCBank_AccountProp_Place = -1
function ARCBank.CanAccessAccount(ent,account,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.GetAccountProperties: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.GetAccountProperties: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.GetAccountProperties: Argument #3 is not a function")
	ARCBank_AccountProp_Args[#ARCBank_AccountProp_Args + 1] = {ent,account,callback}
	if ARCBank_AccountProp_Place == -1 then
		net.Start("arcbank_comm_get_account_properties")
		net.WriteEntity(ARCBank_AccountProp_Args[1][1])
		net.WriteString(ARCBank_AccountProp_Args[1][2])
		net.SendToServer()
		ARCBank_AccountProp_Place = 1
	end
end
ARCBank.GetAccountProperties = ARCBank.CanAccessAccount
net.Receive( "arcbank_comm_get_account_properties", function(length)
	local account = {}
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	if errcode == ARCBANK_ERROR_NONE then
		account.account = net.ReadString()
		account.name = net.ReadString()
		account.owner = net.ReadString()
		account.rank = net.ReadUInt(ARCBANK_ACCOUNTBITRATE)
	end
	
	local ent = ARCBank_AccountProp_Args[ARCBank_AccountProp_Place][1]
	local callback = ARCBank_AccountProp_Args[ARCBank_AccountProp_Place][3]
	timer.Simple(0.00001,function() callback(errcode,account,ent) end)
	ARCBank_AccountProp_Place = ARCBank_AccountProp_Place + 1
	if istable(ARCBank_AccountProp_Args[ARCBank_AccountProp_Place]) then
		net.Start("arcbank_comm_get_account_properties")
		net.WriteEntity(ARCBank_AccountProp_Args[ARCBank_AccountProp_Place][1])
		net.WriteString(ARCBank_AccountProp_Args[ARCBank_AccountProp_Place][2])
		net.SendToServer()
	else
		ARCBank_AccountProp_Args = {}
		ARCBank_AccountProp_Place = -1
	end
end)


-- Account Balance
local ARCBank_AccountBal_Args = {}
local ARCBank_AccountBal_Place = -1
function ARCBank.GetBalance(ent,account,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.GetBalance: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.GetBalance: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.GetBalance: Argument #3 is not a function")
	ARCBank_AccountBal_Args[#ARCBank_AccountBal_Args + 1] = {ent,account,callback}
	if ARCBank_AccountBal_Place == -1 then
		net.Start("arcbank_comm_get_account_balance")
		net.WriteEntity(ARCBank_AccountBal_Args[1][1])
		net.WriteString(ARCBank_AccountBal_Args[1][2])
		net.SendToServer()
		ARCBank_AccountBal_Place = 1
	end
end

net.Receive( "arcbank_comm_get_account_balance", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	local amount = net.ReadDouble()
	local ent = ARCBank_AccountBal_Args[ARCBank_AccountBal_Place][1]
	local callback = ARCBank_AccountBal_Args[ARCBank_AccountBal_Place][3]
	timer.Simple(0.00001,function() callback(errcode,amount,ent) end)
	ARCBank_AccountBal_Place = ARCBank_AccountBal_Place + 1
	if istable(ARCBank_AccountBal_Args[ARCBank_AccountBal_Place]) then
		net.Start("arcbank_comm_get_account_balance")
		net.WriteEntity(ARCBank_AccountBal_Args[ARCBank_AccountBal_Place][1])
		net.WriteString(ARCBank_AccountBal_Args[ARCBank_AccountBal_Place][2])
		net.SendToServer()
	else
		ARCBank_AccountBal_Args = {}
		ARCBank_AccountBal_Place = -1
	end
end)


-- Group Members
local ARCBank_AccountMem_Args = {}
local ARCBank_AccountMem_Place = -1
function ARCBank.GroupGetPlayers(ent,account,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.GroupGetPlayers: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.GroupGetPlayers: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.GroupGetPlayers: Argument #3 is not a function")
	ARCBank_AccountMem_Args[#ARCBank_AccountMem_Args + 1] = {ent,account,callback}
	if ARCBank_AccountMem_Place == -1 then
		net.Start("arcbank_comm_get_group_members")
		net.WriteEntity(ARCBank_AccountMem_Args[1][1])
		net.WriteString(ARCBank_AccountMem_Args[1][2])
		net.SendToServer()
		ARCBank_AccountMem_Place = 1
	end
end

net.Receive( "arcbank_comm_get_group_members", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	local tab = {}
	
	if errcode == ARCBANK_ERROR_NONE then
		local len = net.ReadUInt(32)
		for i=1,len do
			tab[i] = net.ReadString()
		end
	end
	
	local ent = ARCBank_AccountMem_Args[ARCBank_AccountMem_Place][1]
	local callback = ARCBank_AccountMem_Args[ARCBank_AccountMem_Place][3]
	timer.Simple(0.00001,function() callback(errcode,tab,ent) end)
	ARCBank_AccountMem_Place = ARCBank_AccountMem_Place + 1
	if istable(ARCBank_AccountMem_Args[ARCBank_AccountMem_Place]) then
		net.Start("arcbank_comm_get_group_members")
		net.WriteEntity(ARCBank_AccountMem_Args[ARCBank_AccountMem_Place][1])
		net.WriteString(ARCBank_AccountMem_Args[ARCBank_AccountMem_Place][2])
		net.SendToServer()
	else
		ARCBank_AccountMem_Args = {}
		ARCBank_AccountMem_Place = -1
	end
end)

-- Transfer
local ARCBank_AccountTrans_Args = {}
local ARCBank_AccountTrans_Place = -1
function ARCBank.Transfer(ent,plyto,accountfrom,accountto,amount,comment,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.Transfer: Argument #1 is not a valid entity")
	assert(isstring(plyto) or (IsValid(plyto) and plyto:IsPlayer()),"ARCBank.Transfer: Argument #2 is not a string or player")
	assert(isstring(accountfrom),"ARCBank.Transfer: Argument #3 is not a string")
	assert(isstring(accountto),"ARCBank.Transfer: Argument #4 is not a string")
	assert(isnumber(amount),"ARCBank.Transfer: Argument #5 is not a number")
	assert(isstring(comment),"ARCBank.Transfer: Argument #6 is not a string")
	assert(isfunction(callback),"ARCBank.Transfer: Argument #7 is not a function")
	ARCBank_AccountTrans_Args[#ARCBank_AccountTrans_Args + 1] = {ent,plyto,accountfrom,accountto,amount,comment,callback}
	if ARCBank_AccountTrans_Place == -1 then
		net.Start("arcbank_comm_transfer")
		net.WriteEntity(ARCBank_AccountTrans_Args[1][1])
		local usePlyEnt = isentity(ARCBank_AccountTrans_Args[1][2])
		net.WriteBool(usePlyEnt)
		if usePlyEnt then
			net.WriteEntity(ARCBank_AccountTrans_Args[1][2])
		else
			net.WriteString(ARCBank_AccountTrans_Args[1][2])
		end
		net.WriteString(ARCBank_AccountTrans_Args[1][3])
		net.WriteString(ARCBank_AccountTrans_Args[1][4])
		net.WriteUInt(ARCBank_AccountTrans_Args[1][5],32)
		net.WriteString(ARCBank_AccountTrans_Args[1][6])
		net.SendToServer()
		ARCBank_AccountTrans_Place = 1
	end
end

net.Receive( "arcbank_comm_transfer", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Place][1]
	local callback = ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Place][7]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountTrans_Place = ARCBank_AccountTrans_Place + 1
	if istable(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Place]) then
		net.Start("arcbank_comm_transfer")
		net.WriteEntity(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][1])
		local usePlyEnt = isentity(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][2])
		net.WriteBool(usePlyEnt)
		if usePlyEnt then
			net.WriteEntity(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][2])
		else
			net.WriteString(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][2])
		end
		net.WriteString(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][3])
		net.WriteString(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][4])
		net.WriteUInt(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][5],32)
		net.WriteString(ARCBank_AccountTrans_Args[ARCBank_AccountTrans_Args][6])
		net.SendToServer()
	else
		ARCBank_AccountTrans_Args = {}
		ARCBank_AccountTrans_Place = -1
	end
end)

-- Get Log
local ARCBank_AccountLog_Args = {}
local ARCBank_AccountLog_ArgsSort = {}
local ARCBank_AccountLog_Place = -1
local ARCBank_AccountLog_PlaceSort = -1
function ARCBank.GetLog(ent,account,timestamp,transaction_type,callback,rawsearch)
	assert(isentity(ent) and IsValid(ent),"ARCBank.GetLog: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.GetLog: Argument #2 is not a string")
	assert(isnumber(timestamp),"ARCBank.GetLog: Argument #3 is not a number")
	assert(isnumber(transaction_type),"ARCBank.GetLog: Argument #4 is not a number")
	assert(isfunction(callback),"ARCBank.GetLog: Argument #5 is not a function")
	ARCBank_AccountLog_Args[#ARCBank_AccountLog_Args + 1] = {ent,account,timestamp,transaction_type,callback,rawsearch}
	if ARCBank_AccountLog_Place == -1 then
		net.Start("arcbank_comm_get_account_log")
		net.WriteEntity(ARCBank_AccountLog_Args[1][1])
		net.WriteBool(tobool(ARCBank_AccountLog_Args[1][6]))
		net.WriteString(ARCBank_AccountLog_Args[1][2])
		net.WriteUInt(ARCBank_AccountLog_Args[1][3],32)
		net.WriteUInt(ARCBank_AccountLog_Args[1][4],16)
		net.SendToServer()
		ARCBank_AccountLog_Place = 1
	end
end
local function nextLog()
	ARCBank_AccountLog_Place = ARCBank_AccountLog_Place + 1
	if istable(ARCBank_AccountLog_Args[ARCBank_AccountLog_Place]) then
		net.Start("arcbank_comm_get_account_log")
		net.WriteEntity(ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][1])
		net.WriteBool(tobool(ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][6]))
		net.WriteString(ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][2])
		net.WriteUInt(ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][3],32)
		net.WriteUInt(ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][4],16)
		net.SendToServer()
	else
		ARCBank_AccountLog_Args = {}
		ARCBank_AccountLog_Place = -1
	end
end
net.Receive( "arcbank_comm_get_account_log", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	local ent = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][1]
	local callback = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][5]
	timer.Simple(0.00001,function() callback(errcode,0,nil,ent) end)
	nextLog()
end)
ARCLib.ReceiveBigMessage("arcbank_comm_get_account_log_dl",function(err,per,data,ply)
	if err == ARCLib.NET_DOWNLOADING then
		local ent = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][1]
		local callback = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][5]
		callback(ARCBANK_ERROR_DOWNLOADING,per*0.8,nil,ent)
	elseif err == ARCLib.NET_COMPLETE then
		--timer.Simple(0.0001,function() callback(ARCBANK_ERROR_DOWNLOADING,0.8,nil,ent) end) -- Gotta isolate it in its own stack just in case whoever coded the callback is an idiot
		ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][7] = data
		ARCBank_AccountLog_ArgsSort[#ARCBank_AccountLog_ArgsSort + 1] = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place]
		if ARCBank_AccountLog_PlaceSort == -1 then
			ARCBank_AccountLog_PlaceSort = 1
		end
		nextLog()
	else
		print("Incomming arcbank_comm_get_account_log_dl message errored! "..err)
		local ent = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][1]
		local callback = ARCBank_AccountLog_Args[ARCBank_AccountLog_Place][5]
		timer.Simple(0.00001,function() callback(ARCBANK_ERROR_CHUNK_MISMATCH,0,nil,ent) end)
		nextLog()
	end
end)
ARCLib.AddThinkFunc("ARCBank SortLog",function()
	if ARCBank_AccountLog_PlaceSort > 0 then
		--{ent,account,timestamp,transaction_type,callback,rawsearch}
		local ent = ARCBank_AccountLog_ArgsSort[ARCBank_AccountLog_PlaceSort][1]
		local callback = ARCBank_AccountLog_ArgsSort[ARCBank_AccountLog_PlaceSort][5]
		local bigstr = ARCBank_AccountLog_ArgsSort[ARCBank_AccountLog_PlaceSort][7]
		
		local nextdisplay = 0.05
		
		local datalen = 0
		local data = {}
		local line = string.Explode( "\r\n", bigstr)
		ARCBank_AccountLog_ArgsSort[ARCBank_AccountLog_PlaceSort][7] = "" -- Clear out the big string so we don't eat too much RAM
		line[#line] = nil --Last line of a log is always blank
		local linelen = #line
		for kk,vv in ipairs(line) do
			local stuffs = string.Explode("\t",vv)
			datalen = datalen + 1
			data[datalen] = {}
			data[datalen].transaction_id = tonumber(stuffs[1]) or 0
			data[datalen].timestamp = tonumber(stuffs[2]) or 0
			data[datalen].account1 = stuffs[3]
			data[datalen].account2 = stuffs[4]
			data[datalen].user1 = stuffs[5]
			data[datalen].user2 = stuffs[6]
			data[datalen].moneydiff = tonumber(stuffs[7]) or 0
			data[datalen].money = tonumber(stuffs[8])
			data[datalen].transaction_type = tonumber(stuffs[9])
			data[datalen].comment = stuffs[10]
			coroutine.yield()
			local per = kk/linelen
			if (kk/linelen > nextdisplay) then
				timer.Simple(0.0001,function() callback(ARCBANK_ERROR_DOWNLOADING,0.8+(per*0.2),nil,ent) end) -- Gotta isolate it in its own stack just in case whoever coded the callback is an idiot
				nextdisplay = nextdisplay + 0.05
			end
		end
		timer.Simple(0.1,function() callback(ARCBANK_ERROR_NONE,1,data,ent) end) -- Making sure the timer above ticks out first
		ARCBank_AccountLog_PlaceSort = ARCBank_AccountLog_PlaceSort + 1
		if not ARCBank_AccountLog_ArgsSort[ARCBank_AccountLog_PlaceSort] then
			ARCBank_AccountLog_PlaceSort = -1
			ARCBank_AccountLog_ArgsSort = {}
		end
		collectgarbage()
		coroutine.yield()
	end
end)


-- Withdraw/Deposit
local ARCBank_AccountAddMoney_Args = {}
local ARCBank_AccountAddMoney_Place = -1
function ARCBank.AddFromWallet(ent,account,amount,comment,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.AddFromWallet: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.AddFromWallet: Argument #2 is not a string")
	assert(isnumber(amount),"ARCBank.AddFromWallet: Argument #3 is not a number")
	assert(isstring(comment),"ARCBank.AddFromWallet: Argument #4 is not a string")
	assert(isfunction(callback),"ARCBank.AddFromWallet: Argument #5 is not a function")
	ARCBank_AccountAddMoney_Args[#ARCBank_AccountAddMoney_Args + 1] = {ent,account,amount,comment,callback}
	if ARCBank_AccountAddMoney_Place == -1 then
		net.Start("arcbank_comm_wallet")
		net.WriteEntity(ARCBank_AccountAddMoney_Args[1][1])
		net.WriteString(ARCBank_AccountAddMoney_Args[1][2])
		net.WriteInt(ARCBank_AccountAddMoney_Args[1][3],32)
		net.WriteString(ARCBank_AccountAddMoney_Args[1][4])
		net.SendToServer()
		ARCBank_AccountAddMoney_Place = 1
	end
end

net.Receive( "arcbank_comm_wallet", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place][1]
	local callback = ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place][5]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountAddMoney_Place = ARCBank_AccountAddMoney_Place + 1
	if istable(ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place]) then
		net.Start("arcbank_comm_wallet")
		net.WriteEntity(ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place][1])
		net.WriteString(ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place][2])
		net.WriteInt(ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place][3],32)
		net.WriteString(ARCBank_AccountAddMoney_Args[ARCBank_AccountAddMoney_Place][4])
		net.SendToServer()
	else
		ARCBank_AccountAddMoney_Args = {}
		ARCBank_AccountAddMoney_Place = -1
	end
end)


-- Create
local ARCBank_AccountCreate_Args = {}
local ARCBank_AccountCreate_Place = -1
function ARCBank.CreateAccount(ent,groupname,rank,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.CreateAccount: Argument #1 is not a valid entity")
	assert(isstring(groupname),"ARCBank.CreateAccount: Argument #2 is not a string")
	assert(isnumber(rank),"ARCBank.CreateAccount: Argument #3 is not a number")
	assert(isfunction(callback),"ARCBank.CreateAccount: Argument #4 is not a function")
	ARCBank_AccountCreate_Args[#ARCBank_AccountCreate_Args + 1] = {ent,groupname,rank,callback}
	if ARCBank_AccountCreate_Place == -1 then
		net.Start("arcbank_comm_create")
		net.WriteEntity(ARCBank_AccountCreate_Args[1][1])
		net.WriteString(ARCBank_AccountCreate_Args[1][2])
		net.WriteInt(ARCBank_AccountCreate_Args[1][3],ARCBANK_ERRORBITRATE)
		net.SendToServer()
		ARCBank_AccountCreate_Place = 1
	end
end

net.Receive( "arcbank_comm_create", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountCreate_Args[ARCBank_AccountCreate_Place][1]
	local callback = ARCBank_AccountCreate_Args[ARCBank_AccountCreate_Place][4]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountCreate_Place = ARCBank_AccountCreate_Place + 1
	if istable(ARCBank_AccountCreate_Args[ARCBank_AccountCreate_Place]) then
		net.Start("arcbank_comm_create")
		net.WriteEntity(ARCBank_AccountCreate_Args[ARCBank_AccountCreate_Place][1])
		net.WriteString(ARCBank_AccountCreate_Args[ARCBank_AccountCreate_Place][2])
		net.WriteInt(ARCBank_AccountCreate_Args[ARCBank_AccountCreate_Place][3],ARCBANK_ACCOUNTBITRATE)
		net.SendToServer()
	else
		ARCBank_AccountCreate_Args = {}
		ARCBank_AccountCreate_Place = -1
	end
end)

-- Upgrade
local ARCBank_AccountUpgrade_Args = {}
local ARCBank_AccountUpgrade_Place = -1
function ARCBank.UpgradeAccount(ent,groupname,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.UpgradeAccount: Argument #1 is not a valid entity")
	assert(isstring(groupname),"ARCBank.UpgradeAccount: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.UpgradeAccount: Argument #3 is not a function")
	ARCBank_AccountUpgrade_Args[#ARCBank_AccountUpgrade_Args + 1] = {ent,groupname,callback}
	if ARCBank_AccountUpgrade_Place == -1 then
		net.Start("arcbank_comm_upgrade")
		net.WriteEntity(ARCBank_AccountUpgrade_Args[1][1])
		net.WriteString(ARCBank_AccountUpgrade_Args[1][2])
		net.SendToServer()
		ARCBank_AccountUpgrade_Place = 1
	end
end

net.Receive( "arcbank_comm_upgrade", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountUpgrade_Args[ARCBank_AccountUpgrade_Place][1]
	local callback = ARCBank_AccountUpgrade_Args[ARCBank_AccountUpgrade_Place][3]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountUpgrade_Place = ARCBank_AccountUpgrade_Place + 1
	if istable(ARCBank_AccountUpgrade_Args[ARCBank_AccountUpgrade_Place]) then
		net.Start("arcbank_comm_upgrade")
		net.WriteEntity(ARCBank_AccountUpgrade_Args[ARCBank_AccountUpgrade_Place][1])
		net.WriteString(ARCBank_AccountUpgrade_Args[ARCBank_AccountUpgrade_Place][2])
		net.SendToServer()
	else
		ARCBank_AccountUpgrade_Args = {}
		ARCBank_AccountUpgrade_Place = -1
	end
end)

-- Downgrade
local ARCBank_AccountDowngrade_Args = {}
local ARCBank_AccountDowngrade_Place = -1
function ARCBank.DowngradeAccount(ent,groupname,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.DowngradeAccount: Argument #1 is not a valid entity")
	assert(isstring(groupname),"ARCBank.DowngradeAccount: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.DowngradeAccount: Argument #3 is not a function")
	ARCBank_AccountDowngrade_Args[#ARCBank_AccountDowngrade_Args + 1] = {ent,groupname,callback}
	if ARCBank_AccountDowngrade_Place == -1 then
		net.Start("arcbank_comm_downgrade")
		net.WriteEntity(ARCBank_AccountDowngrade_Args[1][1])
		net.WriteString(ARCBank_AccountDowngrade_Args[1][2])
		net.SendToServer()
		ARCBank_AccountDowngrade_Place = 1
	end
end

net.Receive( "arcbank_comm_downgrade", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountDowngrade_Args[ARCBank_AccountDowngrade_Place][1]
	local callback = ARCBank_AccountDowngrade_Args[ARCBank_AccountDowngrade_Place][3]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountDowngrade_Place = ARCBank_AccountDowngrade_Place + 1
	if istable(ARCBank_AccountDowngrade_Args[ARCBank_AccountDowngrade_Place]) then
		net.Start("arcbank_comm_downgrade")
		net.WriteEntity(ARCBank_AccountDowngrade_Args[ARCBank_AccountDowngrade_Place][1])
		net.WriteString(ARCBank_AccountDowngrade_Args[ARCBank_AccountDowngrade_Place][2])
		net.SendToServer()
	else
		ARCBank_AccountDowngrade_Args = {}
		ARCBank_AccountDowngrade_Place = -1
	end
end)

-- Delete
local ARCBank_AccountDelete_Args = {}
local ARCBank_AccountDelete_Place = -1
function ARCBank.RemoveAccount(ent,groupname,reason,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.RemoveAccount: Argument #1 is not a valid entity")
	assert(isstring(groupname),"ARCBank.RemoveAccount: Argument #2 is not a string")
	assert(isstring(reason),"ARCBank.RemoveAccount: Argument #3 is not a string")
	assert(isfunction(callback),"ARCBank.RemoveAccount: Argument 4 is not a function")
	ARCBank_AccountDelete_Args[#ARCBank_AccountDelete_Args + 1] = {ent,groupname,reason,callback}
	if ARCBank_AccountDelete_Place == -1 then
		net.Start("arcbank_comm_delete")
		net.WriteEntity(ARCBank_AccountDelete_Args[1][1])
		net.WriteString(ARCBank_AccountDelete_Args[1][2])
		net.WriteString(ARCBank_AccountDelete_Args[1][3])
		net.SendToServer()
		ARCBank_AccountDelete_Place = 1
	end
end

net.Receive( "arcbank_comm_delete", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountDelete_Args[ARCBank_AccountDelete_Place][1]
	local callback = ARCBank_AccountDelete_Args[ARCBank_AccountDelete_Place][4]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountDelete_Place = ARCBank_AccountDelete_Place + 1
	if istable(ARCBank_AccountDelete_Args[ARCBank_AccountDelete_Place]) then
		net.Start("arcbank_comm_delete")
		net.WriteEntity(ARCBank_AccountDelete_Args[ARCBank_AccountDelete_Place][1])
		net.WriteString(ARCBank_AccountDelete_Args[ARCBank_AccountDelete_Place][2])
		net.WriteString(ARCBank_AccountDelete_Args[ARCBank_AccountDelete_Place][3])
		net.SendToServer()
	else
		ARCBank_AccountDelete_Args = {}
		ARCBank_AccountDelete_Place = -1
	end
end)


-- Add Player to group
local ARCBank_AccountPlyAdd_Args = {}
local ARCBank_AccountPlyAdd_Place = -1
function ARCBank.GroupAddPlayer(ent,account,otherply,comment,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.GroupAddPlayer: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.GroupAddPlayer: Argument #2 is not a string")
	assert(isstring(otherply) or (IsValid(otherply) and otherply:IsPlayer()),"ARCBank.GroupAddPlayer: Argument #3 is not a string or player")
	assert(isstring(comment),"ARCBank.GroupAddPlayer: Argument #4 is not a string")
	assert(isfunction(callback),"ARCBank.GroupAddPlayer: Argument #5 is not a function")
	ARCBank_AccountPlyAdd_Args[#ARCBank_AccountPlyAdd_Args + 1] = {ent,account,otherply,comment,callback}
	if ARCBank_AccountPlyAdd_Place == -1 then
		net.Start("arcbank_comm_add_group_member")
		net.WriteEntity(ARCBank_AccountPlyAdd_Args[1][1])
		net.WriteString(ARCBank_AccountPlyAdd_Args[1][2])
		net.WriteBool(isentity(ARCBank_AccountPlyAdd_Args[1][3]))
		if isentity(ARCBank_AccountPlyAdd_Args[1][3]) then
			net.WriteEntity(ARCBank_AccountPlyAdd_Args[1][3])
		else
			net.WriteString(ARCBank_AccountPlyAdd_Args[1][3])
		end
		net.WriteString(ARCBank_AccountPlyAdd_Args[1][4])
		net.SendToServer()
		ARCBank_AccountPlyAdd_Place = 1
	end
end

net.Receive( "arcbank_comm_add_group_member", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][1]
	local callback = ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][5]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountPlyAdd_Place = ARCBank_AccountPlyAdd_Place + 1
	if istable(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place]) then
		net.Start("arcbank_comm_add_group_member")
		net.WriteEntity(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][1])
		net.WriteString(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][2])
		net.WriteBool(isentity(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][3]))
		if isentity(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][3]) then
			net.WriteEntity(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][3])
		else
			net.WriteString(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][3])
		end
		net.WriteString(ARCBank_AccountPlyAdd_Args[ARCBank_AccountPlyAdd_Place][4])
		net.SendToServer()
	else
		ARCBank_AccountPlyAdd_Args = {}
		ARCBank_AccountPlyAdd_Place = -1
	end
end)


-- Remove Player from group
local ARCBank_AccountPlyRemove_Args = {}
local ARCBank_AccountPlyRemove_Place = -1
function ARCBank.GroupRemovePlayer(ent,account,otherply,comment,callback)
	assert(isentity(ent) and IsValid(ent),"ARCBank.GroupRemovePlayer: Argument #1 is not a valid entity")
	assert(isstring(account),"ARCBank.GroupRemovePlayer: Argument #2 is not a string")
	assert(isstring(otherply) or (IsValid(otherply) and otherply:IsPlayer()),"ARCBank.GroupRemovePlayer: Argument #3 is not a string or player")
	assert(isstring(comment),"ARCBank.GroupRemovePlayer: Argument #4 is not a string")
	assert(isfunction(callback),"ARCBank.GroupRemovePlayer: Argument #5 is not a function")
	ARCBank_AccountPlyRemove_Args[#ARCBank_AccountPlyRemove_Args + 1] = {ent,account,otherply,comment,callback}
	if ARCBank_AccountPlyRemove_Place == -1 then
		net.Start("arcbank_comm_remove_group_member")
		net.WriteEntity(ARCBank_AccountPlyRemove_Args[1][1])
		net.WriteString(ARCBank_AccountPlyRemove_Args[1][2])
		net.WriteBool(isentity(ARCBank_AccountPlyRemove_Args[1][3]))
		if isentity(ARCBank_AccountPlyRemove_Args[1][3]) then
			net.WriteEntity(ARCBank_AccountPlyRemove_Args[1][3])
		else
			net.WriteString(ARCBank_AccountPlyRemove_Args[1][3])
		end
		net.WriteString(ARCBank_AccountPlyRemove_Args[1][4])
		net.SendToServer()
		ARCBank_AccountPlyRemove_Place = 1
	end
end

net.Receive( "arcbank_comm_remove_group_member", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local ent = ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][1]
	local callback = ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][5]
	timer.Simple(0.00001,function() callback(errcode,ent) end)
	ARCBank_AccountPlyRemove_Place = ARCBank_AccountPlyRemove_Place + 1
	if istable(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place]) then
		net.Start("arcbank_comm_remove_group_member")
		net.WriteEntity(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][1])
		net.WriteString(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][2])
		net.WriteBool(isentity(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][3]))
		if isentity(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][3]) then
			net.WriteEntity(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][3])
		else
			net.WriteString(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][3])
		end
		net.WriteString(ARCBank_AccountPlyRemove_Args[ARCBank_AccountPlyRemove_Place][4])
		net.SendToServer()
	else
		ARCBank_AccountPlyRemove_Args = {}
		ARCBank_AccountPlyRemove_Place = -1
	end
end)


-- GetAccountName
local ARCBank_AccountGetName_Args = {}
local ARCBank_AccountGetName_Place = -1
function ARCBank.GetAccountName(account,callback)
	assert(isstring(account),"ARCBank.GetAccountName: Argument #1 is not a string")
	assert(isfunction(callback),"ARCBank.GetAccountName: Argument #2 is not a function")
	ARCBank_AccountGetName_Args[#ARCBank_AccountGetName_Args + 1] = {account,callback}
	if ARCBank_AccountGetName_Place == -1 then
		net.Start("arcbank_comm_accname")
		net.WriteString(ARCBank_AccountGetName_Args[1][1])
		net.SendToServer()
		ARCBank_AccountGetName_Place = 1
	end
end

net.Receive( "arcbank_comm_accname", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	local name = net.ReadString()
	
	local callback = ARCBank_AccountGetName_Args[ARCBank_AccountGetName_Place][2]
	timer.Simple(0.00001,function() callback(errcode,name) end)
	ARCBank_AccountGetName_Place = ARCBank_AccountGetName_Place + 1
	if istable(ARCBank_AccountGetName_Args[ARCBank_AccountGetName_Place]) then
		net.Start("arcbank_comm_accname")
		net.WriteString(ARCBank_AccountGetName_Args[ARCBank_AccountGetName_Place][1])
		net.SendToServer()
	else
		ARCBank_AccountGetName_Args = {}
		ARCBank_AccountGetName_Place = -1
	end
end)

-- GetAccessableAccounts
local ARCBank_AccountAccess_Args = {}
local ARCBank_AccountAccess_Place = -1
function ARCBank.GetAccessableAccounts(plyto,callback)
	assert(isstring(plyto) or (IsValid(plyto) and plyto:IsPlayer()),"ARCBank.GetAccessableAccounts: Argument #1 is not a string or player")
	assert(isfunction(callback),"ARCBank.GetAccessableAccounts: Argument #2 is not a function")
	ARCBank_AccountAccess_Args[#ARCBank_AccountAccess_Args + 1] = {plyto,callback}
	if ARCBank_AccountAccess_Place == -1 then
		net.Start("arcbank_comm_get_accounts")
		net.WriteBool(isentity(ARCBank_AccountAccess_Args[1][1]))
		if isentity(ARCBank_AccountAccess_Args[1][1]) then
			net.WriteEntity(ARCBank_AccountAccess_Args[1][1])
		else
			net.WriteString(ARCBank_AccountAccess_Args[1][1])
		end
		net.SendToServer()
		ARCBank_AccountAccess_Place = 1
	end
end

net.Receive( "arcbank_comm_get_accounts", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	
	local data = {}
	if errcode == ARCBANK_ERROR_NONE then
		local len = net.ReadUInt(32)
		for i=1,len do
			data[i] = net.ReadString()
		end
	end
	
	local callback = ARCBank_AccountAccess_Args[ARCBank_AccountAccess_Place][2]
	timer.Simple(0.00001,function() callback(errcode,data) end)
	ARCBank_AccountAccess_Place = ARCBank_AccountAccess_Place + 1
	if istable(ARCBank_AccountAccess_Args[ARCBank_AccountAccess_Place]) then
		net.Start("arcbank_comm_get_accounts")
		net.WriteBool(isentity(ARCBank_AccountAccess_Args[ARCBank_AccountPlyRemove_Place][1]))
		if isentity(ARCBank_AccountAccess_Args[ARCBank_AccountPlyRemove_Place][1]) then
			net.WriteEntity(ARCBank_AccountAccess_Args[ARCBank_AccountPlyRemove_Place][1])
		else
			net.WriteString(ARCBank_AccountAccess_Args[ARCBank_AccountPlyRemove_Place][1])
		end
		net.SendToServer()
	else
		ARCBank_AccountAccess_Args = {}
		ARCBank_AccountAccess_Place = -1
	end
end)


-- Admin search account?
--1 Account owner (UserID)
--2 Group Member (UserID)
--3 Accessable accounts (UserID) (Group member and account owner combined)
--4 Balance equal
--5 Balance more
--6 Balance less
local ARCBank_AdminSearch_Args = {}
local ARCBank_AdminSearch_Place = -1
function ARCBank.AdminSearch(search,term,callback)
	assert(isnumber(search),"ARCBank.AdminSearch: Argument #1 is not a number")
	assert(isstring(term),"ARCBank.AdminSearch: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.AdminSearch: Argument #3 is not a function")
	ARCBank_AdminSearch_Args[#ARCBank_AdminSearch_Args + 1] = {search,term,callback}
	if ARCBank_AdminSearch_Place == -1 then
		net.Start("arcbank_comm_admin_search")
		net.WriteUInt(ARCBank_AdminSearch_Args[1][1],4)
		net.WriteString(ARCBank_AdminSearch_Args[1][2])
		net.SendToServer()
		ARCBank_AdminSearch_Place = 1
	end
end

net.Receive( "arcbank_comm_admin_search", function(length)
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	local callback = ARCBank_AdminSearch_Args[ARCBank_AdminSearch_Place][3]
	local tab = {}
	local tablen = net.ReadUInt(32)
	for i=1,tablen do
		tab[i] = net.ReadString()
	end
	timer.Simple(0.00001,function() callback(errcode,tab) end)
	ARCBank_AdminSearch_Place = ARCBank_AdminSearch_Place + 1
	if istable(ARCBank_AdminSearch_Args[ARCBank_AdminSearch_Place]) then
		net.Start("arcbank_comm_admin_search")
		net.WriteUInt(ARCBank_AdminSearch_Args[ARCBank_AdminSearch_Place][1],4)
		net.WriteString(ARCBank_AdminSearch_Args[ARCBank_AdminSearch_Place][2])
		net.SendToServer()
	else
		ARCBank_AdminSearch_Args = {}
		ARCBank_AdminSearch_Place = -1
	end
end)


local ARCBank_Secret_IsBusy = false
local ARCBank_Secret_Ent = NULL
local ARCBank_Secret_CallBack
function ARCBank.Secret(num,nnum,entity,callback)
	if ARCBank_Secret_IsBusy then callback(false) return end
	if !entity.ARCBank_IsAValidDevice then callback(false) return end -- Kind of useless doing it, anyone can just net_start a secret.
	ARCBank_Secret_CallBack = callback
	ARCBank_Secret_IsBusy = true
	ARCBank_Secret_Ent = entity
	net.Start("arcbank_comm_secret")
	net.WriteEntity(entity)
	net.WriteInt(num,8)
	net.WriteInt(nnum,32)
	net.SendToServer()
end

net.Receive( "arcbank_comm_secret", function(length)
	ARCBank_Secret_CallBack(tobool(net.ReadBit()),ARCBank_Secret_Ent)
	ARCBank_Secret_IsBusy = false
	ARCBank_Secret_CallBack = nil
	ARCBank_Secret_Ent = NULL
end)

net.Receive( "arcbank_comm_atmspawn", function(length)
	local count = net.ReadUInt(32)
	MainPanel = vgui.Create( "DFrame" )
	MainPanel:SetPos( ScrW()/2 - 110, ScrH()/2 - 30)
	MainPanel:SetSize( 220, 60 )
	MainPanel:SetTitle( "atm_spawn" )
	MainPanel:SetVisible( true )
	MainPanel:SetDraggable( true )
	MainPanel:ShowCloseButton( true )
	MainPanel:MakePopup()
	local DComboBox = vgui.Create( "DComboBox" ,MainPanel)
	DComboBox:SetPos( 10, 30 )
	DComboBox:SetSize( 200, 20 )
	DComboBox:SetValue( ARCBank.Msgs.Commands["atm_spawn"] )
	for i=1,count do
		DComboBox:AddChoice( net.ReadString() )
	end
	DComboBox.OnSelect = function( panel, index, value )
		net.Start("arcbank_comm_atmspawn")
		net.WriteString(value)
		net.SendToServer()
		MainPanel:Remove()
	end
end)





