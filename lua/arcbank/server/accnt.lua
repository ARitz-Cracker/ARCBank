-- accnt.lua - Accounts and File manager

-- This file is under copyright.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016 Aritz Beobide-Cardinal All rights reserved.

-- Group members are stored seperatly from group accounts
-- 
--[[
Ventz: please add a feature
Ventz: to list accounts in order of balance
Ventz: cos its useful to find ppl who somehow glitched money
Ventz: if that ever happens#


personal)_
1 - Withdraw/deposit
2 - Transfer
4 - Interest
8 - Upgrade
16 - Downgrade
32 - Add member
64 - Remove member
128 - Create
256 - Delete
65535 - everything

CREATE TABLE IF NOT EXISTS arcbank_log
(
transaction_id UNSIGNED BIGINT NOT NULL AUTO_INCREMENT,
timestamp UNSIGNED BIGINT NOT NULL,
account1 varchar(255) NOT NULL,
account2 varchar(255) NOT NULL,
user1 varchar(255) NOT NULL,
user2 varchar(255) NOT NULL,
moneydiff BIGINT NOT NULL,
money BIGINT, --this is nullable so we can get the stuff before it
transaction_type UNSIGNED SMALLINT NOT NULL,
comment varchar(255) NOT NULL
);
SELECT * FROM arcbank_log where money IS NOT NULL AND account1='amazing' ORDER BY transaction_id DESC LIMIT 1;
SELECT * FROM arcbank_log WHERE timestamp >= 1479422050 AND account1 = 'amazing' ORDER BY transaction_id ASC;



CREATE TABLE IF NOT EXISTS arcbank_accounts
(
account varchar(255) PRIMARY KEY,
name varchar(255) NOT NULL,
owner varchar(255) NOT NULL,
rank UNSIGNED TINYINT NOT NULL
);

CREATE TABLE IF NOT EXISTS arcbank_groups
(
account varchar(255) NOT NULL,
user varchar(255) NOT NULL,
CONSTRAINT pk_PersonID UNIQUE (account,user)
);

CREATE TABLE arcbank_lock
(
account varchar(255) PRIMARY KEY
}
]]

local function specialAccess(ply)
	return (IsValid(ply) and ply:IsPlayer() and table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup()))) or ply == "__SYSTEM" or ply == "__UNKNOWN"
end

local function sterilizePlayerAccount(ply,accnt)
	if isstring(ply) then
		if !string.StartWith( ply, ARCBank.PlayerIDPrefix ) then
			return nil
		end
	elseif IsValid(ply) and ply:IsPlayer() then
		ply = ARCBank.GetPlayerID(ply)
	else
		return nil
	end
	if !accnt or accnt == "" then
		accnt = "personal_"..ARCLib.SafeFileName(ply)
	else
		accnt = ARCLib.SafeFileName(accnt)
	end
	return ply,accnt
end


function ARCBank.CreateAccount(ply,groupname,rank,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	if not IsValid(ply) or not ply:IsPlayer() then
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return
	end
	local newb = true
	for k,v in pairs( ARCBank.Settings["usergroup_all"] ) do
		if ply:IsUserGroup( v ) then
			newb = false
		end
	end
	if newb then
		if rank < ARCBANK_GROUPACCOUNTS_ then
			for i=rank,ARCBANK_PERSONALACCOUNTS_GOLD do
				if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],ply:GetUserGroup()) then
					newb = false
					break
				end
			end
		else
			for i=rank,ARCBANK_GROUPACCOUNTS_PREMIUM do
				if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],ply:GetUserGroup()) then
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
	
	local name = ply:Nick()
	local initbalance = 0
	if !groupname || groupname == "" then
		if rank <= 0 then
			callback(ARCBANK_ERROR_INVALID_RANK)
			return
		end
		initbalance = ARCBank.Settings["account_starting_cash"]
	else
		if rank <= ARCBANK_GROUPACCOUNTS_ then
			callback(ARCBANK_ERROR_INVALID_RANK)
			return
		end
		name = groupname
	end
	ARCBank.WriteNewAccount(name,ARCBank.GetPlayerID(ply),rank,initbalance,"",callback)
end
function ARCBank.RemoveAccount(ply,account,comment,callback)
	local sa = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner != ply and not sa then
				callback(ARCBANK_ERROR_NO_ACCESS)
				return
			end
			if data.rank < ARCBANK_GROUPACCOUNTS_ and ARCBank.Settings["account_starting_cash"] > 0 then
				callback(ARCBANK_ERROR_DELETE_REFUSED)
				return
			end
			ARCBank.ReadBalance(account,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					if currentbalance < 0 then
						callback(ARCBANK_ERROR_DEBT)
						return
					end
					ARCBank.EraseAccount(account,ply,comment,callback)
				else
					callback(err)
				end
			end)
			
		else
			callback(err)
		end
	end)
end


function ARCBank.CanAccessAccount(ply,account,callback)
	if specialAccess(ply) then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
		return
	end

	ply, account = sterilizePlayerAccount(ply,account)
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner == ply then
				callback(ARCBANK_ERROR_NONE)
			elseif data.rank > ARCBANK_GROUPACCOUNTS_ then
				ARCBank.ReadGroupMembers(account,function(err,data)
					if err == ARCBANK_ERROR_NONE then
						if table.HasValue(data,ply) then
							callback(ARCBANK_ERROR_NONE)
						else
							callback(ARCBANK_ERROR_NO_ACCESS)
						end
					else
						callback(err)
					end
				end)
			else
				callback(ARCBANK_ERROR_NO_ACCESS)
			end
		else
			callback(err)
		end
	end)
end

function ARCBank.IntergrityCheck(callback)
	-- Check if all transfers have matches
	-- Check if created account logs have properties or deleted log entries
	-- Check if group members match up with logs
end

local function accountInterest(accounts,i)
	ARCBank.ReadTransactions(accounts[i],os.time()-(ARCBank.Settings["account_interest_time_limit"]*86400),bit.bnot(ARCBANK_TRANSACTION_EVERYTHING,ARCBANK_TRANSACTION_INTEREST),function(errcode,data)
		if #data > 0 then
			local interest = ARCBank.Settings["interest_"..accounts[i].rank.."_"..ARCBANK_ACCOUNTSTRINGS[accounts[i].rank]] or 0
			ARCBank.WriteBalanceMultiply(accounts[i].account,nil,"__SYSTEM",nil,1+(interest/100),4,interest.."%",function(err)
				if err != ARCBANK_ERROR_NONE --[[ and err != ARCBANK_ERROR_NO_CASH ]] then
					ARCBank.Msg("Failed to give interest to "..accounts[i].account.." - "..ARCBANK_ERRORSTRINGS[err])
				else
					ARCBank.Msg("Gave interest to "..accounts[i].account)
				end
				accountInterest(accounts,i + 1)
			end,ARCBank.Settings["interest_perpetual_debt"])
		else
			ARCBank.Msg(accounts[i].." is unused")
			accountInterest(accounts,i + 1)
		end
	end)

end

function ARCBank.AddAccountInterest()
	if !ARCBank.Loaded then return end
	if ARCBank.Busy then return end
	if !ARCBank.Settings["interest_enable"] then return end
	ARCBank.Msg("Giving out bank interest...")
	ARCBank.ReadAllAccountProperties(function(errcode,data)
		if errcode == ARCBANK_ERROR_NONE then
			accountInterest(data,1)
		else
			ARCBank.Msg("Failed to get list of all accounts ("..errcode..")")
		end
	end)
end

local fsReadAllProperties = {}
function ARCBank.ReadAllAccountProperties(callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_accounts;",function(err,data)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE,data)
			end
		end)
	else
		local files = file.Find(ARCBank.Dir.."/accounts_1.4/*","DATA")
		files[#files + 1] = callback
		fsReadAllProperties[#fsReadAllProperties + 1] = files
	end
end

local fsReadOwners = {}

function ARCBank.ReadOwnedAccounts(user,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_accounts WHERE owner='"..ARCBank.MySQL.Escape(user).."';",function(err,data)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				accounts = {}
				if #data > 0 then
					for k,v in ipairs(data) do
						accounts[k] = v.account
					end
				end
				callback(ARCBANK_ERROR_NONE,accounts)
			end
		end)
	else
		local files = file.Find(ARCBank.Dir.."/groups_1.4/*","DATA")
		local i = #files
		i = i + 1
		files[i] = user
		i = i + 1
		files[i] = callback
		fsReadOwners[#fsReadOwners + 1] = files
	end
end
local fsReadMembers = {}
function ARCBank.ReadMemberedAccounts(user,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_accounts WHERE owner='"..ARCBank.MySQL.Escape(user).."';",function(err,data)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				accounts = {}
				if #data > 0 then
					for k,v in ipairs(data) do
						accounts[k] = v.account
					end
				end
				callback(ARCBANK_ERROR_NONE,accounts)
			end
		end)
	else
		local files = file.Find(ARCBank.Dir.."/accounts_1.4/*","DATA")
		local i = #files
		i = i + 1
		files[i] = user
		i = i + 1
		files[i] = callback
		fsReadMembers[#fsReadMembers + 1] = files
	end
end

function ARCBank.EraseAccount(account,person,comment,callback)
	account = tostring(account)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("DELETE FROM arcbank_accounts WHERE account='"..ARCBank.MySQL.Escape(account).."';",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				ARCBank.MySQL.Query("DELETE FROM arcbank_groups WHERE account='"..ARCBank.MySQL.Escape(account).."';",function(err,ddata)
					if err then
						callback(ARCBANK_ERROR_WRITE_FAILURE)
					else
						ARCBank.WriteTransaction(account,nil,person,nil,nil,nil,ARCBANK_TRANSACTION_DELETE,comment,callback)
					end
				end)
			end
		end)
	else
		file.Delete( ARCBank.Dir.."/accounts_1.4/"..account..".txt" ) 
		file.Delete( ARCBank.Dir.."/groups_1.4/"..account..".txt" ) 
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
	end
end

function ARCBank.WriteNewAccount(name,owner,rank,amount,comment,callback)
	name = tostring(name)
	owner = tostring(owner)
	amount = tonumber(amount) or 0
	rank = tonumber(rank) or 1
	local account
	if rank < ARCBANK_GROUPACCOUNTS_ then
		account = "personal_"..ARCLib.SafeFileName(owner)
	else
		account = ARCLib.SafeFileName(name)
		if string.StartWith( account, "personal_" ) then
			timer.Simple(0.0001, function() callback(ARCBANK_ERROR_PREFIX_CONFLICT) end)
			return
		end
	end
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	
	ARCBank.ReadAccountProperties(account,function(errcode,data)
		if errcode == ARCBANK_ERROR_NIL_ACCOUNT then
			local cb = function(err)
				if err then
					callback(ARCBANK_ERROR_WRITE_FAILURE)
				else
					ARCBank.WriteTransaction(account,nil,owner,nil,amount,amount,ARCBANK_TRANSACTION_CREATE,comment,function(errcode)
						callback(errcode,account)
					end)
				end
			end
			if ARCBank.IsMySQLEnabled() then
				ARCBank.MySQL.Query("INSERT INTO arcbank_accounts(account,name,owner,rank) VALUES('"..account.."','"..ARCBank.MySQL.Escape(name).."','"..ARCBank.MySQL.Escape(owner).."',"..rank..");",cb)
			else
				local fullpath = ARCBank.Dir.."/accounts_1.4/"..tostring(account)..".txt"
				local tab = {}
				tab.account = account
				tab.name = name
				tab.owner = owner
				tab.rank = rank
				file.Write(fullpath,util.TableToJSON(tab))
				if file.Exists(fullpath,"DATA") then
					cb(nil)
				else
					cb("Shits fucked up")
				end
			end
		elseif errcode == ARCBANK_ERROR_NONE then
			callback(ARCBANK_ERROR_NAME_DUPE)
		else
			callback(errcode)
		end
	end)
end

function ARCBank.WriteAccountProperties(account,name,owner,rank)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		local q = "UPDATE arcbank_accounts SET "
		if name then
			q = q .. "name='"..ARCBank.MySQL.Escape(name).."',"
		end
		if owner then
			q = q .. "owner='"..ARCBank.MySQL.Escape(owner).."',"
		end
		if rank then
			q = q .. "rank="..(tonumber(rank) or 0)..","
		end
		q = string.sub(q,#q-1).." WHERE account='"..ARCBank.MySQL.Escape(account).."';"
		ARCBank.MySQL.Query(q,function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE)
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/accounts_1.4/"..tostring(account)..".txt"
		if file.Exists( fullpath, "DATA" ) then
			data = file.Read( fullpath, "DATA")
			if !data || data == "" then 
				timer.Simple(0.0001, function() callback(ARCBANK_ERROR_CORRUPT_ACCOUNT) end)
			else
				local tab = util.JSONToTable(data)
				if tab then
					if name then
						tab.name = tostring(name)
					end
					if owner then
						tab.owner = tostring(owner)
					end
					if rank then
						tab.rank = tonumber(rank)
					end
					file.Write(fullpath,util.TableToJSON(tab))
					timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
				else
					timer.Simple(0.0001, function() callback(ARCBANK_ERROR_CORRUPT_ACCOUNT) end)
				end
				
			end
		else
			timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NIL_ACCOUNT) end)
		end
	end
end

function ARCBank.WriteBalanceMultiply(account1,account2,user1,user2,amount,transaction_type,comment,callback,allowdebt)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if allowdebt == nil then allowdebt = true end
	ARCBank.LockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadBalance(account1,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					local total = currentbalance * amount
					local difference = total - currentbalance
					if total + ARCBank.Settings.account_debt_limit*ARCLib.BoolToNumber(allowdebt) >= 0 then
						ARCBank.WriteTransaction(account1,account2,user1,user2,difference,total,transaction_type,comment,function(err)
							if err == ARCBANK_ERROR_NONE then
								ARCBank.UnlockAccount(account1,callback)
							else
								callback(err)
							end
						end)
					else
						callback(ARCBANK_ERROR_NO_CASH)
					end
				else
					callback(err)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.WriteBalanceAdd(account1,account2,user1,user2,amount,transaction_type,comment,callback,allowdebt)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if allowdebt == nil then allowdebt = true end
	ARCBank.LockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadBalance(account1,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					local total = currentbalance + amount
					if total + ARCBank.Settings.account_debt_limit*ARCLib.BoolToNumber(allowdebt) >= 0 then
						ARCBank.WriteTransaction(account1,account2,user1,user2,amount,total,transaction_type,comment,function(err)
							if err == ARCBANK_ERROR_NONE then
								ARCBank.UnlockAccount(account1,callback)
							else
								callback(err)
							end
						end)
					else
						callback(ARCBANK_ERROR_NO_CASH)
					end
				else
					callback(err)
				end
			end)
		else
			callback(err)
		end
	end)
end
function ARCBank.WriteBalanceSet(account1,account2,user1,user2,amount,transaction_type,comment,callback,allowdebt)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if allowdebt == nil then allowdebt = true end
	ARCBank.LockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadBalance(account1,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					if amount + ARCBank.Settings.account_debt_limit*ARCLib.BoolToNumber(allowdebt) >= 0 then
						local difference = amount - currentbalance
						ARCBank.WriteTransaction(account1,account2,user1,user2,difference,amount,transaction_type,comment,function(err)
							if err == ARCBANK_ERROR_NONE then
								ARCBank.UnlockAccount(account1,callback)
							else
								callback(err)
							end
						end)
					else
						callback(ARCBANK_ERROR_NO_CASH)
					end
				else
					callback(err)
				end
			end)
		else
			callback(err)
		end
	end)
end
local currentLogFile = ""
local currentLogs = file.Find( ARCBank.Dir.."/logs_1.4/*", "DATA")
local currentLogLine = -1
local logCache = {}
local lastClearCash = 0
local function readLog(v)
	if v == string.GetFileFromFilename(currentLogFile) then
		return file.Read(currentLogFile,"DATA")
	else
		if !logCache[v] then
			logCache[v] = file.Read(ARCBank.Dir.."/logs_1.4/"..v,"DATA")
		end
		return logCache[v]
	end
end
function ARCBank.WriteTransaction(account1,account2,user1,user2,moneydiff,money,transaction_type,comment,callback)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		local keys = "INSERT INTO arcbank_log(timestamp"
		local values = "VALUES ("..os.time()
		if account1 then
			keys = keys .. ",account1"
			values = values .. ",'"..ARCBank.MySQL.Escape(account1).."'"
		end
		if account2 then
			keys = keys .. ",account2"
			values = values .. ",'"..ARCBank.MySQL.Escape(account2).."'"
		end
		if user1 then
			keys = keys .. ",user1"
			values = values .. ",'"..ARCBank.MySQL.Escape(user1).."'"
		end
		if user2 then
			keys = keys .. ",user2"
			values = values .. ",'"..ARCBank.MySQL.Escape(user2).."'"
		end
		if moneydiff then
			keys = keys .. ",moneydiff"
			values = values .. ","..tonumber(moneydiff)
			if money and moneydiff != 0 then
				keys = keys .. ",money"
				values = values .. ","..tonumber(money)
			end
		end
		if transaction_type then
			keys = keys .. ",transaction_type"
			values = values .. ","..tonumber(transaction_type)
		end
		if comment then
			keys = keys .. ",comment"
			values = values .. ",'"..ARCBank.MySQL.Escape(string.Replace( comment, "\r\n", "" )).."'"
		end
		ARCBank.MySQL.Query(keys..") "..values..");",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE)
			end
		end)
	else
		if currentLogFile == "" then
			currentLogs = file.Find( ARCBank.Dir.."/logs_1.4/*", "DATA")
			if #currentLogs == 0 then
				currentLogFile = ARCBank.Dir.."/logs_1.4/"..os.time()..".txt"
				currentLogLine = 1
			else
				currentLogFile = ARCBank.Dir.."/logs_1.4/"..currentLogs[1]
				
				currentLogLine = #string.Explode("\r\n",file.Read(currentLogFile,"DATA"))
				if currentLogLine > 4096 then
					currentLogFile = ARCBank.Dir.."/logs_1.4/"..os.time()..".txt"
					currentLogLine = 1
				end
			end
		end
		local currentLogsLen = #currentLogs
		local logFile = string.GetFileFromFilename(currentLogFile)
		if currentLogs[currentLogsLen] != logFile then
			currentLogsLen = currentLogsLen + 1
			currentLogs[currentLogsLen] = logFile
		end
		
		file.Append( currentLogFile, ((currentLogsLen-1)*4096+currentLogLine).."\t"..os.time().."\t"..(account1 or "").."\t"..(account2 or "").."\t"..(user1 or "").."\t"..(user2 or "").."\t"..(tonumber(moneydiff) or "").."\t"..(tonumber(money) or "").."\t"..(tonumber(transaction_type) or "").."\t"..string.Replace( comment, "\r\n", "" ).."\r\n" )
		if currentLogLine >= 4096 then
			currentLogFile = ARCBank.Dir.."/logs_1.4/"..os.time()..".txt"
			currentLogLine = 1
		else
			currentLogLine = currentLogLine + 1
		end
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
	end
end
local loackedAccounts = {}
function ARCBank.UnlockAccount(filename,callback)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("DELETE FROM arcbank_lock WHERE account='"..ARCBank.MySQL.Escape(filename).."';",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE)
			end
		end)
	else
		loackedAccounts[filename] = nil
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
	end
end

local IKnowWhatErrorsToIgnore = false
function ARCBank.LockAccount(filename,callback,retries)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	retries = retries or 0
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("INSERT INTO arcbank_lock(account) VALUES('"..ARCBank.MySQL.Escape(filename).."');",function(err,ddata)
			if err then
				if IKnowWhatErrorsToIgnore then
					if retries > 50 then 
						callback(ARCBANK_ERROR_DEADLOCK)
					else
						timer.Simple(0.1, function() ARCBank.LockAccount(filename,callback,retries+1) end)
					end
				else
					callback(ARCBANK_ERROR_WRITE_FAILURE)
				end
			else
				local data = {}
				if #ddata > 0 then
					for k,v in ipairs(ddata) do
						data[k] = v.user
					end
				end
				callback(ARCBANK_ERROR_NONE,data)
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/groups_1.4/"..tostring(filename)..".txt"
		if loackedAccounts[filename] then
			if retries > 50 then 
				timer.Simple(0.0001, function() callback(ARCBANK_ERROR_DEADLOCK) end)
			else
				timer.Simple(0.1, function() ARCBank.LockAccount(filename,callback,retries+1) end)
			end
		else
			loackedAccounts[filename] = true
			timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
		end
	end
end

function ARCBank.WriteGroupMemberRemove(filename,person,callback)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("DELETE FROM arcbank_groups WHERE account='"..ARCBank.MySQL.Escape(filename).."' AND user='"..ARCBank.MySQL.Escape(person).."';",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE)
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/groups_1.4/"..tostring(filename)..".txt"
		if file.Exists( fullpath, "DATA" ) then
			file.Write( fullpath, string.Replace( file.Read(fullpath,"DATA"), person..",", "")   )
		end
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
	end
end

function ARCBank.WriteGroupMemberAdd(filename,person,callback)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("INSERT INTO arcbank_groups(account,user) VALUES('"..ARCBank.MySQL.Escape(filename).."','"..ARCBank.MySQL.Escape(person).."');",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE)
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/groups_1.4/"..tostring(filename)..".txt"
		file.Append( fullpath, person.."," )
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
	end
end

function ARCBank.ReadGroupMembers(filename,callback)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_groups WHERE account='"..ARCBank.MySQL.Escape(filename).."';",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				local data = {}
				if #ddata > 0 then
					for k,v in ipairs(ddata) do
						data[k] = v.user
					end
				end
				callback(ARCBANK_ERROR_NONE,data)
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/groups_1.4/"..tostring(filename)..".txt"
		if file.Exists( fullpath, "DATA" ) then
			local tab = string.Explode( ",", file.Read( fullpath, "DATA"))
			if tab then
				tab[#tab] = nil --Last person is blank because lazy
				timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE,tab) end)
			else
				timer.Simple(0.0001, function() callback(ARCBANK_ERROR_CORRUPT_ACCOUNT) end)
			end
		else
			timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE,{}) end)
		end
	end
end

function ARCBank.ReadAccountProperties(filename,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_accounts WHERE account='"..ARCBank.MySQL.Escape(filename).."';",function(err,data)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				if #data == 0 then
					callback(ARCBANK_ERROR_NIL_ACCOUNT)
				else
					callback(ARCBANK_ERROR_NONE,data[1])
				end
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/accounts_1.4/"..tostring(filename)..".txt"
		if file.Exists( fullpath, "DATA" ) then
			data = file.Read( fullpath, "DATA")
			if !data || data == "" then 
				timer.Simple(0.0001, function() callback(ARCBANK_ERROR_CORRUPT_ACCOUNT) end)
			else
				local tab = util.JSONToTable(data)
				if tab then
					timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE,tab) end)
				else
					timer.Simple(0.0001, function() callback(ARCBANK_ERROR_CORRUPT_ACCOUNT) end)
				end
				
			end
		else
			timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NIL_ACCOUNT) end)
		end
	end
end

local fsReadBalance = {}
function ARCBank.ReadBalance(filename,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.ReadAccountProperties(filename,function(errcode,data)
			if errcode == ARCBANK_ERROR_NONE then
				ARCBank.MySQL.Query("SELECT * FROM arcbank_log where money IS NOT NULL AND account1='"..ARCBank.MySQL.Escape(filename).."' ORDER BY transaction_id DESC LIMIT 1;",function(err,data)
					if err then
						callback(ARCBANK_ERROR_READ_FAILURE)
					else
						if #data == 0 then
							callback(ARCBANK_ERROR_NIL_ACCOUNT)
						else
							callback(ARCBANK_ERROR_NONE,data[1].money)
						end
					end
				end)
			else
				callback(errcode)
			end
		end)
	else
		local fullpath = ARCBank.Dir.."/accounts_1.4/"..tostring(filename)..".txt"
		if file.Exists( fullpath, "DATA" ) then
			local files = table.Reverse(currentLogs)
			local i = #files
			i = i + 1
			files[i] = filename
			i = i + 1
			files[i] = callback
			fsReadBalance[#fsReadBalance + 1] = files
		else
			timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NIL_ACCOUNT) end)
		end
	end
end

local fsReadTransactions = {}
function ARCBank.ReadTransactions(filename,timestamp,ttype,callback) -- TODO: LIKE clause to search through transactions?
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	timestamp = tonumber(timestamp) or 0
	filename = filename or ""
	ttype = ttype or 0
	ttype = bit.band( ttype, ARCBANK_TRANSACTION_EVERYTHING ) -- Clamp it to 16 bit
	if ARCBank.IsMySQLEnabled() then
		local q = "SELECT * FROM table WHERE timestamp >= "..timestamp
		if filename != "" then
			q = q .. " AND account1 = '"..ARCBank.MySQL.Escape(filename).."'"
		end
		if ttype > 0 then
		 q = q .. " AND transaction_type & "..ttype.." > 0"
		end
		q = q .. " ORDER BY transaction_id ASC;"
		ARCBank.MySQL.Query(q,function(err,data)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				callback(ARCBANK_ERROR_NONE,data)
			end
		end)
	else
		local files = table.Copy(currentLogs)
		if #files > 1 then
			local num = tonumber(string.sub( files[2], 1, #files[2]-4 ))
			while num < timestamp do
				table.remove(files,1)
				if files[2] then
					num = tonumber(string.sub( files[2], 1, #files[2]-4 ))
				else
					break
				end
			end
		end
		local i = #files
		i = i + 1
		files[i] = filename
		i = i + 1
		files[i] = timestamp
		i = i + 1
		files[i] = ttype
		i = i + 1
		files[i] = callback
		fsReadTransactions[#fsReadTransactions+1] = files
	end
end

if !ARCLib.IsVersion("1.6.2") then return end -- ARCLib.AddThinkFunc is only available in v1.6.2 or later

ARCLib.AddThinkFunc("ARCBank ReadTransactions",function() -- Look at this guy, re-inventing the wheel
	local i = 1
	while i < #fsReadTransactions do
		local files = fsReadTransactions[i]
		local callback = table.remove(files)
		local timestampstart = table.remove(files)
		local ttype = table.remove(files)
		local filename = table.remove(files)
		
		local datalen = 0
		local data = {}
		for k,v in iparis(files) do 
			local line = string.Explode( "\r\n", readLog(v) or "")
			line[#line] = nil --Last line of a log is always blank
			for kk,vv in ipairs(line) do
				local stuffs = string.Explode("\t",vv)
				local transaction_type = tonumber(stuffs[9])
				local timestamp = tonumber(stuffs[2]) or 0
				
				if (ttype == 0 or bit.band(transaction_type,ttype) > 0) and timestamp >= timestampstart then
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
					data[datalen].transaction_type = transaction_type
					data[datalen].comment = stuffs[10]
				end
			end
			coroutine.yield() 
		end
		callback(ARCBANK_ERROR_NONE,data)
		i = i + 1
	end
	fsReadTransactions = {}
	coroutine.yield() 

	i = 1
	while i < #fsReadBalance do
		local files = fsReadBalance[i]
		local callback = table.remove(files)
		local filename = table.remove(files)
		
		local money
		for k,v in iparis(files) do 
			local line = string.Explode( "\r\n", readLog(v))
			line[#line] = nil --Last line of a log is always blank
			
			local ii = #line
			while ii > 0 do
				local stuffs = string.Explode("\t",line[ii])
				if data[datalen].account1 == filename then
					money = tonumber(stuffs[8])
					if (money != nil) then
						break
					end
				end
				ii = ii - 1
			end
			if (money != nil) then
				break
			end
			coroutine.yield() 
		end
		if (money == nil) then
			callback(ARCBANK_ERROR_NIL_ACCOUNT)
		else
			callback(ARCBANK_ERROR_NONE,money)
		end
		
		i = i + 1
	end
	fsReadBalance = {}
	coroutine.yield() 
	
	i = 1
	while i < #fsReadMembers do
		local files = fsReadMembers[i]
		local callback = table.remove(files)
		local user = table.remove(files)
		
		local accounts = {}
		local accountslen = 0
		for k,v in iparis(files) do 
			if string.find(file.Read(ARCBank.Dir.."/groups_1.4/"..v,"DATA") or "",user,1,true) then
				accountslen = accountslen + 1
				accounts[accountslen] = string.sub(v,1,#v-4)
			end
			coroutine.yield() 
		end
		callback(ARCBANK_ERROR_NONE,accounts)
		i = i + 1
	end
	fsReadMembers = {}
	coroutine.yield() 
	
	i = 1
	while i < #fsReadOwners do
		local files = fsReadOwners[i]
		local callback = table.remove(files)
		local user = table.remove(files)
		
		local accounts = {}
		local accountslen = 0
		for k,v in iparis(files) do 
			local data = util.JSONToTable(file.Read(ARCBank.Dir.."/accounts_1.4/"..v,"DATA") or "")
			if data and data.owner == user then
				accountslen = accountslen + 1
				if data.rank < ARCBANK_GROUPACCOUNTS_ then
					table.insert(accounts,1,string.sub(v,1,#v-4))
				else
					accounts[accountslen] = string.sub(v,1,#v-4)
				end
			end
			coroutine.yield() 
		end
		callback(ARCBANK_ERROR_NONE,accounts)
		i = i + 1
	end
	fsReadOwners = {}
	coroutine.yield() 
	
	i = 1
	while i < #fsReadAllProperties do
		local files = fsReadAllProperties[i]
		local callback = table.remove(files)
		
		local accounts = {}
		local accountslen = 0
		for k,v in iparis(files) do 
			local data = util.JSONToTable(file.Read(ARCBank.Dir.."/accounts_1.4/"..v,"DATA") or "")
			if data then
				accountslen = accountslen + 1
				accounts[accountslen] = data
			end
			coroutine.yield() 
		end
		callback(ARCBANK_ERROR_NONE,accounts)
		i = i + 1
	end
	fsReadAllProperties = {}
	coroutine.yield() 
	
	--
	
	if lastClearCash <= CurTime() then
		logCache = {}
		lastClearCash = CurTime() + 20
	end
end)

local function createOldAccount(oldAccounts,i)
	local accountdata = oldAccounts[i]
	if not accountdata then
		ARCBank.Msg("Finished converting old accounts.")
		for _,plys in pairs(player.GetAll()) do
			ARCBank.MsgCL(plys,"Finished converting old accounts.")
		end
		return
	end
	ARCBank.Msg("Converting old accounts... ("..i.."/"..#oldAccounts..") DO NOT SHUT DOWN THE SERVER!")
	for _,plys in pairs(player.GetAll()) do
		ARCBank.MsgCL(plys,"Converting old accounts... ("..i.."/"..#oldAccounts..") DO NOT SHUT DOWN THE SERVER!")
	end
	local owner = accountdata.owner
	if not owner then
		owner = string.sub(accountdata.filename,9) -- strips account_ prefix which was dumb
		if string.StartWith( owner, string.lower(ARCBank.PlayerIDPrefix) ) then
			if (ARCBank.PlayerIDPrefix == "STEAM_") then
				owner = string.sub(owner,#ARCBank.PlayerIDPrefix+1)
				owner = ARCBank.PlayerIDPrefix..string.Replace( owner, "_", ":" )
			else
				owner = ARCBank.PlayerIDPrefix..string.sub(owner,#ARCBank.PlayerIDPrefix+1)
			end
		else
			ARCBank.Msg("FAILED TO CONVERT PERSONAL ACCOUNT! "..owner.." doesn't match Player ID Prefix "..ARCBank.PlayerIDPrefix)
			createOldAccount(oldAccounts,i+1)
			return
		end
	end
	ARCBank.WriteNewAccount(accountdata.name,owner,accountdata.rank,accountdata.money,"Converted from v1.0 system",function(errcode,filename)
		if errcode == ARCBANK_ERROR_NONE then
			if accountdata.isgroup then
				ARCLib.ForEachAsync(accountdata.members,function(k,v,callback)
					ARCBank.WriteGroupMemberAdd(filename,v,function(errcode) --I know I don't check errcode here shhh
						createOldAccount(oldAccounts,i+1)
					end)					
				end,function()
					createOldAccount(oldAccounts,i+1)
				end)
			else
				createOldAccount(oldAccounts,i+1)
			end
		elseif errcode == ARCBANK_ERROR_NAME_DUPE then
			ARCBank.Msg(accountdata.filename.." already exists in new system!")
			createOldAccount(oldAccounts,i+1)
		else
			ARCBank.Msg("Failed to create account - "..ARCBANK_ERRORSTRINGS[errcode])
		end
	end)
end
function ARCBank.ConvertOldAccounts()
	ARCBank.ConvertAncientAccounts()
	ARCBank.GetOldAccounts(function(errcode,data)
		if errcode == ARCBANK_ERROR_NONE then
			createOldAccount(data,1)
		else
			ARCBank.Loaded = false
			ARCBank.Msg("Failed to check for old accounts - "..ARCBANK_ERRORSTRINGS[errcode])
		end
	
	end)
end


function ARCBank.GetOldAccounts(callback)
	--accountdata.rank
	local accounts = {}
	if file.IsDir( ARCBank.Dir.."/accounts","DATA" ) then
		ARCBank.Msg("Converting v1.0 accounts to v1.4")
		if ARCBank.IsMySQLEnabled() then
			ARCBank.MySQL.Query("SELECT 1 FROM information_schema.TABLES WHERE (TABLE_SCHEMA = '"..ARCBank.MySQL.Escape(ARCBank.MySQL.DatabaseName).."') AND (TABLE_NAME = 'arcbank_personal_account');",function(err,data)
				if err then
					callback(ARCBANK_ERROR_READ_FAILURE)
				elseif #data == 0 then
					callback(ARCBANK_ERROR_NONE,{})
				else
					ARCBank.MySQL.Query("SELECT * FROM arcbank_group_account",function(didwork,data)
						if didwork then -- Even I cry when I read the next few lines of code... although not as much
							callback(ARCBANK_ERROR_READ_FAILURE)			
						else
							ARCBank.MySQL.Query("SELECT * FROM arcbank_account_members;",function(ddidwork,ddata)
								if ddidwork then
									callback(ARCBANK_ERROR_READ_FAILURE)	
								else
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
										table.insert( accounts, accountdata )
									end
									--
									ARCBank.MySQL.Query("SELECT * FROM arcbank_personal_account;",function(diditworkk,pdata)
										if diditworkk then
											callback(ARCBANK_ERROR_READ_FAILURE)
										else
											for _, accounttdata in pairs( pdata ) do
												accounttdata.money = tonumber(accounttdata.money)
												accounttdata.isgroup = tobool(accounttdata.isgroup)
												table.insert( accounts, accounttdata )
											end
											ARCBank.MySQL.Query("DROP TABLE IF EXISTS arcbank_group_account, arcbank_account_members, arcbank_personal_account;",function(err,data)
												if err then
													callback(ARCBANK_ERROR_WRITE_FAILURE)
												else
													callback(ARCBANK_ERROR_NONE,accounts)
												end
											end)
											ARCLib.DeleteAll(ARCBank.Dir.."/accounts")
											ARCLib.DeleteAll(ARCBank.Dir.."/accounts_unused")
										end
									end)
								end
							end)
						end
					end)
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
			local files, directories = file.Find( ARCBank.Dir.."/accounts_unused/group/*.txt","DATA" )
			for _,v in pairs( files ) do
				local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts_unused/group/"..v,"DATA"))
				table.insert(accounts, accountdata )
			end
			local files, directories = file.Find( ARCBank.Dir.."/accounts_unused/personal/*.txt","DATA" )
			for _,v in pairs( files ) do
				local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts_unused/personal/"..v,"DATA"))
				table.insert(accounts, accountdata )
			end
			callback(ARCBANK_ERROR_NONE,accounts)
			ARCLib.DeleteAll(ARCBank.Dir.."/accounts")
			ARCLib.DeleteAll(ARCBank.Dir.."/accounts_unused")
		end
	else
		callback(ARCBANK_ERROR_NONE,{})
	end
end
function ARCBank.ConvertAncientAccounts()
	if file.IsDir( ARCBank.Dir.."/group_account","DATA" ) || file.IsDir( ARCBank.Dir.."/personal_account","DATA" ) then
		ARCBank.Msg("Converting v0.9 accounts to v1.0")
		local OldFolders = {ARCBank.Dir.."/personal_account/standard/",ARCBank.Dir.."/personal_account/bronze/",ARCBank.Dir.."/personal_account/silver/",ARCBank.Dir.."/personal_account/gold/","NOPE",ARCBank.Dir.."/group_account/standard/",ARCBank.Dir.."/group_account/premium/"}
		for i = 1,4 do
			for k,v in pairs(file.Find(OldFolders[i].."*.txt","DATA")) do
				local oldaccountdata = util.JSONToTable(file.Read(OldFolders[i]..v,"DATA"))
				if oldaccountdata then
					if file.Exists(ARCBank.Dir.."/accounts/personal/"..v..".txt","DATA") then
						ARCBank.Msg(string.Replace(v,".txt","").." is already in the 1.0 filesystem! Account will be removed.")
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
				end
			end
		end
		
		
		for i = 6,7 do
			for k,v in pairs(file.Find(OldFolders[i].."*.txt","DATA")) do
				local oldaccountdata = util.JSONToTable(file.Read(OldFolders[i]..v,"DATA"))
				if oldaccountdata then
					if file.Exists(ARCBank.Dir.."/accounts/group/"..v..".txt","DATA") then
						ARCBank.Msg(string.Replace(v,".txt","").." is already in the 1.0 filesystem! Account will be removed.")
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
				end
			end
		end
		ARCLib.DeleteAll(ARCBank.Dir.."/group_account")
		ARCLib.DeleteAll(ARCBank.Dir.."/personal_account")
	end
end
