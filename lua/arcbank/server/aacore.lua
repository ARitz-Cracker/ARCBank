-- aacore.lua - Accounts and File manager

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.

-- You know, I hate it that I have to use a billion callback functions now that SQL was implimented.

ARCBank.LogFileWritten = false
ARCBank.LogFile = ""
ARCBank.Loaded = false
ARCBank.Busy = true
ARCBank.Dir = "_arcbank"
ARCBank.AccountPrefix = "account_"

ARCBank.EasterEggsEnabled = false

ARCBank.Disk = {}
ARCBank.Disk.NommedCards = {}
ARCBank.Disk.EmoPlayers = {}
ARCBank.Disk.BlindPlayers = {}
ARCBank.Disk.OldPlayers = {} 
ARCBank.Disk.ProperShutdown = false

function ARCBankAccountMsg(accountdata,msg)
	if !ARCBank then return end
	if ARCBank.LogFileWritten then
	--accountdata.filename
		local dir = ""
		if accountdata.isgroup then
			dir = ARCBank.Dir.."/accounts/group/logs/"..accountdata.filename..".txt"
		else
			dir = ARCBank.Dir.."/accounts/personal/logs/"..accountdata.filename..".txt"
		end
		if dir != "" then
			file.Append(dir, os.date("%d-%m-%Y %H:%M:%S").." > "..tostring(msg).."\r\n")
		end
	end
end
function ARCBank.FuckIdiotPlayer(ply,reason)
	ARCBank.Msg("ARCBANK ANTI-CHEAT WARNING: Some stupid shit by the name of "..ply:Nick().." ("..ply:SteamID()..") tried to use an exploit: ["..tostring(reason).."]")
	if ply.ARCBank_AFuckingIdiot then
		ply:Ban(ARCBank.Settings["autoban_time"])
		ply:SendLua("Derma_Message( \"You will be autobanned for "..ARCLib.TimeString( ARCBank.Settings["autoban_time"]*60 )..".\", \"You're a failure at hacking\", \"Shit, Looks like I'm an idiot.\" )")
		timer.Simple(10,function()
			if IsValid(ply) && ply:IsPlayer() then 
				ply:Kick("ARCBank Autobanned for "..ARCLib.TimeString( ARCBank.Settings["autoban_time"]*60 ).." - Tried to be a L33T H4X0R ["..tostring(reason).."]") 
			end
		end)
	else
		ARCBank.MsgCL(ply,table.Random({"I fucking swear, you better not try that again.","It's people like you that make my life harder.","I'LL BAN YO' FUCKIN' ASS IF YOU TRY THAT MUTHAFUKIN SHIT AGAIN!","Seriously? Do you really think you can get away with that?"}))
		ply.ARCBank_AFuckingIdiot = true
	end
end

function ARCBank.SaveDisk()
	ARCBank.Disk.ProperShutdown = true
	file.Write(ARCBank.Dir.."/__data.txt", util.TableToJSON(ARCBank.Disk) )
end



function ARCBank.GetAccountID(name)
	return ARCBank.AccountPrefix..string.lower(string.gsub(name, "[^_%w]", "_"))
end
function ARCBank.IsMySQLEnabled()
	return ARCBank.MySQL && ARCBank.MySQL.EnableMySQL 
end



function ARCBank.WriteAccountFile(accounttable,callback)
	if !ARCBank.Loaded || !accounttable.filename || !accounttable.rank || accounttable.rank <= ARCBANK_PERSONALACCOUNTS_ || accounttable.rank == ARCBANK_GROUPACCOUNTS_ || accounttable.rank > ARCBANK_GROUPACCOUNTS_PREMIUM then return false end
	accounttable.money = tostring(accounttable.money) -- Just in case!
	if ARCBank.IsMySQLEnabled() then -- Doing messy calculations in Lua to make things optimized for SQL..
	--How ironic, making things dirty to make others clean. I guess some things requires balancem then
		local qCallBack = function(didwork,data)
			if didwork == nil then
				data = {}
				didwork = true
			elseif istable(didwork) then
				data = didwork
				didwork = true
			end
			
			
			
			if didwork then
				local writeCallback = function(didw,dataa)
					callback(didw)
				end
				
				local gWriteCallback = function(didw,dataa)
					if didw then
						local tempa = {}
						local i = 1
						for k,v in pairs(accounttable.members) do
							if !table.HasValue(data.members,v) then
								--v
								tempa[i] = "INSERT INTO arcbank_account_members (filename,steamid) VALUES ('"..accounttable.filename.."','"..v.."')"
								i = i + 1
							end
						end
						if #tempa == 0 then
							callback(true)
						else
							local ii = 1
							local function recrusivecopy(num)
								if num > #tempa then 
										--FINISH THIS
										local onemorething = false
										local tempb = ""
										for k,v in pairs(data.members) do
											if !table.HasValue(accounttable.members,v) then
												onemorething = true
												if tempb == "" then
													tempb = "DELETE FROM arcbank_account_members WHERE filename = '"..accounttable.filename.."' AND (steamid = '"..v.."'"
												else
													tempb = "OR steamid = '"..v.."'"
												end
											end
										end
										if tempb == "" then
											callback(true)
										else
											ARCBank.MySQL.Query(tempb..");",function(didwork,reason)
												callback(didwork)
											end)
										end
									return 
								end
								ARCBank.MySQL.Query(tempa[num],function(didwork,reason)
									if didwork then
										ii = ii + 1
										recrusivecopy(ii)
									else
										callback(false)
									end
								end)
							end
							recrusivecopy(ii)
						end
					else
						callback(false)
					end
				end
				if accounttable.isgroup then
					if !data.filename then
						ARCBank.MySQL.Query("INSERT INTO arcbank_group_account (filename, isgroup, name, owner, money, rank) VALUES ('"..tostring(accounttable.filename).."',"..tostring(accounttable.isgroup)..",'"..ARCBank.MySQL.Escape(tostring(accounttable.name)).."','"..tostring(accounttable.owner).."',"..accounttable.money..","..tostring(accounttable.rank).."); ",gWriteCallback)
					else
						ARCBank.MySQL.Query("UPDATE arcbank_group_account SET money="..accounttable.money..", rank="..tostring(accounttable.rank).." WHERE filename='"..tostring(accounttable.filename).."';",gWriteCallback)
					end
				else
					if !data.filename then
						ARCBank.MySQL.Query("INSERT INTO arcbank_personal_account (filename, isgroup, name, money, rank) VALUES ('"..tostring(accounttable.filename).."',"..tostring(accounttable.isgroup)..",'"..ARCBank.MySQL.Escape(tostring(accounttable.name)).."',"..tonumber(accounttable.money)..","..tostring(accounttable.rank).."); ",writeCallback)
					else
						ARCBank.MySQL.Query("UPDATE arcbank_personal_account SET name='"..ARCBank.MySQL.Escape(accounttable.name).."', money="..accounttable.money..", rank="..tostring(accounttable.rank).." WHERE filename='"..tostring(accounttable.filename).."';",writeCallback)
					end
				end
			else
				callback(false)
			end
		end
		ARCBank.ReadAccountFile(accounttable.filename,accounttable.isgroup,qCallBack)
	else
		--ARCBank.Dir.."/personal_account/"  
		if accounttable.isgroup then
			file.Write( ARCBank.Dir.."/accounts/group/"..accounttable.filename..".txt", util.TableToJSON(accounttable) )
			timer.Simple(0.01, function() callback(file.Exists(ARCBank.Dir.."/accounts/group/"..accounttable.filename..".txt","DATA")) end)
		else
			file.Write( ARCBank.Dir.."/accounts/personal/"..accounttable.filename..".txt", util.TableToJSON(accounttable) )
			timer.Simple(0.01, function() callback(file.Exists(ARCBank.Dir.."/accounts/personal/"..accounttable.filename..".txt","DATA")) end)
		end
	end
end


function ARCBank.ReadAccountFile(name,isgroup,callback)
	if !ARCBank.Loaded then callback(false) return end
	if ARCBank.IsMySQLEnabled() then
		local qOnSuccess = function(didwork,data)
			if didwork then
				if #data == 0 then
					callback(nil)
				else
					data[1].money = tonumber(data[1].money)
					data[1].isgroup = tobool(data[1].isgroup)
					if data[1].isgroup then
						ARCBank.MySQL.Query("SELECT * FROM arcbank_account_members WHERE filename='"..name.."';",function(didwork,ddata)
							if didwork then
								data[1].members = {}
								if #ddata > 0 then
									for k,v in pairs(ddata) do
										data[1].members[k] = v.steamid
									end
								end
								callback(data[1])
							else
								callback(false)
							end
						end)
					else
						callback(data[1])
					end
				end
			else
				callback(false)
			end
		end
		if isgroup then
			--MsgN("SELECT FROM GROUP ACCOUNT")
			ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account WHERE filename='"..name.."';",qOnSuccess)
		else
			--MsgN("SELECT FROM PERSONAL ACCOUNT")
			ARCBank.MySQL.Query("SELECT * FROM arcbank_personal_account WHERE filename='"..name.."';",qOnSuccess)
		end
	else
		local data = ""
		if isgroup then
			data = file.Read( ARCBank.Dir.."/accounts/group/"..tostring(name)..".txt","DATA")
		else
			data = file.Read( ARCBank.Dir.."/accounts/personal/"..tostring(name)..".txt","DATA")
		end
		if !data || data == "" then 
			timer.Simple(0.01, function() callback(nil) end)
		else
			local tab = util.JSONToTable(data)
			if tab then
				tab.money = tonumber(tab.money)
			end
			timer.Simple(0.01, function() callback(tab) end)
		end
	end
end
function ARCBank.AccountExists(name,isgroup,callback)
	if !ARCBank.Loaded then callback(false) return end
	if ARCBank.IsMySQLEnabled() then
		local qOnSuccess = function(didwork,data)
			if didwork then
				if #data == 0 then
					callback(false)
				else
					callback(true)
				end
			else
				callback(false)
			end
		end
		if isgroup then
			ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account WHERE filename='"..name.."';",qOnSuccess)
		else
			ARCBank.MySQL.Query("SELECT * FROM arcbank_personal_account WHERE filename='"..name.."';",qOnSuccess)
		end
	else
		if isgroup then
			timer.Simple(0.01, function() callback(file.Exists(ARCBank.Dir.."/accounts/group/"..name..".txt","DATA")) end)
		else
			timer.Simple(0.01, function() callback(file.Exists(ARCBank.Dir.."/accounts/personal/"..name..".txt","DATA")) end)
		end
	end
end
function ARCBank.EraseAccount(name,isgroup,callback)
	if !ARCBank.Loaded then callback(false) return end
	if ARCBank.IsMySQLEnabled() then
		local qOnDidIt = function(didwork,data) 
			callback(didwork)
		end
		if isgroup then
			ARCBank.MySQL.Query("DELETE FROM arcbank_account_members WHERE filename='"..name.."';",function(didwork,data)
				if didwork then
					ARCBank.MySQL.Query("DELETE FROM arcbank_group_account WHERE filename='"..name.."';",qOnDidIt)
				else
					callback(false)
				end
			end)
		else
			ARCBank.MySQL.Query("DELETE FROM arcbank_personal_account WHERE filename='"..name.."';",qOnDidIt)
		end
	else
		if isgroup then
			file.Delete( ARCBank.Dir.."/accounts/group/"..name..".txt")
			timer.Simple(0.01, function() callback(!file.Exists(ARCBank.Dir.."/accounts/group/"..name..".txt","DATA")) end)
		else
			file.Delete( ARCBank.Dir.."/accounts/personal/"..name..".txt")
			timer.Simple(0.01, function() callback(!file.Exists(ARCBank.Dir.."/accounts/personal/"..name..".txt","DATA")) end)
		end
	end
end
function ARCBank.GetLogTable(name,isgroup)
	if isgroup then
		return ARCBank.ReadFileTable( ARCBank.Dir.."/accounts/group/logs/"..name..".txt")
	else
		return ARCBank.ReadFileTable( ARCBank.Dir.."/accounts/personal/logs/"..name..".txt")
	end
end
function ARCBank.ReadFileTable(dir)
	if !ARCBank.Loaded then return {"**ARCBank File Viewer Error**","","System didn't load properly!"} end
	
	if file.Exists( dir,"DATA" ) then
		local shit = string.Explode( "\n", file.Read( dir,"DATA" ) )
		table.remove(shit)
		return shit
	else
		return {"**ARCBank File Viewer Error**","","Requested File: "..dir,"","File doesn't exist!"}
	end
end

function ARCBank.MaxAccountRank(ply,group)
	if group then
		local result = ARCBANK_GROUPACCOUNTS_
		
		for k,v in pairs( ARCBank.Settings["everything_requirement"] ) do
			if ply:IsUserGroup( v ) then
				result = ARCBANK_GROUPACCOUNTS_PREMIUM
				break
			end
		end
		if result>ARCBANK_GROUPACCOUNTS_ then return result end
		for i=ARCBANK_GROUPACCOUNTS_STANDARD,ARCBANK_GROUPACCOUNTS_PREMIUM do
			for k,v in pairs( ARCBank.Settings[""..ARCBANK_ACCOUNTSTRINGS[i].."_requirement"] ) do
				if ply:IsUserGroup( v ) then
					result = i
					break
				end
			end
		end
		return result
	else
		local result = ARCBANK_PERSONALACCOUNTS_
		for k,v in pairs( ARCBank.Settings["everything_requirement"] ) do
			if ply:IsUserGroup( v ) then
				result = ARCBANK_PERSONALACCOUNTS_GOLD
				break
			end
		end
		if result>ARCBANK_PERSONALACCOUNTS_ then return result end
		for i=ARCBANK_PERSONALACCOUNTS_STANDARD,ARCBANK_PERSONALACCOUNTS_GOLD do
			for k,v in pairs( ARCBank.Settings[""..ARCBANK_ACCOUNTSTRINGS[i].."_requirement"] ) do
				if ply:IsUserGroup( v ) then
					result = i
					break
				end
			end
		end
		return result
	end
	
end

function ARCBank.CreateAccount(ply,rank,initbalance,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local newb = true
	for k,v in pairs( ARCBank.Settings["everything_requirement"] ) do
		if ply:IsUserGroup( v ) then
			newb = false
		end
	end
	if newb then
		if rank < ARCBANK_GROUPACCOUNTS_ then
			for i=rank,ARCBANK_PERSONALACCOUNTS_GOLD do
				if table.HasValue(ARCBank.Settings[""..ARCBANK_ACCOUNTSTRINGS[i].."_requirement"],ply:GetUserGroup()) then
					newb = false
					break
				end
			end
		else
			for i=rank,ARCBANK_GROUPACCOUNTS_PREMIUM do
				if table.HasValue(ARCBank.Settings[""..ARCBANK_ACCOUNTSTRINGS[i].."_requirement"],ply:GetUserGroup()) then
					newb = false
					break
				end
			end
		end
	end
	if newb then callback(ARCBANK_ERROR_UNDERLING) return end
	
	if rank > ARCBANK_GROUPACCOUNTS_PREMIUM then
		callback(ARCBANK_ERROR_INVALID_RANK)
		return
	end
	
	
	local accountdata = {}
	if !groupname || groupname == "" then
		if rank <= 0 then
			callback(ARCBANK_ERROR_INVALID_RANK)
			return
		end
		accountdata.isgroup = false
		accountdata.filename = ARCBank.GetAccountID(ply:SteamID())
		accountdata.name = ply:Nick()
		accountdata.money = tostring(initbalance)
		accountdata.rank = rank
	else
		if rank <= ARCBANK_GROUPACCOUNTS_ then
			callback(ARCBANK_ERROR_INVALID_RANK)
			return
		end
		accountdata.isgroup = true
		accountdata.filename = ARCBank.GetAccountID(groupname)
		accountdata.name = groupname
		accountdata.money = tostring(initbalance)
		accountdata.rank = rank
		accountdata.owner = ply:SteamID()
		accountdata.members = {}
	end
	
	ARCBank.AccountExists(accountdata.filename,accountdata.isgroup,function(yes)
		if yes then
			callback(ARCBANK_ERROR_NAME_DUPE)
		else
			ARCBank.WriteAccountFile(accountdata,function(didwrite)
				if didwrite then
					ARCBank.Msg(ply:Nick().."("..ply:SteamID()..") ceated an account named "..accountdata.name.." with "..initbalance.." munnies")
					ARCBankAccountMsg(accountdata,"Account Created/Reset!")
					callback(ARCBANK_ERROR_NONE)
				else
					callback(ARCBANK_ERROR_WRITE_FAILURE)
				end
			end)
		end
	end)
end
function ARCBank.AddAccountInterest()
	if !ARCBank.Loaded then return end
	if ARCBank.Busy then return end
	if !ARCBank.Settings["interest_enable"] then return end
	ARCBank.Msg("Giving out bank interest...")
	if ARCBank.IsMySQLEnabled() then
		if ARCBank.Settings["perpetual_debt"] then
			for i=1,4 do -- Ahhh so clean...
				ARCBank.MySQL.Query("UPDATE arcbank_personal_account SET money=money*"..tostring(1+(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[i].."_interest"]/100)).." WHERE rank="..tostring(i).." AND money>"..tostring(-ARCBank.Settings["debt_limit"])..";",function(didwork) if (didwork) then ARCBank.Msg("Personal account interest complete for rank "..i.."!") end end)
			end
			for i= 6,7 do
				ARCBank.MySQL.Query("UPDATE arcbank_group_account SET money=money*"..tostring(1+(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[i].."_interest"]/100)).." WHERE rank="..tostring(i).." AND money>"..tostring(-ARCBank.Settings["debt_limit"])..";",function(didwork) if (didwork) then ARCBank.Msg("Group account interest complete for rank "..i.."!") end end)
			end
		else
			for i=1,4 do -- Ahhh so clean...
				ARCBank.MySQL.Query("UPDATE arcbank_personal_account SET money=money*"..tostring(1+(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[i].."_interest"]/100)).." WHERE rank="..tostring(i).." AND money>0;",function(didwork) if (didwork) then ARCBank.Msg("Personal account interest complete for rank "..i.."!") end end)
			end
			for i= 6,7 do
				ARCBank.MySQL.Query("UPDATE arcbank_group_account SET money=money*"..tostring(1+(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[i].."_interest"]/100)).." WHERE rank="..tostring(i).." AND money>0;",function(didwork) if (didwork) then ARCBank.Msg("Group account interest complete for rank "..i.."!") end end)
			end
		end
	else -- Why did I do it this way? Apperently some servers have over 9000 accounts. (Literally) Doing this in a for loop would cause the server to freeze for a bit.
		for k,v in pairs(file.Find(ARCBank.Dir.."/accounts/personal/*.txt","DATA")) do
			--ARCBank.Dir.."/accounts/personal/*.txt" 
			ARCBank.ReadAccountFile(string.Replace(v,".txt",""),false,function(accdata)
				accdata.money = math.floor(accdata.money*(1+(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[accdata.rank].."_interest"]/100)))
				if accdata.money > 1e14 then
					accdata.money = 1e14
				end
				if (accdata.money > 0 || (accdata.money < 0 && ARCBank.Settings["perpetual_debt"])) then
					if accdata.money < -ARCBank.Settings["debt_limit"] then
						accdata.money = -ARCBank.Settings["debt_limit"]
					end
					ARCBank.WriteAccountFile(accdata,function(wop) end)
					ARCBankAccountMsg(accdata,string.Replace( ARCBank.Msgs.LogMsgs.Interest, "%VALUE%", tostring(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[accdata.rank].."_interest"]) ).."("..accdata.money..")")
				end
			end)
		end
		for k,v in pairs(file.Find(ARCBank.Dir.."/accounts/group/*.txt","DATA")) do
		--ARCBank.Dir.."/accounts/group/*.txt" 
			ARCBank.ReadAccountFile(string.Replace(v,".txt",""),true,function(accdata)
				accdata.money = math.floor(accdata.money*(1+(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[accdata.rank].."_interest"]/100)))
				if accdata.money > 1e14 then
					accdata.money = 1e14
				end
				
				if (accdata.money > 0 || (accdata.money < 0 && ARCBank.Settings["perpetual_debt"])) then
					if accdata.money < -ARCBank.Settings["debt_limit"] then
						accdata.money = -ARCBank.Settings["debt_limit"]
					end
					ARCBank.WriteAccountFile(accdata,function(wop) end)
					ARCBankAccountMsg(accdata,string.Replace( ARCBank.Msgs.LogMsgs.Interest, "%VALUE%", tostring(ARCBank.Settings[ARCBANK_ACCOUNTSTRINGS[accdata.rank].."_interest"]) ).."("..accdata.money..")")
				end
			end)
		end
	end
	
end

function ARCBank.RemoveAccount(ply,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local datafunc = function(accountdata)
		if !accountdata then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdata.isgroup && accountdata.owner != ply:SteamID() then
			callback(ARCBANK_ERROR_NO_ACCESS)
			return
		end
		if accountdata.money < 0 then
			callback(ARCBANK_ERROR_DEBT)
			return
		end
		if !accountdata.isgroup && ARCBank.Settings["starting_cash"] > 0 then
			callback(ARCBANK_ERROR_DELETE_REFUSED)
			return
		end
		ARCBank.EraseAccount(accountdata.filename,accountdata.isgroup,function(yes)
			if yes then
				ARCBank.Msg(ply:Nick().."("..ply:SteamID()..") closed their account named "..accountdata.name.." ("..accountdata.filename..")")
				callback(ARCBANK_ERROR_NONE)
			else
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			end
	
		end)
	end

	if !groupname || groupname == "" then
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(ply:SteamID()),false,datafunc)
	else
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(groupname),true,datafunc)
	end
end

function ARCBank.AddPlayerToGroup(ply,newguysteamid,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end

	ARCBank.ReadAccountFile(ARCBank.GetAccountID(groupname),true,function(accountdata)
		if !accountdata then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdata.owner != ply:SteamID() then
			callback(ARCBANK_ERROR_NO_ACCESS)
			return
		end
		--MsgN("LINE 476 OF CORE!")
		if table.HasValue(accountdata.members,newguysteamid) || newguysteamid == ply:SteamID() then
			callback(ARCBANK_ERROR_DUPE_PLAYER)
			return
		end
		if #accountdata.members > 50 then
			callback(ARCBANK_ERROR_TOO_MANY_PLAYERS)
			return
		end
		table.insert( accountdata.members, newguysteamid )
		ARCBank.WriteAccountFile(accountdata,function(yes)
			if yes then
				ARCBankAccountMsg(accountdata,string.Replace( ARCBank.Msgs.LogMsgs.AddUser, "%PLAYER%",newguysteamid ))
				callback(ARCBANK_ERROR_NONE)
			else
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			end
		end)
	
	end)
	
	
end


function ARCBank.RemovePlayerFromGroup(ply,guysteamid,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	
	
	ARCBank.ReadAccountFile(ARCBank.GetAccountID(groupname),true,function(accountdata)
		if !accountdata then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdata.owner != ply:SteamID() then
			callback(ARCBANK_ERROR_NO_ACCESS)
			return
		end
		if !table.HasValue(accountdata.members,guysteamid) then
			callback(ARCBANK_ERROR_NIL_PLAYER)
			return
		end
		table.RemoveByValue( accountdata.members, guysteamid )
		ARCBank.WriteAccountFile(accountdata,function(yes)
			if yes then
				ARCBankAccountMsg(accountdata,string.Replace( ARCBank.Msgs.LogMsgs.RemoveUser, "%PLAYER%",guysteamid ))
				callback(ARCBANK_ERROR_NONE)
			else
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			end
		end)
	end)
end

function ARCBank.GroupAccountOwner(ply,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED,{}) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY,{}) return end
	local sid = ""
	if !isstring(ply)&& ply:IsPlayer() then
		sid = ply:SteamID()
	elseif string.StartWith(ply,"STEAM_") then
		sid = ply
	else
		callback(ARCBANK_ERROR_NIL_PLAYER,{}) 
		return
	end
	local names = {}
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account WHERE owner='"..sid.."';",function(didwork,data)
			if didwork then
				for _,accountdata in pairs(data) do
					if accountdata.owner == sid then
						table.insert( names, accountdata.name )
					end
				end
				callback(ARCBANK_ERROR_NONE,names) 
			else
				callback(ARCBANK_ERROR_READ_FAILURE,{})
			end
		end)
	else
		local files, directories = file.Find( ARCBank.Dir.."/accounts/group/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/group/"..v,"DATA" ))
			if accountdata.owner == sid then
				table.insert( names, accountdata.name )
			end
		end
		callback(ARCBANK_ERROR_NONE,names) 
	end
	
end

function ARCBank.GroupAccountAcces(ply,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED,{}) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY,{}) return end
	local sid = ""
	if !isstring(ply)&& ply:IsPlayer() then
		sid = ply:SteamID()
	elseif string.StartWith(ply,"STEAM_") then
		sid = ply
	else
		callback(ARCBANK_ERROR_NIL_PLAYER,{}) 
		return
	end
	local names = {}
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account;",function(didwork,data)
			if didwork then
				ARCBank.MySQL.Query("SELECT * FROM arcbank_account_members;",function(ddidwork,ddata)
					if ddidwork then
						for _,accountdata in pairs(data) do
							accountdata.members = {}
							if #ddata > 0 then
								for k,v in pairs(ddata) do
									if v.filename == accountdata.filename then
										table.insert( accountdata.members, v.steamid )
									end
								end
							end
							if accountdata.owner == sid || table.HasValue( accountdata.members, sid ) then
								table.insert( names, accountdata.name )
							end
						end
						callback(ARCBANK_ERROR_NONE,names) 
					else
						callback(ARCBANK_ERROR_READ_FAILURE,{})
					end
				end)
				
			else
				callback(ARCBANK_ERROR_READ_FAILURE,{})
			end
		end)
	else
	
		local files, directories = file.Find( ARCBank.Dir.."/accounts/group/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/group/"..v,"DATA" ))
			if accountdata.owner == sid || table.HasValue( accountdata.members, sid ) then
				table.insert( names, accountdata.name )
			end
		end
		callback(ARCBANK_ERROR_NONE,names) 
	end
	
end

function ARCBank.GetAccountInformation(ply,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sid = ""
	if !isstring(ply)&& ply:IsPlayer() then
		sid = ply:SteamID()
	elseif string.StartWith(ply,"STEAM_") then
		sid = ply
	else
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return 
	end
	local datafunc = function(accountdata)
		if !accountdata then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdata.isgroup && accountdata.owner != sid && !table.HasValue( accountdata.members, sid ) then
			callback(ARCBANK_ERROR_NO_ACCESS)
			return 
		end
		callback(ARCBANK_ERROR_NONE,accountdata)
	end
	if !groupname || groupname == "" then
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(sid),false,datafunc)
	else
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(groupname),true,datafunc)
	end
end

function ARCBank.CanAfford(ply,amount,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sid = ""
	if !isstring(ply)&& ply:IsPlayer() then
		sid = ply:SteamID()
	elseif string.StartWith(ply,"STEAM_") then
		sid = ply
	else
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return 
	end
	local datafunc = function(accountdata)
		if !accountdata then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdata.isgroup && accountdata.owner != sid && !table.HasValue( accountdata.members, sid ) then
			callback(ARCBANK_ERROR_NO_ACCESS)
			return 
		end

		if accountdata.money+ARCBank.Settings["debt_limit"] < amount then
			 callback(ARCBANK_ERROR_NO_CASH)
			 return
		end
		callback(ARCBANK_ERROR_NONE)
	end
	if !groupname || groupname == "" then
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(sid),false,datafunc)
	else
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(groupname),true,datafunc)
	end
	
	
end

--
function ARCBank.PlayerHasAccesToAccount(ply,accounttable)
	if accounttable.isgroup then
		return accounttable.owner == ply:SteamID() || table.HasValue( accounttable.members, ply:SteamID() ) 
	else
		return accounttable.filename == ARCBank.GetAccountID(ply:SteamID())
	end
end
function ARCBank.GetAllAccounts(amount,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED,{}) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY,{}) return end
	local pers = {}
	pers[1] = {}
	pers[2] = {}
	pers[3] = {}
	pers[4] = {}
	pers[6] = {}
	pers[7] = {}
	--accountdata.rank
	local accounts = {}
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account",function(didwork,data)
			
			if didwork then -- Even I cry when I read the next few lines of code.
				for _, accountdata in pairs( data ) do
					accountdata.money = tonumber(accountdata.money)
					if accountdata.money >= amount then
						table.insert( pers[accountdata.rank], accountdata )
					end
				end
				
				
				
				
				
				ARCBank.MySQL.Query("SELECT * FROM arcbank_account_members;",function(ddidwork,ddata)
					if ddidwork then
						for _,accountdata in pairs(data) do
							accountdata.members = {}
							if #ddata > 0 then
								for k,v in pairs(ddata) do
									if v.filename == accountdata.filename then
										table.insert( accountdata.members, v.steamid )
									end
								end
							end
							accountdata.isgroup = tobool(accountdata.isgroup)
							
							--[[
							if accountdata.owner == sid || table.HasValue( accountdata.members, sid ) then
								table.insert( names, accountdata.name )
							end
							]]
							--for _, accountdata in pairs( data ) do
							table.insert( accounts, accountdata )
							--end
							
						end
						
						ARCBank.MySQL.Query("SELECT * FROM arcbank_personal_account",function(diditworkk,pdata)
							if diditworkk then
								for _, accounttdata in pairs( pdata ) do
									accounttdata.money = tonumber(accounttdata.money)
									if accounttdata.money >= amount then
										accounttdata.isgroup = tobool(accounttdata.isgroup)
										table.insert( pers[accounttdata.rank], accounttdata )
									end
								end
								
								for k,v in pairs(pers[1]) do -- These orders are important... Trust me, I wish they were not.
									table.insert(accounts,v)	
								end
								for k,v in pairs(pers[2]) do
									table.insert(accounts,v)	
								end
								for k,v in pairs(pers[6]) do
									table.insert(accounts,v)	
								end
								for k,v in pairs(pers[3]) do
									table.insert(accounts,v)	
								end
								for k,v in pairs(pers[4]) do
									table.insert(accounts,v)	
								end
								for k,v in pairs(pers[7]) do
									table.insert(accounts,v)	
								end
								if #accounts == 0 then
									callback(ARCBANK_ERROR_NO_CASH,accounts)
								else
									callback(ARCBANK_ERROR_NONE,accounts)
								end
							else
								callback(ARCBANK_ERROR_READ_FAILURE,{})
							end
						end)
					else
						callback(ARCBANK_ERROR_READ_FAILURE,{})
					end
				end)
			else
				callback(ARCBANK_ERROR_READ_FAILURE,{})
			end
		end)
	else
		local files, directories = file.Find( ARCBank.Dir.."/accounts/group/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/group/"..v,"DATA"))
			if tonumber(accountdata.money) >= amount then
				table.insert( pers[accountdata.rank], accountdata )
			end
		end
		local files, directories = file.Find( ARCBank.Dir.."/accounts/personal/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/personal/"..v,"DATA"))
			if tonumber(accountdata.money) >= amount then
				table.insert( pers[accountdata.rank], accountdata )
			end
		end
		

		for k,v in pairs(pers[1]) do -- These orders are important... Trust me, I wish they were not.
			table.insert(accounts,v)	
		end
		for k,v in pairs(pers[2]) do
			table.insert(accounts,v)	
		end
		for k,v in pairs(pers[6]) do
			table.insert(accounts,v)	
		end
		for k,v in pairs(pers[3]) do
			table.insert(accounts,v)	
		end
		for k,v in pairs(pers[4]) do
			table.insert(accounts,v)	
		end
		for k,v in pairs(pers[7]) do
			table.insert(accounts,v)	
		end
		if #accounts == 0 then
			callback(ARCBANK_ERROR_NO_CASH,accounts)
		else
			callback(ARCBANK_ERROR_NONE,accounts)
		end
	end
	
end
function ARCBank.GetAllAccountsUnordered(usesql,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED,{}) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY,{}) return end
	--accountdata.rank
	local accounts = {}
	if usesql then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account",function(didwork,data)
			if didwork then -- Even I cry when I read the next few lines of code... although not as much
			
			
			
			

				ARCBank.MySQL.Query("SELECT * FROM arcbank_account_members;",function(ddidwork,ddata)
					if ddidwork then
						for _,accountdata in pairs(data) do
							accountdata.members = {}
							if #ddata > 0 then
								for k,v in pairs(ddata) do
									if v.filename == accountdata.filename then
										table.insert( accountdata.members, v.steamid )
									end
								end
							end
							accountdata.money = tonumber(accountdata.money)
							accountdata.isgroup = tobool(accountdata.isgroup)
							
							--[[
							if accountdata.owner == sid || table.HasValue( accountdata.members, sid ) then
								table.insert( names, accountdata.name )
							end
							]]
							--for _, accountdata in pairs( data ) do
							table.insert( accounts, accountdata )
							--end
							
						end
						
						ARCBank.MySQL.Query("SELECT * FROM arcbank_personal_account",function(diditworkk,pdata)
							if diditworkk then
								for _, accounttdata in pairs( pdata ) do
									accounttdata.money = tonumber(accounttdata.money)
									accounttdata.isgroup = tobool(accounttdata.isgroup)
									table.insert( accounts, accounttdata )
								end
								callback(ARCBANK_ERROR_NONE,accounts)
							else
								callback(ARCBANK_ERROR_READ_FAILURE,{})
							end
						end)
						
					else
						callback(ARCBANK_ERROR_READ_FAILURE,{})
					end
				end)
			else
				callback(ARCBANK_ERROR_READ_FAILURE,{})
			end
			
		end)
	else
		local files, directories = file.Find( ARCBank.Dir.."/accounts/group/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/group/"..v,"DATA"))
			table.insert(accounts, accountdata )
		end
		local files, directories = file.Find( ARCBank.Dir.."/accounts/personal/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/personal/"..v,"DATA"))
			table.insert(accounts, accountdata )
		end
		callback(ARCBANK_ERROR_NONE,accounts)
	end
end

function ARCBank.PlayerAddMoney(ply,amount)
	if string.lower(GAMEMODE.Name) == "gmod day-z" then
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
	if string.lower(GAMEMODE.Name) == "gmod day-z" then
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

function ARCBank.AddMoney(ply,amount,groupaccount,reason,callback)
	ARCBank.CanAfford(ply,-amount,groupaccount,function(errc)
		if errc == ARCBANK_ERROR_NONE then
			if !isstring(ply) && ply:IsPlayer() then
				sid = ply:SteamID()
			elseif string.StartWith(ply,"STEAM_") then
				sid = ply
			else
				callback(ARCBANK_ERROR_NIL_PLAYER)
				return
			end
			local acc = groupaccount
			if acc == "" then
				acc = sid
			end
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(acc),groupaccount != "",function(accountdata)
				if accountdata then
					accountdata.money = accountdata.money + amount
					ARCBank.WriteAccountFile(accountdata,function(diditwork) 
						if diditwork then
							callback(ARCBANK_ERROR_NONE)
							if reason == "" then
								reason = "No reason specified"
							end
							if amount > 0 then
								ARCBankAccountMsg(accountdata,string.Replace( string.Replace( ARCBank.Msgs.LogMsgs.AddMoney, "%VALUE%", tostring(amount)), "%PLAYER%", ply:SteamID()).."["..tostring(reason).."]")
							else
								ARCBankAccountMsg(accountdata,string.Replace( string.Replace( ARCBank.Msgs.LogMsgs.RemoveMoney, "%VALUE%", tostring(-amount)), "%PLAYER%", ply:SteamID()).."["..tostring(reason).."]")
							end
						else
							callback(ARCBANK_ERROR_WRITE_FAILURE)
						end
					end)
				else
					callback(ARCBANK_ERROR_NIL_ACCOUNT)
				end
			end) 
		else
			callback(errc)
		end
	end)
end
function ARCBank.StealMoney(ply,amount,accounttable,hidden,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED,0) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY,0) return end
	if accounttable == "*STEAL FROM MULTIPLE ACCOUNTS!!*" then
		ARCBank.GetAllAccounts(amount,function(err,accounts)
			if err == 0 then
				local money = 0
				local victims = {}

				for i=1,math.floor(amount/5) do
					for ii=1,#accounts do
						local acc = accounts[ARCLib.RandomExp(1,#accounts)]
						if !victims[acc.filename] then
							acc.money = acc.money - 5
							victims[acc.filename] = acc
						else
							victims[acc.filename].money = victims[acc.filename].money - 5
						end
					end
				end
				if ARCBank.IsMySQLEnabled() then --TODO: Read minidump #%%CONFIRMATION_HASH%%. Could hold the key to some issues lag issues.
					local fuckinglongqueryies = {}
					local count = 1
					for k,v in pairs(victims) do
						if fuckinglongqueryies[count] then
							count = count + 1
						end
						if !fuckinglongqueryies[count] then
							fuckinglongqueryies[count] = ""
						end
						if v.isgroup then
							fuckinglongqueryies[count] = fuckinglongqueryies[count].."UPDATE arcbank_group_account SET money="..v.money.." WHERE filename='"..k.."';"
						else
							fuckinglongqueryies[count] = fuckinglongqueryies[count].."UPDATE arcbank_personal_account SET money="..v.money.." WHERE filename='"..k.."';"
						end
					end
					
					local iii = 1
					local function recrusivecopy(num)
						if num > #fuckinglongqueryies then 
							callback(ARCBANK_ERROR_NONE,1)
							if IsValid(ply) then
								ARCBank.Msg(ply:Nick().."("..ply:SteamID()..") performed a distributed hack. All accounts were affected. Stole a total of "..tostring(amount))
							else
								ARCBank.Msg("(Someone) performed a distributed hack. All accounts were affected. Stole a total of "..tostring(amount))
							end
							--ARCBank.PlayerAddMoney(ply,amount)
							return 
						end
						ARCBank.MySQL.Query(fuckinglongqueryies[num],function(didwork,reason)
							if didwork then
								iii = iii + 1
								recrusivecopy(iii)
								callback(ARCBANK_ERROR_DOWNLOADING,math.floor((num/#fuckinglongqueryies)*100))
							else
								callback(ARCBANK_ERROR_WRITE_FAILURE,0)
							end
						end)
					end
					recrusivecopy(iii)
				else
					for k,v in pairs(victims) do
						v.money = tostring(v.money)
						if v.isgroup then
							file.Write( ARCBank.Dir.."/accounts/group/"..k..".txt", util.TableToJSON(v) )
						else
							file.Write( ARCBank.Dir.."/accounts/personal/"..k..".txt", util.TableToJSON(v) )
						end
					end
					timer.Simple(math.random(0.5,5),function() callback(ARCBANK_ERROR_NONE,1) end)
					if IsValid(ply) then
						ARCBank.Msg(ply:Nick().."("..ply:SteamID()..") performed a distributed hack. All accounts were affected. Stole a total of "..tostring(amount))
					else
						ARCBank.Msg("(Someone) performed a distributed hack. All accounts were affected. Stole a total of "..tostring(amount))
					end
					
					--ARCBank.PlayerAddMoney(ply,amount)
				end
			else
				callback(err)
			end
		end)
		
	else
		--ARCBank.ReadAccountFile(accounttable.filename,accounttable.isgroup,function(accountdata)
			if !accounttable then
				callback(ARCBANK_ERROR_READ_FAILURE,0)
				return
			end
			accounttable.money = accounttable.money - amount
			ARCBank.WriteAccountFile(accounttable,function(didwrite)
				if didwrite then
					timer.Simple(math.random(0.5,5),function() callback(ARCBANK_ERROR_NONE,1) end)
					if !hidden then
						if IsValid(ply) then
							ARCBank.Msg(ply:Nick().."("..ply:SteamID()..") hacked into "..accounttable.filename.." stole "..tostring(amount))
						else
							ARCBank.Msg("(Someone) hacked into "..accounttable.filename.." stole "..tostring(amount))
						end
						ARCBankAccountMsg(accounttable,string.Replace( string.Replace( ARCBank.Msgs.LogMsgs.RemoveMoney, "%VALUE%", tostring(-amount)), "%PLAYER%", "__UNKNOWN"))
					end
					--ARCBank.PlayerAddMoney(ply,amount)
				else
					callback(ARCBANK_ERROR_WRITE_FAILURE,0)
				end
			end)
		--end)
	end
	

end
function ARCBank.AtmFunc(ply,amount,groupname,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	if !IsValid(ply) || !ply:IsPlayer() then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	
		local datafunc = function(accountdata)
		if !accountdata then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdata.isgroup then
			if accountdata.owner != ply:SteamID() && !table.HasValue( accountdata.members, ply:SteamID() ) then
				callback(ARCBANK_ERROR_NO_ACCESS)
				return
			end
		else
			accountdata.name = ply:Nick()
		end
		local mode = "Added "..amount.." to account."
		local logmode = string.Replace( string.Replace( ARCBank.Msgs.LogMsgs.AddMoney, "%VALUE%", tostring(amount)), "%PLAYER%", ply:SteamID())
		if amount <= 0 then
			mode = "Subtracted "..tostring(-amount).." from account."
			logmode = string.Replace( string.Replace( ARCBank.Msgs.LogMsgs.RemoveMoney, "%VALUE%", tostring(-amount)), "%PLAYER%", ply:SteamID())
			if accountdata.money+ARCBank.Settings["debt_limit"] < -amount then
				--MsgN("Can't Afford!")
				callback(ARCBANK_ERROR_NO_CASH)
				return
			end
		else
			if !ARCBank.PlayerCanAfford(ply,amount) then
				callback(ARCBANK_ERROR_NO_CASH_PLAYER)
				return
			end
		end
		accountdata.money = accountdata.money + amount
		if accountdata.money >= 1e14 && amount > 0 then
			callback(ARCBANK_ERROR_TOO_MUCH_CASH)
			return
		end
		
		ARCBank.WriteAccountFile(accountdata,function(didwork)
			if didwork then
				ARCBank.PlayerAddMoney(ply,amount*-1)
				ARCBank.Msg(ply:Nick().."("..ply:SteamID()..") "..mode..accountdata.name.."'s Account. ("..accountdata.filename..") ("..accountdata.money..")")
				ARCBankAccountMsg(accountdata,logmode.." ("..accountdata.money..")")
				callback(ARCBANK_ERROR_NONE)
			else
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			end
		end)
	end
	
	if !groupname || groupname == "" then
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(ply:SteamID()),false,datafunc)
	else
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(groupname),true,datafunc)
	end
end
function ARCBank.Transfer(fromply,toply,fromname,toname,amount,reason,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	if amount < 0 then
		ARCBank.FuckIdiotPlayer(fromply,"Negative Transfer Funds Request")
		callback(ARCBANK_ERROR_EXPLOIT)
		return
	end
	local sid = ""
	local nic = "[OFFLINE PLAYER]"
	
	

	local dothingfr = function(accountdatafrom)
		if !accountdatafrom then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
			return
		end
		if accountdatafrom.isgroup then
			if accountdatafrom.owner != fromply:SteamID() && !table.HasValue( accountdatafrom.members, fromply:SteamID() ) then
				callback(ARCBANK_ERROR_NO_ACCESS)
				return
			end
		else
			accountdatafrom.name = fromply:Nick()
		end
		
		local dothingto = function(accountdatato)
			if !accountdatato then
				callback(ARCBANK_ERROR_NIL_ACCOUNT)
				return
			end
			if accountdatato.isgroup then
				if accountdatato.owner != sid && !table.HasValue( accountdatato.members, sid ) then
					callback(ARCBANK_ERROR_NO_ACCESS)
					return
				end
			end
			
			if accountdatafrom.money+ARCBank.Settings["debt_limit"] < amount then
				callback(ARCBANK_ERROR_NO_CASH)
				return
			end
			if accountdatafrom.filename != accountdatato.filename then --Fixed an exploit that the player could create more money
				accountdatafrom.money = accountdatafrom.money - amount
				accountdatato.money = accountdatato.money + amount
			end
			if accountdatato.money >= 1e14 then
				callback(ARCBANK_ERROR_TOO_MUCH_CASH)
				return
			end

			
			ARCBank.WriteAccountFile(accountdatato,function(didwork)
				if didwork then
					ARCBank.WriteAccountFile(accountdatafrom,function(didwork)
						if didwork then
							ARCBankAccountMsg(accountdatafrom,string.Replace(string.Replace(string.Replace(string.Replace( ARCBank.Msgs.LogMsgs.GiveMoney, "%VALUE%", tostring(amount)),"%ACCOUNT%",accountdatato.filename),"%PLAYER2%",sid),"%PLAYER1%",fromply:SteamID()).."["..tostring(reason).."]")
							ARCBankAccountMsg(accountdatato,string.Replace(string.Replace(string.Replace(string.Replace( ARCBank.Msgs.LogMsgs.GiveMoney, "%VALUE%", tostring(amount)),"%ACCOUNT%",accountdatafrom.filename),"%PLAYER2%",sid),"%PLAYER1%",fromply:SteamID()).."["..tostring(reason).."]")
							ARCBank.Msg(fromply:Nick().."("..fromply:SteamID()..") gave "..amount.." to "..nic.."("..sid..") (From accounts "..accountdatafrom.filename.." to "..accountdatato.filename..") ["..tostring(reason).."]")
							callback(ARCBANK_ERROR_NONE)
						else
							callback(ARCBANK_ERROR_WRITE_FAILURE)
						end
					end)
				else
					callback(ARCBANK_ERROR_WRITE_FAILURE)
				end
			end)
		end
		if !isstring(toply) && toply:IsPlayer() then
			sid = toply:SteamID()
			nic = toply:Nick()
		elseif string.StartWith(toply,"STEAM_") then
			sid = toply
		else
			callback(ARCBANK_ERROR_NIL_PLAYER)
			return
		end
		if !toname || toname == "" then
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(sid),false,dothingto)
			
		else
			ARCBank.ReadAccountFile(ARCBank.GetAccountID(toname),true,dothingto)
		end
	end	
	

	if !fromname || fromname == "" then
		if !IsValid(fromply) || !fromply:IsPlayer() || !toply then
			callback(ARCBANK_ERROR_NIL_PLAYER)
			return
		end
		accountdatafrom = ARCBank.ReadAccountFile(ARCBank.GetAccountID(fromply:SteamID()),false,dothingfr)
	else
		accountdatafrom = ARCBank.ReadAccountFile(ARCBank.GetAccountID(fromname),true,dothingfr)
	end

end
function ARCBank.Load()
	ARCBank.Loaded = false
		if #player.GetAll() == 0 then
			ARCBank.Msg("A player must be online before continuing...")
		end
		timer.Simple(1,function()
	--[[
		http.Fetch( "http://dl.dropboxusercontent.com/u/%%ID%%/ADDONS/arcbank/CurrentVer.txt",
		function( body, len, headers, code )
			-- The first argument is the HTML we asked for.
			ARCBank.Msg("HTTP: "..body)
		end,
		function( error )
			ARCBank.Msg("WARNING! Failed to get update version. ("..error..")")
		end
		);
		]]

		ARCBank.Msg("Post-loading ARCBank...")
		if game.SinglePlayer() then
			ARCBank.Msg("CRITICAL ERROR! THIS IS A SINGLE PLAYER GAME!")
			ARCBank.Msg("LOADING FALIURE!")
			return
		end
		if !file.IsDir( ARCBank.Dir,"DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir)
			file.CreateDir(ARCBank.Dir)
		end
		
		if !file.IsDir( ARCBank.Dir,"DATA" ) then
			ARCBank.Msg("CRITICAL ERROR! FAILED TO CREATE ROOT FOLDER!")
			ARCBank.Msg("LOADING FALIURE!")
			return
		end
		--if !file.Exists(ARCBank.Dir.."/_about_atm.txt","DATA") then
			--ARCBank.Msg("Copied atm about file")
			file.Write(ARCBank.Dir.."/_about_atm.txt", file.Read( "arcbank/data/about_atm.lua", "LUA" ) )
		--end
		--		 = false
		if file.Exists(ARCBank.Dir.."/__data.txt","DATA") then
			ARCBank.Disk = util.JSONToTable(file.Read( ARCBank.Dir.."/__data.txt","DATA" ))
			if (!ARCBank.Disk) then
				ARCBank.Msg("__data.txt is corrupt. Yeah, some accounts will be too.")
				ARCBank.Disk = {}
			end
			ARCBank.Disk.EmoPlayers = ARCBank.Disk.EmoPlayers or {}
			ARCBank.Disk.BlindPlayers = ARCBank.Disk.BlindPlayers or {}
			ARCBank.Disk.OldPlayers = ARCBank.Disk.OldPlayers or {}
			ARCBank.Disk.NommedCards = ARCBank.Disk.NommedCards or {}
		end
		if ARCBank.Disk.ProperShutdown then
			ARCBank.Disk.ProperShutdown = false
		else
			ARCBank.Msg("WARNING! THE SYSTEM DIDN'T SHUT DOWN PROPERLY! EXPECT CORRUPTED ACCOUNTS!")
		end
		ARCLib.AddonLoadSettings("ARCBank",{atm_language = "language"})

		if !file.IsDir( ARCBank.Dir.."/languages","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/languages")
			file.CreateDir(ARCBank.Dir.."/languages")
		end	
		if ARCBank.DefaultLangs then
			ARCBank.Msg("Writing default language files...")
			file.Write(ARCBank.Dir.."/languages/spa.txt", ARCBank.DefaultLangs.spa )
			file.Write(ARCBank.Dir.."/languages/sp.txt", ARCBank.DefaultLangs.spa )
			file.Write(ARCBank.Dir.."/languages/en.txt", ARCBank.DefaultLangs.en )
			file.Write(ARCBank.Dir.."/languages/ger.txt", ARCBank.DefaultLangs.ger )
			file.Write(ARCBank.Dir.."/languages/pt_br.txt", ARCBank.DefaultLangs.pt_br )
			file.Write(ARCBank.Dir.."/languages/fr.txt", ARCBank.DefaultLangs.fr )
			file.Write(ARCBank.Dir.."/languages/1337.txt", ARCBank.DefaultLangs.leet )
			file.Write(ARCBank.Dir.."/languages/ru.txt", ARCBank.DefaultLangs.ru )
			ARCBank.DefaultLangs = nil
		end
		ARCLib.SetAddonLanguage("ARCBank")
		if !file.IsDir( ARCBank.Dir.."/accounts","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts")
			file.CreateDir(ARCBank.Dir.."/accounts")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts/group","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts/group")
			file.CreateDir(ARCBank.Dir.."/accounts/group")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts/personal","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts/personal")
			file.CreateDir(ARCBank.Dir.."/accounts/personal")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts/group/logs","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts/group/logs")
			file.CreateDir(ARCBank.Dir.."/accounts/group/logs")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts/personal/logs","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts/personal/logs")
			file.CreateDir(ARCBank.Dir.."/accounts/personal/logs")
		end
		if !file.IsDir( ARCBank.Dir.."/saved_atms","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/saved_atms")
			file.CreateDir(ARCBank.Dir.."/saved_atms")
		end
		if !file.IsDir( ARCBank.Dir.."/custom_atms","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/custom_atms")
			file.CreateDir(ARCBank.Dir.."/custom_atms")
		end
		
		if !file.IsDir( ARCBank.Dir.."/accounts_unused","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts_unused")
			file.CreateDir(ARCBank.Dir.."/accounts_unused")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts_unused/group","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts_unused/group")
			file.CreateDir(ARCBank.Dir.."/accounts_unused/group")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts_unused/personal","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts_unused/personal")
			file.CreateDir(ARCBank.Dir.."/accounts_unused/personal")
		end
		
		if ARCBank.DefaultATM then
			file.Write(ARCBank.Dir.."/custom_atms/default.txt", ARCBank.DefaultATM )
			ARCBank.DefaultATM = nil
		end
		
		local files,dirs = file.Find(ARCBank.Dir.."/custom_atms/*.txt","DATA")
		
		for i=1,#files do
			local tab = util.JSONToTable(file.Read(ARCBank.Dir.."/custom_atms/"..files[i],"DATA"))
			if tab then
				for i = 1,#tab.ErrorSound do
					ARCLib.AddToSoundWhitelist("sent_arc_atm",tab.ErrorSound[i],65,100)
				end
				for i = 1,#tab.PressSound do
					ARCLib.AddToSoundWhitelist("sent_arc_atm",tab.PressSound[i],65,100)
				end
			end

		end
		
		ARCBank.LogFile = os.date(ARCBank.Dir.."/systemlog - %d %b %Y - "..tostring(os.date("%H")*60+os.date("%M"))..".log.txt")
		file.Write(ARCBank.LogFile,"***ARCBank System Log***\r\n"..table.Random({"Oh my god. You're reading this!","WINDOWS LOVES TYPEWRITER COMMANTS IN TXT FILES","What you're refeering to as 'Linux' is in fact GNU/Linux.","... did you mess something up this time?"}).."\r\nDates are in DD-MM-YYYY\r\n")
		ARCBank.LogFileWritten = true
		ARCBank.Msg("Log File Created at "..ARCBank.LogFile)
		
		ARCBank.Msg("**STARTING FILESYSTEM CHECK!**")
		if file.IsDir( ARCBank.Dir.."/group_account","DATA" ) || file.IsDir( ARCBank.Dir.."/personal_account","DATA" ) then
			ARCBank.Msg("Filesystem from a pre-release version of ARCBank detected.")
			ARCBank.Msg("Migrating data...")
			local OldFolders = {ARCBank.Dir.."/personal_account/standard/",ARCBank.Dir.."/personal_account/bronze/",ARCBank.Dir.."/personal_account/silver/",ARCBank.Dir.."/personal_account/gold/","NOPE",ARCBank.Dir.."/group_account/standard/",ARCBank.Dir.."/group_account/premium/"}
			for i = 1,4 do
				for k,v in pairs(file.Find(OldFolders[i].."*.txt","DATA")) do
					local oldaccountdata = util.JSONToTable(file.Read(OldFolders[i]..v,"DATA"))
					if oldaccountdata then
						if file.Exists(ARCBank.Dir.."/accounts/personal/"..v..".txt","DATA") then
							ARCBank.Msg(string.Replace(v,".txt","").." is already in the new filesystem! Account will be removed.")
						else
							local newaccount = {}
								newaccount.isgroup = false
								newaccount.filename =  string.lower(string.Replace(v,".txt",""))
								newaccount.name = oldaccountdata[1]
								newaccount.money = oldaccountdata[4]
								newaccount.rank = i
							file.Write( ARCBank.Dir.."/accounts/personal/"..newaccount.filename..".txt", util.TableToJSON(newaccount) )
							if file.Exists(ARCBank.Dir.."/accounts/personal/"..newaccount.filename..".txt","DATA") then
								file.Write(ARCBank.Dir.."/accounts/personal/logs/"..newaccount.filename..".txt",file.Read(OldFolders[i].."logs/"..v,"DATA"))
								file.Delete(OldFolders[i].."logs/"..v)
								file.Delete(OldFolders[i]..v)
								
							else
								ARCBank.Msg("Failed to transfer "..string.lower(string.Replace(v,".txt",""))..". account will be removed")
							end
						
						end
						
						--ARCBank.WriteAccountFile(datatadada)
						--
						--ARCBank.AccountExists(ARCBank.GetAccountID(string.Replace(v,".txt" "")),false)
					end
				end
			end
			
			
			for i = 6,7 do
				for k,v in pairs(file.Find(OldFolders[i].."*.txt","DATA")) do
					local oldaccountdata = util.JSONToTable(file.Read(OldFolders[i]..v,"DATA"))
					if oldaccountdata then
						if file.Exists(ARCBank.Dir.."/accounts/group/"..v..".txt","DATA") then
						
							ARCBank.Msg(string.Replace(v,".txt","").." is already in the new filesystem!")
						else
							local newaccount = {}
								newaccount.isgroup = true
								newaccount.filename = string.lower(string.Replace(v,".txt",""))
								newaccount.name = oldaccountdata[1]
								newaccount.owner = oldaccountdata[3]
								newaccount.money = oldaccountdata[4]
								newaccount.rank = i
								newaccount.members = oldaccountdata.players
							file.Write( ARCBank.Dir.."/accounts/group/"..newaccount.filename..".txt", util.TableToJSON(newaccount) )
							if file.Exists(ARCBank.Dir.."/accounts/group/"..newaccount.filename..".txt","DATA") then
								file.Write(ARCBank.Dir.."/accounts/group/logs/"..newaccount.filename..".txt",file.Read(OldFolders[i].."logs/"..v,"DATA"))
								file.Delete(OldFolders[i].."logs/"..v)
								file.Delete(OldFolders[i]..v)
							else
								ARCBank.Msg("Failed to transfer ".. string.lower(string.Replace(v,".txt","")))
							end
						end
						
						--ARCBank.WriteAccountFile(datatadada)
						--
						--ARCBank.AccountExists(ARCBank.GetAccountID(string.Replace(v,".txt" "")),false)
					end
				end
			end
			ARCLib.DeleteAll(ARCBank.Dir.."/group_account")
			ARCLib.DeleteAll(ARCBank.Dir.."/personal_account")
		end
		
		local stime = SysTime()
		local files, directories = file.Find( ARCBank.Dir.."/accounts/personal/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/personal/"..v,"DATA"))
			if !accountdata then
				ARCBank.Msg("Corrupted account found. ("..v.."); Attempting to restore...")
				local fixnum
				local log = file.Read( ARCBank.Dir.."/accounts/personal/logs/"..v,"DATA")
				
				if log != "" then
				
					local nums = string.Explode( "(", log )
					local i = #nums
					while i > 0 do
						local numss = string.Explode( ")", nums[i] )
						fixnum = tonumber(numss[1])
						--MsgN(numss[1])
						if isnumber(fixnum) then
							
							local newaccount = {}
							newaccount.isgroup = false
							newaccount.filename = string.Replace(v,".txt","")
							newaccount.name = "[[RESTORED ACCOUNT]]"
							newaccount.money = tostring(fixnum)
							newaccount.rank = 1
							
							file.Write( ARCBank.Dir.."/accounts/personal/"..v, util.TableToJSON(newaccount) )
							ARCBank.Msg(v.." - Account restored!")
							i = -1
						end
						i = i - 1
					end
				
				end
				if !isnumber(fixnum) then
					ARCBank.Msg("Failed to restore account - "..v.."; Removing.")
					file.Delete(ARCBank.Dir.."/accounts/personal/"..v)
					file.Append(ARCBank.Dir.."/accounts/personal/logs/"..v, os.date("%d-%m-%Y %H:%M:%S").." > This account was corrupt and restoration failed.\r\n")
				end
				
			end
		end
		
		
		local files, directories = file.Find( ARCBank.Dir.."/accounts/group/*.txt","DATA" )
		for _,v in pairs( files ) do
			local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/group/"..v,"DATA"))
			if !accountdata then
				ARCBank.Msg("Corrupted account found. ("..v.."); Attempting to restore...")
				local fixnum
				local log = file.Read( ARCBank.Dir.."/accounts/group/logs/"..v,"DATA")
				if log != "" then
					local newaccount = {}
					newaccount.isgroup = true
					newaccount.filename = string.Replace(v,".txt","")
					newaccount.name = string.sub( string.Replace(v,".txt",""), 8)
					
					newaccount.rank = 6
					newaccount.members = {}
					newaccount.owner = ""
					local nums = string.Explode( "(", log )
					local i = #nums
					while i > 0 do
						local numss = string.Explode( ")", nums[i] )
						fixnum = tonumber(numss[1])
						if isnumber(fixnum) then
							newaccount.money = fixnum
						end
						i = i - 1
					end
					local entries = string.Explode( ">", log )
					--PrintTable(entries)
					i = 1
					while i <= #entries do
						if newaccount.owner == "" && string.StartWith(entries[i]," (STEAM_0") then
							
							newaccount.owner = string.Explode( ")", string.Explode( "(", entries[i] )[2] )[1]
							i = #entries + 1
						end
						i = i + 1
					end
					if string.StartWith(newaccount.owner,"STEAM_") && isnumber(newaccount.money) then
						file.Write( ARCBank.Dir.."/accounts/group/"..v, util.TableToJSON(newaccount) )
						ARCBank.Msg(v.." - Account restored!")
					else
						ARCBank.Msg("Failed to restore account - "..v.."; Removing.")
						--file.Delete(ARCBank.Dir.."/accounts/group/"..v)
						file.Append(ARCBank.Dir.."/accounts/group/logs/"..v, os.date("%d-%m-%Y %H:%M:%S").." > This account was corrupt and restoration failed.\r\n")
					end
				end
				--[[
								newaccount.isgroup = true
								newaccount.filename = string.lower(string.Replace(v,".txt",""))
								newaccount.name = oldaccountdata[1]
								newaccount.owner = oldaccountdata[3]
								newaccount.money = oldaccountdata[4]
								newaccount.rank = i
								newaccount.members = oldaccountdata.players
				]]
				
				
			end
		end
		stime = SysTime() - stime 
		if stime > 0.1 then
			ARCBank.Msg("File system check took "..stime.." seconds. Which I personally think is a bit too long. Optimizing...")
			
			local files, directories = file.Find( ARCBank.Dir.."/accounts/group/*.txt","DATA" )
			for _,v in pairs( files ) do
				local data = file.Read( ARCBank.Dir.."/accounts/group/"..v,"DATA")
				local accountdata = util.JSONToTable(data)
				file.Append( ARCBank.Dir.."/accounts_unused/"..string.lower(string.gsub(accountdata.owner, "[^_%w]", "_"))..".txt", "group/"..v.."\r\n" )
				for i = 1,#accountdata.members do
					file.Append( ARCBank.Dir.."/accounts_unused/"..string.lower(string.gsub(accountdata.members[i], "[^_%w]", "_"))..".txt", "group/"..v.."\r\n" )
				end
				
				file.Write( ARCBank.Dir.."/accounts_unused/group/"..v, data )
				file.Delete( ARCBank.Dir.."/accounts/group/"..v)
				file.Append(ARCBank.Dir.."/accounts/group/logs/"..v, os.date("%d-%m-%Y %H:%M:%S").." > Account has been archived. You will not gain interest during this time.\r\n")
			end
			local files, directories = file.Find( ARCBank.Dir.."/accounts/personal/*.txt","DATA" )
			for _,v in pairs( files ) do
				local data = file.Read( ARCBank.Dir.."/accounts/personal/"..v,"DATA")
				file.Append( ARCBank.Dir.."/accounts_unused/"..string.Replace(v,"account_",""), "personal/"..v.."\r\n" )
				file.Write( ARCBank.Dir.."/accounts_unused/personal/"..v, data )
				file.Delete( ARCBank.Dir.."/accounts/personal/"..v)
				file.Append(ARCBank.Dir.."/accounts/personal/logs/"..v, os.date("%d-%m-%Y %H:%M:%S").." > Account has been archived. You will not gain interest during this time.\r\n")
			end
			
			
		else
			ARCBank.Msg("File system check took "..stime.." seconds.")
		end
		ARCBank.Msg("**FILESYSTEM CHECK COMPLETE!**")
		timer.Create( "ARCBANK_SAVEDISK", 300, 0, function() 
			if ARCBank.Settings["interest_time"] < 1 then
				ARCBank.Msg("interest_time cannot be less than 1 hour. Will not give out interest")
			else
				if !ARCBank.Disk.LastInterestTime then
					ARCBank.Disk.LastInterestTime = os.time() - ARCBank.Settings["interest_time"]*3600
				end
				local missedtimes = math.floor((os.time() - ARCBank.Disk.LastInterestTime)/(ARCBank.Settings["interest_time"]*3600))
				if missedtimes > 0 then
					if missedtimes > 1 then
						ARCBank.Msg("MISSED "..missedtimes.." INTEREST PAYMENTS! Looks like we'll have to catch up!")
					end
					for i=1,missedtimes do
						timer.Simple(i*2,ARCBank.AddAccountInterest)
					end
					
					ARCBank.Disk.LastInterestTime = os.time()
					
					timer.Simple((missedtimes+1)*2,function()
						ARCBank.Msg("Interest will be given next on "..os.date( "%X - %d-%m-%Y", ARCBank.Disk.LastInterestTime+ARCBank.Settings["interest_time"]*3600 ))
					end)
				end
			end
			file.Write(ARCBank.Dir.."/__data.txt", util.TableToJSON(ARCBank.Disk) )
			--ARCBank.UpdateLang(ARCBank.Settings["atm_language"])

			if ARCBank.Settings["notify_update"] then
				ARCBank.Msg("ARCBank no longer checks for updates. This feature has been replaced with ARCLoad. Please disable the 'notify_update' setting.")
			end
			
		end )
		timer.Start( "ARCBANK_SAVEDISK" ) 
		if ARCBank.IsMySQLEnabled() then
			ARCBank.MySQL.Connect()
		else
			ARCBank.Msg("ARCBank is ready!")
			ARCBank.Loaded = true
			ARCBank.Busy = false
			ARCBank.CapAccountRank();
		end
		for k,ply in pairs(player.GetAll()) do
			local f = ARCBank.Dir.."/accounts_unused/"..string.lower(string.gsub(ply:SteamID(), "[^_%w]", "_"))..".txt" 
			if file.Exists(f,"DATA") then 
				local accounts = string.Explode( "\r\n", file.Read(f,"DATA")) 
				for i=1,#accounts do 
					if #accounts[i] > 2 && file.Exists(ARCBank.Dir.."/accounts_unused/"..accounts[i],"DATA") then 
						file.Write( ARCBank.Dir.."/accounts/"..accounts[i], file.Read(ARCBank.Dir.."/accounts_unused/"..accounts[i],"DATA") ) 
						file.Delete( ARCBank.Dir.."/accounts_unused/"..accounts[i]) 
						file.Delete(f)
						--file.Append(ARCBank.Dir.."/accounts/group/logs/"..accounts[i], os.date("%d-%m-%Y %H:%M:%S").." > Account has been re-activated.\r\n") 
					end 
				end 
			end 
		end
	end)
end

