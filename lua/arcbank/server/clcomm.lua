-- clcomm.lua - Client/Server communications for ARCBank
-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

--Check if the thing is running

util.AddNetworkString( "arcbank_comm_check" )
ARCBank.Loaded = false

net.Receive( "arcbank_comm_check", function(length,ply)
	net.Start("arcbank_comm_check")
	net.WriteBit(ARCBank.Loaded)
	net.WriteBit(ARCBank.Outdated)
	net.Send(ply)
end)

local function isValidPermissions(ply,ent,perm)
	local readPerm = bit.band(perm,bit.bor(ARCBANK_PERMISSIONS_DEPOSIT,ARCBANK_PERMISSIONS_WITHDRAW,ARCBANK_PERMISSIONS_TRANSFER,ARCBANK_PERMISSIONS_RANK,ARCBANK_PERMISSIONS_CREATE,ARCBANK_PERMISSIONS_MEMBERS)) == 0
	return table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) or (table.HasValue(ARCBank.Settings.moderators,string.lower(ply:GetUserGroup())) and (readPerm or not ARCBank.Settings.moderators_read_only)) or (isfunction(ent.GetARCBankUsePlayer) and ent:GetARCBankUsePlayer() == ply and bit.band(tonumber(ent.ARCBank_Permissions) or 0,perm)) > 0
end
--[[
ARCBANK_PERMISSIONS_READ = 1
ARCBANK_PERMISSIONS_READ_LOG = 2
ARCBANK_PERMISSIONS_DEPOSIT = 4
ARCBANK_PERMISSIONS_WITHDRAW = 8
ARCBANK_PERMISSIONS_TRANSFER = 16
ARCBANK_PERMISSIONS_RANK = 32
ARCBANK_PERMISSIONS_CREATE = 64
ARCBANK_PERMISSIONS_MEMBERS = 128
ARCBANK_PERMISSIONS_OTHER = 32768
ARCBANK_PERMISSIONS_EVERYTHING = 65535 -- everything

ARCBANK_ERROR_ENTITY_NO_ACCESS
]]
-- Account Properties --
util.AddNetworkString( "arcbank_comm_get_account_properties" )
net.Receive( "arcbank_comm_get_account_properties", function(length,ply)
	local ent = net.ReadEntity()
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_READ) then
		net.Start("arcbank_comm_get_account_properties")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	local name = net.ReadString()
	ARCBank.GetAccountProperties(ply,name,function(err,data)
		net.Start("arcbank_comm_get_account_properties")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		if istable(data) then
			if isstring(data.account) then
				net.WriteString(data.account)
			end
			if isstring(data.name) then
				net.WriteString(data.name)
			end
			if isstring(data.owner) then
				net.WriteString(data.owner)
			end
			if isnumber(data.rank) then
				net.WriteUInt(data.rank,ARCBANK_ACCOUNTBITRATE)
			end
		end
		net.Send(ply)
	end)
end)

-- Account Balance
util.AddNetworkString( "arcbank_comm_get_account_balance" )
net.Receive( "arcbank_comm_get_account_balance", function(length,ply)
	local ent = net.ReadEntity()
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_READ) then
		net.Start("arcbank_comm_get_account_balance")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	local name = net.ReadString()
	ARCBank.GetBalance(ply,name,function(err,balance)
		net.Start("arcbank_comm_get_account_balance")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.WriteDouble(balance or 0)
		net.Send(ply)
	end)
end)

-- Group Members
util.AddNetworkString( "arcbank_comm_get_group_members" )
net.Receive( "arcbank_comm_get_group_members", function(length,ply)
	local ent = net.ReadEntity()
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_READ) then
		net.Start("arcbank_comm_get_group_members")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	local name = net.ReadString()
	ARCBank.GroupGetPlayers(ply,name,function(err,people)
		net.Start("arcbank_comm_get_group_members")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		if istable(people) then
			local len = #people
			net.WriteUInt(len,32)
			for i=1,len do
				net.WriteString(people[i])
			end
		end
		net.Send(ply)
	end)
end)

-- Transfer
util.AddNetworkString( "arcbank_comm_transfer" )
net.Receive( "arcbank_comm_transfer", function(length,ply) -- Potential exploit: Someone could send a billion transfers of $1 to lock out someone's account
	local ent = net.ReadEntity()
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_TRANSFER) then
		net.Start("arcbank_comm_transfer")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	local plyto
	local usePlyEnt = net.ReadBool()
	if usePlyEnt then
		plyto = net.ReadEntity()
	else
		plyto = net.ReadString()
	end
	local accountfrom = net.ReadString()
	local accountto = net.ReadString()
	local amount = net.ReadUInt(32)
	local comment = net.ReadString()
	ARCBank.Transfer(ply,plyto,accountfrom,accountto,amount,comment,function(err)
		net.Start("arcbank_comm_transfer")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)

-- Get Log
local readLogs = {}
ARCLib.RegisterBigMessage("arcbank_comm_get_account_log_dl",16000,255,true)
local maxloglen = 16000*255
util.AddNetworkString( "arcbank_comm_get_account_log" )
net.Receive( "arcbank_comm_get_account_log", function(length,ply)
	local ent = net.ReadEntity()
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_READ_LOG) then
		net.Start("arcbank_comm_get_account_log")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	local teatAsRawName = net.ReadBool() and table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup()))
	local account = net.ReadString()
	local timestamp = net.ReadUInt(32) -- This addon is not going to be used in 2038. Shocking, I know
	local transaction_type = net.ReadUInt(16)
	local callback = function(err,progress,data)
		if err == ARCBANK_ERROR_NONE then
			local datalen = #data
			datalen = datalen + 1
			data[datalen] = ply
			--datalen = datalen + 1
			--data[datalen] = ent
			readLogs[#readLogs + 1] = data 
		elseif err != ARCBANK_ERROR_DOWNLOADING then
			net.Start("arcbank_comm_get_account_log")
			net.WriteInt(err,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	end
	if teatAsRawName then
		ARCBank.ReadTransactions(account,timestamp,transaction_type,callback)
	else
		ARCBank.GetLog(ply,account,timestamp,transaction_type,callback)
	end
end)


if !ARCLib.IsVersion("1.6.2") then return end -- ARCLib.AddThinkFunc is only available in v1.6.2 or later

ARCLib.AddThinkFunc("ARCBank SendUserLogs",function()
	local i = 1
	while i <= #readLogs do
		local entries = readLogs[i]
		local ply = table.remove(entries)
		--local ent = table.remove(entries)
		local bigstring = ""
		for k,v in ipairs(entries) do 
			bigstring = bigstring .. v.transaction_id.."\t"..v.timestamp.."\t"..v.account1.."\t"..v.account2.."\t"..v.user1.."\t"..v.user2.."\t"..v.moneydiff.."\t"..(v.money or "").."\t"..v.transaction_type.."\t"..string.Replace( v.comment, "\r\n", " " ).."\r\n"
			coroutine.yield()
			if !IsValid(ply) then break end
		end
		if IsValid(ply) then
			if #bigstring > maxloglen then
				local place = string.find( bigstring, "\r\n", -maxloglen, true )
				bigstring = string.sub(bigstring,place)
				ARCBank.MsgCL(ply,"The log was too big to send, the oldest stuff has been cut off.")
			end
			--I would compress the data before sending if util.Compress didn't block the entire server. (It takes 1.5 seconds to compress 4.4KB on my Intel i7 5820k, I don't want to freeze the server just because some idiot wants to look at 3 years of transaction history)
			ARCLib.SendBigMessage("arcbank_comm_get_account_log_dl",bigstring,ply,NULLFUNC) -- Client gets notified of errors anyway
		end
		i = i + 1
	end
	readLogs = {}
	coroutine.yield() 

end)


-- Withdraw/Deposit
util.AddNetworkString( "arcbank_comm_wallet" )
net.Receive( "arcbank_comm_wallet", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	local amount = net.ReadInt(32)
	local comment = net.ReadString()
	--local
	local perm = ARCBANK_PERMISSIONS_DEPOSIT
	if amount < 0 then
		perm = ARCBANK_PERMISSIONS_WITHDRAW
	end
	if !isValidPermissions(ply,ent,perm) then
		net.Start("arcbank_comm_wallet")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	ARCBank.AddFromWallet(ply,account,amount,comment,function(err)
		net.Start("arcbank_comm_wallet")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)


-- Create
util.AddNetworkString( "arcbank_comm_create" )
net.Receive( "arcbank_comm_create", function(length,ply)
	local ent = net.ReadEntity()
	local groupname = net.ReadString()
	local rank = net.ReadUInt(ARCBANK_ACCOUNTBITRATE)
	--local
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_CREATE) then
		net.Start("arcbank_comm_create")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	ARCBank.CreateAccount(ply,groupname,rank,function(err)
		net.Start("arcbank_comm_create")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)

-- Upgrade
util.AddNetworkString( "arcbank_comm_upgrade" )
net.Receive( "arcbank_comm_upgrade", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	--local
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_RANK) then
		net.Start("arcbank_comm_upgrade")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	
	ARCBank.UpgradeAccount(ply,account,function(err,people)
		net.Start("arcbank_comm_upgrade")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)

-- Downgrade
util.AddNetworkString( "arcbank_comm_downgrade" )
net.Receive( "arcbank_comm_downgrade", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	--local
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_RANK) then
		net.Start("arcbank_comm_downgrade")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	
	ARCBank.DowngradeAccount(ply,account,function(err,people)
		net.Start("arcbank_comm_downgrade")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)


-- Delete
util.AddNetworkString( "arcbank_comm_delete" )
net.Receive( "arcbank_comm_delete", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	local reason = net.ReadString()
	--local
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_CREATE) then
		net.Start("arcbank_comm_delete")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	
	ARCBank.RemoveAccount(ply,account,reason,function(err,people)
		net.Start("arcbank_comm_delete")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)


--[[
ARCBANK_PERMISSIONS_READ = 1
ARCBANK_PERMISSIONS_READ_LOG = 2
ARCBANK_PERMISSIONS_DEPOSIT = 4
ARCBANK_PERMISSIONS_WITHDRAW = 8
ARCBANK_PERMISSIONS_TRANSFER = 16
ARCBANK_PERMISSIONS_RANK = 32
ARCBANK_PERMISSIONS_CREATE = 64
ARCBANK_PERMISSIONS_MEMBERS = 128
ARCBANK_PERMISSIONS_OTHER = 32768
ARCBANK_PERMISSIONS_EVERYTHING = 65535 -- everything

]]

-- Add/Remove player from group
util.AddNetworkString( "arcbank_comm_add_group_member" )
net.Receive( "arcbank_comm_add_group_member", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	local otherply
	local usePlyEnt = net.ReadBool()
	if usePlyEnt then
		otherply = net.ReadEntity()
	else
		otherply = net.ReadString()
	end
	local comment = net.ReadString()
	--local
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_MEMBERS) then
		net.Start("arcbank_comm_add_group_member")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	
	ARCBank.GroupAddPlayer(ply,account,otherply,comment,function(err)
		net.Start("arcbank_comm_add_group_member")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)

util.AddNetworkString( "arcbank_comm_remove_group_member" )
net.Receive( "arcbank_comm_remove_group_member", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	local otherply
	local usePlyEnt = net.ReadBool()
	if usePlyEnt then
		otherply = net.ReadEntity()
	else
		otherply = net.ReadString()
	end
	local comment = net.ReadString()
	--local
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_MEMBERS) then
		net.Start("arcbank_comm_remove_group_member")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	
	
	ARCBank.GroupRemovePlayer(ply,account,otherply,comment,function(err)
		net.Start("arcbank_comm_remove_group_member")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end)
end)

-- AccountName
util.AddNetworkString( "arcbank_comm_accname" )
net.Receive( "arcbank_comm_accname", function(length,ply)
	local account = net.ReadString()
	ARCBank.GetAccountName(account,function(err,name)
		net.Start("arcbank_comm_accname")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		net.WriteString(name or "")
		net.Send(ply)
	end)
end)

--GetAccessableAccounts

util.AddNetworkString( "arcbank_comm_get_accounts" )
net.Receive( "arcbank_comm_get_accounts", function(length,ply)
	--[[
	local ent = net.ReadEntity()
	if !isValidPermissions(ply,ent,ARCBANK_PERMISSIONS_READ) then
		net.Start("arcbank_comm_get_accounts")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	]]
	local plyto
	local usePlyEnt = net.ReadBool()
	if usePlyEnt then
		plyto = net.ReadEntity()
	else
		plyto = net.ReadString()
	end
	ARCBank.GetAccessableAccounts(plyto,function(err,accounts)
		net.Start("arcbank_comm_get_accounts")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		if istable(accounts) then
			local len = #accounts
			net.WriteUInt(len,32)
			for i=1,len do
				net.WriteString(accounts[i])
			end
		end
		net.Send(ply)
	end)
end)

-- Admin search account?
--1 Account owner (UserID)
--2 Group Member (UserID)
--3 Accessible accounts (UserID) (Group member and account owner combined)
--4 Balance equal
--5 Balance more
--6 Balance less
--7 rank
--8 name search
local comparefuncsbal = {}
comparefuncsbal[4] = function(a,b) return a==b end
comparefuncsbal[5] = function(a,b) return a>b end
comparefuncsbal[6] = function(a,b) return a<b end

local comparefuncs = {}
comparefuncs[7] = function(a,b) return a.rank==(tonumber(b) or 0) end
comparefuncs[8] = function(a,b) return string.find( utf8.lower(a.name), utf8.lower(b), 1, true )!=nil end

util.AddNetworkString( "arcbank_comm_admin_search" )
net.Receive( "arcbank_comm_admin_search", function(length,ply)
	--local
	if not table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) and not table.HasValue(ARCBank.Settings.moderators,string.lower(ply:GetUserGroup())) then
		net.Start("arcbank_comm_admin_search")
		net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	local search = net.ReadUInt(4)
	local term = net.ReadString()
	local callback = function(err,list)
		net.Start("arcbank_comm_admin_search")
		net.WriteInt(err,ARCBANK_ERRORBITRATE)
		if istable(list) then
			local len = #list
			net.WriteUInt(len,32)
			for i=1,len do
				net.WriteString(list[i])
			end
		else 
			net.WriteUInt(0,32)
		end
		net.Send(ply)
	end
	
	
	if search == 1 then -- Account owner (UserID)
		ARCBank.GetOwnedAccounts(term,callback)
	elseif search == 2 then -- Group Member (UserID)
		ARCBank.GetGroupAccounts(term,callback)
	elseif search == 3 then -- Accessable accounts (UserID) (Group member and account owner combined)
	elseif isfunction(comparefuncsbal[search]) then
		term = tonumber(term) or 0
		ARCBank.ReadAllAccountProperties(function(err,data)
			if err == ARCBANK_ERROR_NONE then
				local list = {}
				ARCLib.ForEachAsync(data,function(k,v,cb)
					ARCBank.ReadBalance(v.account,function(err,amount)
						if err == ARCBANK_ERROR_NONE and comparefuncsbal[search](amount,term) then
							list[#list + 1] = v.account
						end
						cb()
					end,true)
				end,function()
					callback(ARCBANK_ERROR_NONE,list)
				end)
			else
				net.Start("arcbank_comm_admin_search")
				net.WriteInt(err,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		end)
	elseif isfunction(comparefuncs[search]) then
		ARCBank.ReadAllAccountProperties(function(err,data)
			if err == ARCBANK_ERROR_NONE then
				local list = {}
				ARCLib.ForEachAsync(data,function(k,v,cb)
					if comparefuncs[search](v,term) then
						list[#list + 1] = v.account
					end
					cb()
				end,function()
					callback(ARCBANK_ERROR_NONE,list)
				end)
			else
				net.Start("arcbank_comm_admin_search")
				net.WriteInt(err,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		end)
	else
		net.Start("arcbank_comm_admin_search")
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)


local PlayersWhoDidThatThing = {}
util.AddNetworkString( "arcbank_comm_secret" )
net.Receive( "arcbank_comm_secret", function(length,ply)
	local ent = net.ReadEntity()
	local operation = net.ReadInt(8)
	local arg = net.ReadInt(32)
	if !IsValid(ent) || !ent.ARCBank_IsAValidDevice || !ent.IsAFuckingATM then
		net.Start("arcbank_comm_secret")
		net.WriteBit(false)
		net.Send(ply)
		return
	end
	if operation == -1 then
		net.Start("arcbank_comm_secret")
		net.WriteBit(ply.ARCBank_Secrets)
		net.Send(ply)
	elseif operation == 0 then
		-- My birthday :)
		if arg == 19970415 && ARCBank.Settings["_ester_eggs"] && math.random() < 0.9 then
			ARCBank.MsgCL(ply,"Hello.")
			ply.ARCBank_Secrets = true
			net.Start("arcbank_comm_secret")
			net.WriteBit(true)
			net.Send(ply)
			timer.Simple(math.random(200,1000),function()
				if IsValid(ply) && ply:IsPlayer() then
					ARCBank.MsgCL(ply,"Goodbye.")
					ply.ARCBank_Secrets = false
				end
			end)
		else
			timer.Simple(math.Rand(0.7,1.7),function()
				net.Start("arcbank_comm_secret")
				net.WriteBit(false)
				net.Send(ply)
			end)
			if arg == 88888888 then
				timer.Simple(0.25,function() ply:EmitSound("eight.wav") 
					ply:SendLua("hook.Add(\"HUDPaint\", \"88888888\", function() draw.SimpleText(\"8\" , \"88888888\", surface.ScreenWidth()/2,surface.ScreenHeight()/2, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER) end)")
					timer.Simple(1,function() 
						if IsValid(ply) && ply:IsPlayer() then
							ply:SendLua("hook.Remove( \"HUDPaint\", \"88888888\")")
						end
					end)
				end)
			end
		end
		
	elseif operation == 1 then
		local telent = ents.GetByIndex(arg)
		if ply.ARCBank_Secrets && IsValid(telent) && telent.IsAFuckingATM && !telent.InUse then
			ply:SetPos(telent:GetPos() + ((telent:GetAngles():Up() * -30) + (telent:GetAngles():Forward() * 40)))
			ply:SetVelocity(ply:GetVelocity()*-1)
			net.Start("arcbank_comm_secret")
			net.WriteBit(true)
			net.Send(ply)
		else
			net.Start("arcbank_comm_secret")
			net.WriteBit(false)
			net.Send(ply)
		end
	elseif operation == 3 then
		if ply.ARCBank_Secrets then
			if arg == 1337 then
				if table.HasValue(PlayersWhoDidThatThing,ARCBank.GetPlayerID(ply)) then
					ply:Kick("Yeah, yeah. That was funny. Just don't abuse this shit, alright?")
					return
				end
				for k,v in pairs(ents.FindByClass("sent_arc_atm")) do
					timer.Simple(math.Rand(5,15),function()
						if !IsValid(v) then return end
						local OldVel = v:GetPhysicsObject():GetVelocity()	
						local OldAVel = v:GetPhysicsObject():GetAngleVelocity()
						local oldpos = v:GetPos()
						local oldang = v:GetAngles()
						
						v.ARCBank_MapEntity = false
						v:Remove()
						local welddummeh = ents.Create ("sent_arc_atm_rocket");
						welddummeh:SetPos(oldpos);
						welddummeh:SetAngles(oldang)
						welddummeh:Spawn()
						--dummeh:SetColor( Color(0,0,0,0) )
						welddummeh:GetPhysicsObject():SetVelocityInstantaneous(OldVel)
						welddummeh:GetPhysicsObject():AddAngleVelocity(OldAVel)
						welddummeh.MapEnt = {oldpos,oldang}
						welddummeh.Random = true
					end)
				end
				table.insert(PlayersWhoDidThatThing,ARCBank.GetPlayerID(ply))
			else
			
				local OldVel = ent:GetPhysicsObject():GetVelocity()	
				local OldAVel = ent:GetPhysicsObject():GetAngleVelocity()
				local oldpos = ent:GetPos()
				local oldang = ent:GetAngles()
				
				ent.ARCBank_MapEntity = false
				ent:Remove()
				local welddummeh = ents.Create ("sent_arc_atm_rocket");
				welddummeh:SetPos(oldpos);
				welddummeh:SetAngles(oldang)
				welddummeh:Spawn()
				--dummeh:SetColor( Color(0,0,0,0) )
				welddummeh:GetPhysicsObject():SetVelocityInstantaneous(OldVel)
				welddummeh:GetPhysicsObject():AddAngleVelocity(OldAVel)
				if arg == 1 || arg == 3 then
					welddummeh.MapEnt = {oldpos,oldang}
				elseif !table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) then
					ARCBank.MsgCL(ply,"This was meant to be harmless fun, but it's getting a little abused. The ATM will return to its original location once it's done flying.")
					welddummeh.MapEnt = {oldpos,oldang}
				end
				if arg == 2 || arg == 3 then
					welddummeh.Random = true
				end
			end
			net.Start("arcbank_comm_secret")
			net.WriteBit(true)
			net.Send(ply)
		else
			net.Start("arcbank_comm_secret")
			net.WriteBit(false)
			net.Send(ply)
		end
	
	end
end)

util.AddNetworkString( "arcbank_comm_atmspawn" )

net.Receive( "arcbank_comm_atmspawn", function(length,ply)
	if !table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) then
		ARCBank.MsgCL(ply,ARCLib.PlaceholderReplace(ARCBank.Msgs.CommandOutput.AdminCommand,{RANKS=table.concat( ARCBank.Settings.admins, ", " )}))
	return end
	
	local atmtype = net.ReadString()
	local tr = ply:GetEyeTrace()
	local ang = ply:EyeAngles()
	ang.yaw = ang.yaw + 180 -- Rotate it 180 degrees in my favour
	ang.roll = 0
	ang.pitch = 0
	ATMCreatorProp = ents.Create( "sent_arc_atm" )
	ATMCreatorProp:SetPos(tr.HitPos + tr.HitNormal * 60)
	ATMCreatorProp:SetAngles(ang)
	ATMCreatorProp.ARCBank_InitSpawnType = atmtype
	ATMCreatorProp:Spawn()
	ATMCreatorProp:Activate()
end)
util.AddNetworkString("arcbank_comm_client_settings_changed")
util.AddNetworkString("arcbank_comm_client_settings")

