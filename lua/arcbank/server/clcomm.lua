-- clcomm.lua - Client/Server communications for ARCBank
-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.

--Check if the thing is running

util.AddNetworkString( "arcbank_comm_check" )
ARCBank.Loaded = false

ARCBank.EasterEggs = (!file.Exists("arcbank_no_easter_eggs.txt","DATA")) && tobool(math.Round(math.random()))

net.Receive( "arcbank_comm_check", function(length,ply)
	net.Start("arcbank_comm_check")
	net.WriteBit(ARCBank.Loaded)
	net.WriteBit(ARCBank.Outdated)
	net.Send(ply)
end)


-- Account information --

util.AddNetworkString( "arcbank_comm_get_account_information" )

net.Receive( "arcbank_comm_get_account_information", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local accname = tostring(net.ReadString())
	local callback = function(accdata)
		if accdata then
			if ARCBank.PlayerHasAccesToAccount(ply,accdata) then
				if !accdata.isgroup then
					accdata.owner = ""
					accdata.members = {}
				end
				net.Start("arcbank_comm_get_account_information")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_NONE,ARCBANK_ERRORBITRATE)
				net.WriteBit(accdata.isgroup)
				net.WriteString(accdata.filename)
				net.WriteString(accdata.name)
				net.WriteString(accdata.owner)
				if (math.random(1,4) == 1 && os.date("%d%m") == "0104") then
					net.WriteDouble(0) 
					timer.Simple(2, function() ARCBank.MsgCL(ply,"April fools :)") end)
				else
					net.WriteDouble(accdata.money) 
				end
				
				net.WriteUInt(accdata.rank,ARCBANK_ACCOUNTBITRATE)
				net.WriteTable(accdata.members)
				net.Send(ply)
			else
				net.Start("arcbank_comm_get_account_information")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		else
			net.Start("arcbank_comm_get_account_information")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_NIL_ACCOUNT,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	end
	if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
		if accname == "" then
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(ARCBank.GetPlayerID(ply)),false,callback)
		else
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(accname),true,callback)
		end
	else
		ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
		net.Start("arcbank_comm_get_account_information")
		net.WriteEntity(ent)
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)

-- Transfer funds --

util.AddNetworkString( "arcbank_comm_transfer" )

net.Receive( "arcbank_comm_transfer", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local sid = tostring(net.ReadString())
	local accountfrom = tostring(net.ReadString())
	local accountto = tostring(net.ReadString())
	local amount = net.ReadUInt(32)
	local reason = tostring(net.ReadString())
	local function callback(errcode)
		net.Start("arcbank_comm_transfer")
		net.WriteEntity(ent)
		net.WriteInt(errcode,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
	
	if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
		local tply = ARCBank.GetPlayerByID(sid)
		if !tply:IsPlayer() then
			tply = sid
		end
		ARCBank.Transfer(ply,tply,accountfrom,accountto,amount,reason,callback)
	else
		ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
		net.Start("arcbank_comm_transfer")
		net.WriteEntity(ent)
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)

-- Get Group List 
--_ARCBank_Group_List
--_ARCBank_Group_List_Place
util.AddNetworkString( "arcbank_comm_group_list" )
net.Receive( "arcbank_comm_group_list", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local steamid = tostring(net.ReadString())
	if string.StartWith(steamid,"RECIEVED DUH FOOKING CHUNK ||||") then
		local progr = string.Explode("/",string.Replace(steamid,"RECIEVED DUH FOOKING CHUNK ||||",""))
		if tonumber(progr[2]) == #ply._ARCBank_Group_List then
			if tonumber(progr[1]) == ply._ARCBank_Group_List_Place then
				ply._ARCBank_Group_List_Place = ply._ARCBank_Group_List_Place + 1
				net.Start("arcbank_comm_group_list")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_NONE,ARCBANK_ERRORBITRATE)
				net.WriteUInt(ply._ARCBank_Group_List_Place,32)
				net.WriteUInt(#ply._ARCBank_Group_List,32)
				net.WriteString(tostring(ply._ARCBank_Group_List[ply._ARCBank_Group_List_Place]))
				net.Send(ply)
				if ply._ARCBank_Group_List_Place == #ply._ARCBank_Group_List then
					ply._ARCBank_Group_List = nil
				end
			else
				net.Start("arcbank_comm_group_list")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		else
			net.Start("arcbank_comm_group_list")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	else
		--ARCBank.Msgs.ATMMsgs.PersonalAccount
		if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
			ARCBank.GroupAccountAcces(steamid,function(code,lst)
				net.Start("arcbank_comm_group_list")
				net.WriteEntity(ent)
				net.WriteInt(code,ARCBANK_ERRORBITRATE)
				if code == 0 then
					--table.insert(lst,1,ARCBank.Msgs.ATMMsgs.PersonalAccount)
					ply._ARCBank_Group_List = ARCLib.SplitString(util.TableToJSON(lst),16384) -- Splitting the string every 16 kb just in case
					ply._ARCBank_Group_List_Place = 0
					net.WriteUInt(0,32)
					net.WriteUInt(#ply._ARCBank_Group_List,32)
					net.WriteString("")
				end
				net.Send(ply)
			end)
		else
			ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
			net.Start("arcbank_comm_group_list")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	end
end)

--Create Account

util.AddNetworkString( "arcbank_comm_create" )

net.Receive( "arcbank_comm_create", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local accname = tostring(net.ReadString())
	local callback = function(errcode)
		net.Start("arcbank_comm_create")
		net.WriteEntity(ent)
		net.WriteInt(errcode,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
	if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
		if accname == "" then
			ARCBank.CreateAccount(ply,1,ARCBank.Settings["account_starting_cash"],accname,callback)
		else
			if ent.IsAFuckingATM && ent.UsePlayer == ply && string.find( accname, "() { :;};", 1, true ) then
				--TODO:SHELLSHOCK
				ent:Break()
				ent:ATM_USE(ply)
				timer.Simple(2,function()
					if IsValid(ent) then
						ent:Reboot(2)
					end
				end)
				
				net.Start("arcbank_comm_create")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_UNKNOWN,ARCBANK_ERRORBITRATE)
				net.Send(ply)
				return
			end
			ARCBank.CreateAccount(ply,6,0,accname,callback)
		end
	else
		ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
		net.Start("arcbank_comm_create")
		net.WriteEntity(ent)
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)

--Delete Account

util.AddNetworkString( "arcbank_comm_delete" )

net.Receive( "arcbank_comm_delete", function(length,ply)
	local ent = net.ReadEntity() --ARCBank_IsAValidDevice
	local accname = tostring(net.ReadString())
	local callback = function(accdata)
		if accdata then
			if ARCBank.PlayerHasAccesToAccount(ply,accdata) then
				--%%CONFIRMATION_HASH%%
				if accdata.money < 0 then
						net.Start("arcbank_comm_delete")
						net.WriteEntity(ent)
						net.WriteInt(ARCBANK_ERROR_DEBT,ARCBANK_ERRORBITRATE)
						net.Send(ply)
				else
					ARCBank.EraseAccount(accdata.filename,accdata.isgroup,function(didwork)
						net.Start("arcbank_comm_delete")
						net.WriteEntity(ent)
						net.WriteInt(ARCBANK_ERROR_WRITE_FAILURE*ARCLib.BoolToNumber(!didwork),ARCBANK_ERRORBITRATE) -- I'm feeling lazy today.
						net.Send(ply)
					end)
				end
			else
				net.Start("arcbank_comm_delete")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		else
			net.Start("arcbank_comm_delete")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_NIL_ACCOUNT,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	end
	if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
		if accname == "" then
			if ARCBank.Settings["account_starting_cash"] > 0 then -- We don't want people closing their personal accounts and reopening them to make free money.
				net.Start("arcbank_comm_delete")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_DELETE_REFUSED,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			else
				ARCBank.ReadAccountFile(ARCBank.GetAccountID(ARCBank.GetPlayerID(ply)),false,callback)
			end
		else
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(accname),true,callback)
		end
	else
		ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
		net.Start("arcbank_comm_delete")
		net.WriteEntity(ent)
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)


-- Upgrade account

util.AddNetworkString( "arcbank_comm_upgrade" )

net.Receive( "arcbank_comm_upgrade", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local writecallback = function(didwork)
		if didwork then
			net.Start("arcbank_comm_upgrade")
			net.WriteEntity(ent)
			net.WriteInt(0,ARCBANK_ERRORBITRATE)
			net.Send(ply)	
		else
			net.Start("arcbank_comm_upgrade")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_WRITE_FAILURE,ARCBANK_ERRORBITRATE)
			net.Send(ply)	
		end
	end
	
	local accname = tostring(net.ReadString())
	
	local callback = function(accdata)
		if accdata then
			if accdata.rank == 4 || accdata.rank >= 7 then
				net.Start("arcbank_comm_upgrade")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_INVALID_RANK,ARCBANK_ERRORBITRATE)
				net.Send(ply)		
			else
				local newb = true
				for k,v in pairs( ARCBank.Settings["usergroup_all"] ) do
					if ply:IsUserGroup( v ) then
						newb = false
					end
				end
				if accdata.isgroup then
					if accdata.owner == ARCBank.GetPlayerID(ply) then
						accdata.rank = accdata.rank + 1	
						for i=accdata.rank,ARCBANK_GROUPACCOUNTS_PREMIUM do
							if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],ply:GetUserGroup()) then
								newb = false
								break
							end
						end
						if newb then
							net.Start("arcbank_comm_upgrade")
							net.WriteEntity(ent)
							net.WriteInt(ARCBANK_ERROR_UNDERLING,ARCBANK_ERRORBITRATE)
							net.Send(ply)		
						else
							ARCBank.WriteAccountFile(accdata,writecallback)	
						end
					else
						net.Start("arcbank_comm_upgrade")
						net.WriteEntity(ent)
						net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
						net.Send(ply)			
					end
				else
					accdata.rank = accdata.rank + 1
					for i=accdata.rank,ARCBANK_PERSONALACCOUNTS_GOLD do
						if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],ply:GetUserGroup()) then
							newb = false
							break
						end
					end
					if newb then
						net.Start("arcbank_comm_upgrade")
						net.WriteEntity(ent)
						net.WriteInt(ARCBANK_ERROR_UNDERLING,ARCBANK_ERRORBITRATE)
						net.Send(ply)		
					else
						ARCBank.WriteAccountFile(accdata,writecallback)	
					end
				end
			end
		else
			
			net.Start("arcbank_comm_upgrade")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_NIL_ACCOUNT,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	end
		
	if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
		if accname == "" then
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(ARCBank.GetPlayerID(ply)),false,callback)
		else
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(accname),true,callback)
		end
	else
		ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
		net.Start("arcbank_comm_upgrade")
		net.WriteEntity(ent)
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)



--Get Log _ARCBank_Log_Place _ARCBank_Log
util.AddNetworkString( "arcbank_comm_log" )
net.Receive( "arcbank_comm_log", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local accname = tostring(net.ReadString())
	if string.StartWith(accname,"RECIEVED DUH FOOKING CHUNK ||||") then
		local progr = string.Explode("/",string.Replace(accname,"RECIEVED DUH FOOKING CHUNK ||||",""))
		if tonumber(progr[2]) == #ply._ARCBank_Log then
			if tonumber(progr[1]) == ply._ARCBank_Log_Place then
				ply._ARCBank_Log_Place = ply._ARCBank_Log_Place + 1
				net.Start("arcbank_comm_log")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_NONE,ARCBANK_ERRORBITRATE)
				net.WriteUInt(ply._ARCBank_Log_Place,32)
				net.WriteUInt(#ply._ARCBank_Log,32)
				net.WriteString(tostring(ply._ARCBank_Log[ply._ARCBank_Log_Place]))
				net.Send(ply)
				if ply._ARCBank_Log_Place == #ply._ARCBank_Log then
					ply._ARCBank_Log = nil
				end
			else
				net.Start("arcbank_comm_log")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		else
			net.Start("arcbank_comm_log")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	else
		--ARCBank.Msgs.ATMMsgs.PersonalAccount
		--ARCBank.GroupAccountAcces(steamid,function(code,lst)
		local lst = ""
		if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
			local thing = function(accdata)
				if accdata then
					if ARCBank.PlayerHasAccesToAccount(ply,accdata) then
						if !lst || lst == "" then 
							lst = ARCBank.Msgs.ATMMsgs.NoLog
						end
						net.Start("arcbank_comm_log")
						net.WriteEntity(ent)
						net.WriteInt(0,ARCBANK_ERRORBITRATE)
						ply._ARCBank_Log = ARCLib.SplitString(string.Right(lst,3276800),16384) -- Splitting the string every 16 kb just in case
						-- TODO: Compress %%CONFIRMATION_HASH%%
						ply._ARCBank_Log_Place = 0
						net.WriteUInt(0,32)
						net.WriteUInt(#ply._ARCBank_Log,32)
						net.WriteString("")
						net.Send(ply)
					else
						net.Start("arcbank_comm_log")
						net.WriteEntity(ent)
						net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
						net.Send(ply)
					end
				else
					net.Start("arcbank_comm_log")
					net.WriteEntity(ent)
					net.WriteInt(ARCBANK_ERROR_NIL_ACCOUNT,ARCBANK_ERRORBITRATE)
					net.Send(ply)
				end
			end
			if !accname || accname == "" then
				lst = file.Read( ARCBank.Dir.."/accounts/personal/logs/"..ARCBank.GetAccountID(ARCBank.GetPlayerID(ply))..".txt","DATA")
				ARCBank.ReadAccountFile(ARCBank.GetAccountID(ARCBank.GetPlayerID(ply)),false,thing)
			else
				lst = file.Read( ARCBank.Dir.."/accounts/group/logs/"..ARCBank.GetAccountID(accname)..".txt","DATA")
				ARCBank.ReadAccountFile(ARCBank.GetAccountID(accname),true,thing)
			end
		else
			ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
			net.Start("arcbank_comm_log")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
		--end)
	end
end)



--Add/Remove player from group

util.AddNetworkString( "arcbank_comm_playergroup" )

net.Receive( "arcbank_comm_playergroup", function(length,ply)
	local ent = net.ReadEntity()--ARCBank_IsAValidDevice
	local accname = tostring(net.ReadString())
	local steamid = tostring(net.ReadString())
	local add = tobool(net.ReadBit())
	
	local callback = function(errcode)
		net.Start("arcbank_comm_playergroup")
		net.WriteEntity(ent)
		net.WriteInt(errcode,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
	if ent.ARCBank_IsAValidDevice && ent.UsePlayer == ply then
		if add then
			ARCBank.AddPlayerToGroup(ply,steamid,accname,callback)
		else
			ARCBank.RemovePlayerFromGroup(ply,steamid,accname,callback)
		end
	else
		ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
		net.Start("arcbank_comm_playergroup")
		net.WriteEntity(ent)
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
	end
end)

---------------------
-- ADMIN FUNCTIONS --
---------------------

--Get Log 
util.AddNetworkString( "arcbank_comm_admin_log" )
net.Receive( "arcbank_comm_admin_log", function(length,ply)
	local accname = tostring(net.ReadString())
	local isgroup = tobool(net.ReadBit())
	if string.StartWith(accname,"RECIEVED DUH FOOKING CHUNK ||||") then
		local progr = string.Explode("/",string.Replace(accname,"RECIEVED DUH FOOKING CHUNK ||||",""))
		if tonumber(progr[2]) == #ply._ARCBank_Admin_Log then
			if tonumber(progr[1]) == ply._ARCBank_Admin_Log_Place then
				ply._ARCBank_Admin_Log_Place = ply._ARCBank_Admin_Log_Place + 1
				net.Start("arcbank_comm_admin_log")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_NONE,ARCBANK_ERRORBITRATE)
				net.WriteUInt(ply._ARCBank_Admin_Log_Place,32)
				net.WriteUInt(#ply._ARCBank_Admin_Log,32)
				net.WriteString(tostring(ply._ARCBank_Admin_Log[ply._ARCBank_Admin_Log_Place]))
				net.Send(ply)
				if ply._ARCBank_Admin_Log_Place == #ply._ARCBank_Admin_Log then
					ply._ARCBank_Admin_Log = nil
				end
			else
				net.Start("arcbank_comm_admin_log")
				net.WriteEntity(ent)
				net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		else
			net.Start("arcbank_comm_admin_log")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	else
		--ARCBank.Msgs.ATMMsgs.PersonalAccount
		--ARCBank.GroupAccountAcces(steamid,function(code,lst)
		
		if ply && ply:IsPlayer() && ((!ARCBank.Settings["superadmin_only"] && ply:IsAdmin()) || ply:IsSuperAdmin()) then
			local lst = ""
			if string.StartWith( accname, "account_" ) then
				if isgroup then
					lst = file.Read( ARCBank.Dir.."/accounts/group/logs/"..accname..".txt","DATA")
				else
					lst = file.Read( ARCBank.Dir.."/accounts/personal/logs/"..accname..".txt","DATA")
				end
			else
				lst = file.Read( ARCBank.Dir.."/"..accname,"DATA")
			end
			
			
			if !lst || lst == "" then 
				lst = ARCBank.Msgs.ATMMsgs.NoLog
			end
			net.Start("arcbank_comm_admin_log")
			net.WriteEntity(ent)
			net.WriteInt(0,ARCBANK_ERRORBITRATE)
			ply._ARCBank_Admin_Log = ARCLib.SplitString(string.Right(lst,3276800),16384) -- Splitting the string every 16 kb just in case
			ply._ARCBank_Admin_Log_Place = 0
			net.WriteUInt(0,32)
			net.WriteUInt(#ply._ARCBank_Admin_Log,32)
			net.WriteString("")
			net.Send(ply)
		else
			net.Start("arcbank_comm_admin_log")
			net.WriteEntity(ent)
			net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
		--end)
	end
end)


--GetAll Accounts
--_ARCBank_AllAccounts_List_Place
--_ARCBank_A
util.AddNetworkString( "arcbank_comm_admin_accounts" )
net.Receive( "arcbank_comm_admin_accounts", function(length,ply)
	local steamid = tostring(net.ReadString())
	if string.StartWith(steamid,"RECIEVED DUH FOOKING CHUNK ||||") then
		local progr = string.Explode("/",string.Replace(steamid,"RECIEVED DUH FOOKING CHUNK ||||",""))
		if tonumber(progr[2]) == #ply._ARCBank_AllAccounts_List then
			if tonumber(progr[1]) == ply._ARCBank_AllAccounts_List_Place then
				ply._ARCBank_AllAccounts_List_Place = ply._ARCBank_AllAccounts_List_Place + 1
				net.Start("arcbank_comm_admin_accounts")
				net.WriteInt(ARCBANK_ERROR_NONE,ARCBANK_ERRORBITRATE)
				net.WriteUInt(ply._ARCBank_AllAccounts_List_Place,32)
				net.WriteUInt(#ply._ARCBank_AllAccounts_List,32)
				net.WriteString(tostring(ply._ARCBank_AllAccounts_List[ply._ARCBank_AllAccounts_List_Place]))
				net.Send(ply)
				if ply._ARCBank_AllAccounts_List_Place == #ply._ARCBank_AllAccounts_List then
					ply._ARCBank_AllAccounts_List = nil
				end
			else
				net.Start("arcbank_comm_admin_accounts")
				net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
				net.Send(ply)
			end
		else
			net.Start("arcbank_comm_admin_accounts")
			net.WriteInt(ARCBANK_ERROR_CHUNK_MISMATCH,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
	else
		if ply && ply:IsPlayer() && ((!ARCBank.Settings["superadmin_only"] && ply:IsAdmin()) || ply:IsSuperAdmin()) then
			ARCBank.GetAllAccountsUnordered(ARCBank.IsMySQLEnabled(),function(code,lst)
				net.Start("arcbank_comm_admin_accounts")
				net.WriteInt(code,ARCBANK_ERRORBITRATE)
				if code == 0 then
					--table.insert(lst,1,ARCBank.Msgs.ATMMsgs.PersonalAccount)
					ply._ARCBank_AllAccounts_List = ARCLib.SplitString(util.TableToJSON(lst),16384) -- Splitting the string every 16 kb just in case
					ply._ARCBank_AllAccounts_List_Place = 0
					net.WriteUInt(0,32)
					net.WriteUInt(#ply._ARCBank_AllAccounts_List,32)
					net.WriteString("")
				end
				net.Send(ply)
			end)
		else
			ARCBank.FuckIdiotPlayer(ply,"Specified entity was not a valid ARCBank entity") 
			net.Start("arcbank_comm_admin_accounts")
			net.WriteInt(ARCBANK_ERROR_NO_ACCESS,ARCBANK_ERRORBITRATE)
			net.Send(ply)
		end
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
		net.WriteEntity(ent)
		net.WriteBit(false)
		net.Send(ply)
		return
	end
	if operation == -1 then
		net.Start("arcbank_comm_secret")
		net.WriteBit(ply.ARCBank_Secrets)
		net.WriteEntity(ent)
		net.Send(ply)
	elseif operation == 0 then
		-- My birthday :)
		if arg == 19970415 && ARCBank.EasterEggs && math.random() < 0.9 then
			ARCBank.MsgCL(ply,"Hello.")
			ply.ARCBank_Secrets = true
			net.Start("arcbank_comm_secret")
			net.WriteBit(true)
			net.WriteEntity(ent)
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
				net.WriteEntity(ent)
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
			net.WriteEntity(ent)
			net.Send(ply)
		else
			net.Start("arcbank_comm_secret")
			net.WriteBit(false)
			net.WriteEntity(ent)
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
			net.WriteEntity(ent)
			net.Send(ply)
		else
			net.Start("arcbank_comm_secret")
			net.WriteBit(false)
			net.WriteEntity(ent)
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

