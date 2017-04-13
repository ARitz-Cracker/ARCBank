-- accnt.lua - Accounts and File manager

-- This file is under copyright.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016-2017 Aritz Beobide-Cardinal All rights reserved.

-- Group members are stored seperatly from group accounts
-- 
--[[
Ventz: please add a feature
Ventz: to list accounts in order of balance
Ventz: cos its useful to find ppl who somehow glitched money
Ventz: if that ever happens#
]]

local function specialAccess(ply,readPerm)
	return (isentity(ply) and IsValid(ply) and ply:IsPlayer() and (table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) or (table.HasValue(ARCBank.Settings.moderators,string.lower(ply:GetUserGroup())) and (readPerm or not ARCBank.Settings.moderators_read_only) ))) or ply == "__SYSTEM" or ply == "__UNKNOWN"
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
		accnt = "_"..string.lower(ARCLib.basexx.to_base32(ply)).."_"
	elseif string.sub(accnt,#accnt) != "_" then -- If not already encoded
		accnt = string.lower(ARCLib.basexx.to_base32(accnt)).."_"
	end
	return ply,accnt
end


function ARCBank.PurgeAccounts(callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("DROP TABLE arcbank_log;",function(err,data)
			if err then
				ARCBank.Msg(err)
				callback(ARCBANK_ERROR_WRITE_FAILURE)
			else
				ARCBank.MySQL.Query("DROP TABLE arcbank_accounts;",function(err,data)
					if err then
						ARCBank.Msg(err)
						callback(ARCBANK_ERROR_WRITE_FAILURE)
					else
						ARCBank.MySQL.Query("DROP TABLE arcbank_groups;",function(err,data)
							if err then
								ARCBank.Msg(err)
								callback(ARCBANK_ERROR_WRITE_FAILURE)
							else
								ARCBank.MySQL.Query("DROP TABLE arcbank_lock;",function(err,data)
									if err then
										callback(ARCBANK_ERROR_WRITE_FAILURE)
									else
										callback(ARCBANK_ERROR_NONE)
										ARCBank.Loaded = false
									end
								end)
							end
						end)
					end
				end)
			end
		end)
	else
		ARCLib.DeleteAll(ARCBank.Dir.."/accounts_1.4")
		ARCLib.DeleteAll(ARCBank.Dir.."/groups_1.4")
		ARCLib.DeleteAll(ARCBank.Dir.."/logs_1.4")
		callback(ARCBANK_ERROR_NONE)
		ARCBank.Loaded = false
	end
	ARCLib.DeleteAll(ARCBank.Dir.."/syslogs")
end

function ARCBank.GetAccountName(account,callback)
	assert(isstring(account),"ARCBank.GetAccountName: Argument #1 is not a string")
	assert(isfunction(callback),"ARCBank.GetAccountName: Argument #2 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			callback(ARCBANK_ERROR_NONE,data.name)
		else
			callback(err)
		end
	end)
end
function ARCBank.ChangeAccountName(ply,account,name,callback)
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sc = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	if #name >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner == ply or sc then
				ARCBank.WriteAccountProperties(account,name,nil,nil,callback)
			else
				callback(ARCBANK_ERROR_NO_ACCESS)
			end
		else
			callback(err)
		end
	end)
end
function ARCBank.UpgradeAccount(ply,account,callback)
	assert(isstring(account),"ARCBank.UpgradeAccount: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.UpgradeAccount: Argument #3 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sc = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner == ply or sc then
				if data.rank == ARCBANK_GROUPACCOUNTS_PREMIUM or data.rank == ARCBANK_PERSONALACCOUNTS_GOLD then
					callback(ARCBANK_ERROR_INVALID_RANK)
				else
					ARCBank.WriteAccountProperties(account,nil,nil,data.rank+1,function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.WriteTransaction(account,nil,ply,nil,0,nil,ARCBANK_TRANSACTION_UPGRADE,nil,callback)
						else
							callback(err)
						end
					end)
				end
			else
				callback(ARCBANK_ERROR_NO_ACCESS)
			end
		else
			callback(err)
		end
	end)
end
function ARCBank.DowngradeAccount(ply,account,callback)
	assert(isstring(groupname),"ARCBank.DowngradeAccount: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.DowngradeAccount: Argument #3 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sc = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner == ply or sc then
				if data.rank == ARCBANK_PERSONALACCOUNTS_STANDARD or data.rank == ARCBANK_GROUPACCOUNTS_STANDARD then
					callback(ARCBANK_ERROR_INVALID_RANK)
				else
					ARCBank.WriteAccountProperties(account,nil,nil,data.rank-1,function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.WriteTransaction(account,nil,ply,nil,0,nil,ARCBANK_TRANSACTION_DOWNGRADE,nil,callback)
						else
							callback(err)
						end
					end)
				end
			else
				callback(ARCBANK_ERROR_NO_ACCESS)
			end
		else
			callback(err)
		end
	end)
end
local hackValue = {}
hackValue[ARCBANK_PERSONALACCOUNTS_STANDARD] = 1
hackValue[ARCBANK_PERSONALACCOUNTS_BRONZE] = 2
hackValue[ARCBANK_GROUPACCOUNTS_STANDARD] = 3
hackValue[ARCBANK_PERSONALACCOUNTS_SILVER] = 4
hackValue[ARCBANK_PERSONALACCOUNTS_GOLD] = 5
hackValue[ARCBANK_GROUPACCOUNTS_PREMIUM] = 6
local function hackSortFunc(a,b)
	return (hackValue[a.rank] or 0) < (hackValue[b.rank] or 0)
end


local function hackAccount(moneyToHack,accounts,keys,i,brokeAccounts,hackedAmount,callback)
	ARCBank.WriteBalanceAdd(accounts[keys[i]].account,nil,"__UNKNOWN",nil,-moneyToHack[keys[i]],ARCBANK_TRANSACTION_WITHDRAW_OR_DEPOSIT,"",function(err)
		if err == ARCBANK_ERROR_NONE then
			hackedAmount = hackedAmount + moneyToHack[keys[i]]
			if i >= #keys then
				callback(ARCBANK_ERROR_NONE,1,hackedAmount) 
			else
				moneyToHack[keys[i]] = 0
				callback(ARCBANK_ERROR_DOWNLOADING,i/#keys,nil) 
				hackAccount(moneyToHack,accounts,keys,i+1,brokeAccounts,hackedAmount,callback)
			end
		elseif err == ARCBANK_ERROR_NO_CASH or err == ARCBANK_ERROR_DEADLOCK or err == ARCBANK_ERROR_NIL_ACCOUNT then
			local newkey = keys[i]
			local money = moneyToHack[newkey]
			moneyToHack[newkey] = nil
			brokeAccounts[newkey] = true
			if table.Count( brokeAccounts ) >= #accounts then
				callback(ARCBANK_ERROR_NONE,1,hackedAmount) --All accounts are broke, return what we got
				return
			end
			while brokeAccounts[newkey] do
				newkey = ARCLib.RandomExp(1,#accounts)
			end
			if not moneyToHack[newkey] then
				moneyToHack[newkey] = 0
			end
			table.RemoveByValue( keys, newkey ) 
			keys[i] = newkey
			moneyToHack[newkey] = moneyToHack[newkey] + money
			hackAccount(moneyToHack,accounts,keys,i,brokeAccounts,hackedAmount,callback) -- Now that we swapped the broke account for something else, let's try that again
		else
			callback(err)
		end
	end)
end

--
function ARCBank.StealMoney(ply,multiple,amount,callback)
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ARCBank.ReadAllAccountProperties(function(errcode,accounts)
		if errcode != ARCBANK_ERROR_NONE then
			callback(errcode)
			return
		end
		table.sort( accounts, hackSortFunc )
		local moneyToHack = {}
		local brokeAccounts = {}
		local keys = {}
		if multiple then
			local len = math.floor(amount/25)
			for i=1,len do
				local acct = ARCLib.RandomExp(1,#accounts)
				if not moneyToHack[acct] then
					keys[#keys+1] = acct
					moneyToHack[acct] = 0
				end
				moneyToHack[acct] = moneyToHack[acct] + 25
			end
		else
			local acct = ARCLib.RandomExp(1,#accounts)
			moneyToHack[acct] = amount
			keys[#keys+1] = acct
		end
		hackAccount(moneyToHack,accounts,keys,1,brokeAccounts,0,callback)
	end)
end
function ARCBank.AddFromWallet(ply,account,amount,comment,callback,transaction_type)
	assert(isstring(account),"ARCBank.AddFromWallet: Argument #2 is not a string")
	assert(isnumber(amount),"ARCBank.AddFromWallet: Argument #3 is not a number")
	assert(isstring(comment),"ARCBank.AddFromWallet: Argument #4 is not a string")
	assert(isfunction(callback),"ARCBank.AddFromWallet: Argument #5 is not a function")
	transaction_type = tonumber(transaction_type) or ARCBANK_TRANSACTION_WITHDRAW_OR_DEPOSIT
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	if not IsValid(ply) or not ply:IsPlayer() then
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return
	end
	if amount > 0 and !ARCBank.PlayerCanAfford(ply,amount) then
		callback(ARCBANK_ERROR_NO_CASH_PLAYER)
		return
	end
	ARCBank.AddMoney(ply,account,amount,transaction_type,comment,function(err)
		if err == ARCBANK_ERROR_NONE then
			if amount > 0 and !ARCBank.PlayerCanAfford(ply,amount) then
				ARCBank.AddMoney(ply,account,-amount,transaction_type,"Wallet was unable to afford the previous transaction",function(err)
					ARCBank.FuckIdiotPlayer(ply,"Dropped cash while depositing cash in bank account")
					if err == ARCBANK_ERROR_NONE then
						callback(ARCBANK_ERROR_NO_CASH_PLAYER)
					else
						ARCBank.Msg("WARNING! WARNING! WARNING! Unable to correct bank account balance after exploit attempt! "..ARCBANK_ACCOUNTSTRINGS[err])
						callback(err)
					end
				end)
				return
			end
			ARCBank.PlayerAddMoney(ply,-amount)
		end
		callback(err)
	end)
end

local function UnlockAccouts(account1,account2,callback)
	ARCBank.UnlockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.UnlockAccount(account2,callback)
		else
			callback(err)
		end
	end)
end

function ARCBank.Transfer(plyfrom,plyto,accountfrom,accountto,amount,comment,callback)
	assert(isstring(accountfrom),"ARCBank.Transfer: Argument #3 is not a string")
	assert(isstring(accountto),"ARCBank.Transfer: Argument #4 is not a string")
	assert(isnumber(amount),"ARCBank.Transfer: Argument #5 is not a number")
	assert(isstring(comment),"ARCBank.Transfer: Argument #6 is not a string")
	assert(isfunction(callback),"ARCBank.Transfer: Argument #7 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	if amount < 0 then
		callback(ARCBANK_ERROR_EXPLOIT)
		return
	end
	plyfrom,accountfrom = sterilizePlayerAccount(plyfrom,accountfrom)
	plyto,accountto = sterilizePlayerAccount(plyto,accountto)
	if not plyfrom then
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return
	end
	if not plyto then
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return
	end
	if #accountfrom >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if #accountto >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if accountfrom == accountto then
		timer.Simple(5, function() callback(ARCBANK_ERROR_NONE) end) -- Usually I wouldn't take the Windows route of wasting people's time, but someone who actually does this has to take some time to think about what they've done
		return
	end
	ARCBank.GetAccountProperties(plyfrom,accountfrom,function(err,fromdata)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.GetAccountProperties(plyto,accountto,function(err,todata)
				if err == ARCBANK_ERROR_NONE then
					if amount == 0 then
						callback(ARCBANK_ERROR_NONE) --Confirmed both accounts are accessable, but locking out accounts for reasons like these is stupid
						return
					end
					ARCBank.LockAccount(accountfrom,function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.LockAccount(accountto,function(err)
								if err == ARCBANK_ERROR_NONE then
									ARCBank.ReadBalance(accountfrom,function(err,moneyfrom)
										if err == ARCBANK_ERROR_NONE then
											local totalfrom = moneyfrom - amount
											if totalfrom + ARCBank.Settings.account_debt_limit < 0 then
												callback(ARCBANK_ERROR_NO_CASH)
												UnlockAccouts(accountfrom,accountto,NULLFUNC) -- Hope it works
											else
												ARCBank.ReadBalance(accountto,function(err,moneyto)
													if err == ARCBANK_ERROR_NONE then
														local totalto = moneyto + amount
														if totalto > (ARCBank.Settings["money_max_"..todata.rank.."_"..ARCBANK_ACCOUNTSTRINGS[todata.rank]] or 99999999999999) then
															callback(ARCBANK_ERROR_TOO_MUCH_CASH)
															UnlockAccouts(accountfrom,accountto,NULLFUNC) -- Hope it works
														else
															ARCBank.WriteTransaction(accountfrom,accountto,plyfrom,plyto,-amount,totalfrom,ARCBANK_TRANSACTION_TRANSFER,comment,function(err)
																if err == ARCBANK_ERROR_NONE then
																	ARCBank.WriteTransaction(accountto,accountfrom,plyto,plyfrom,amount,totalto,ARCBANK_TRANSACTION_TRANSFER,comment,function(err)
																		if err == ARCBANK_ERROR_NONE then
																			UnlockAccouts(accountfrom,accountto,callback) 
																		else
																			UnlockAccouts(accountfrom,accountto,NULLFUNC) -- Hope it works
																			callback(err)
																		end
																	end)
																else
																	UnlockAccouts(accountfrom,accountto,NULLFUNC) -- Hope it works
																	callback(err)
																end
															end)
														end
													else
														UnlockAccouts(accountfrom,accountto,NULLFUNC) -- Hope it works
														callback(err)
													end
												end)
											end
										else
											UnlockAccouts(accountfrom,accountto,NULLFUNC) -- Hope it works
											callback(err)
										end
									end)
								else
									ARCBank.UnlockAccount(accountfrom,NULLFUNC) -- Hope it works
									callback(err)
								end
							end)
						else
							callback(err)
						end
					end)
				else
					callback(err)
				end
			end,true)
		else
			callback(err)
		end
	end,true)
end

function ARCBank.AddMoney(ply,account,amount,transaction_type,comment,callback)
	assert(isstring(account),"ARCBank.CanAfford: Argument #2 is not a string")
	assert(isnumber(amount),"ARCBank.CanAfford: Argument #3 is not a number")
	assert(isstring(comment),"ARCBank.CanAfford: Argument #5 is not a string")
	assert(isfunction(callback),"ARCBank.CanAfford: Argument #6 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ARCBank.GetAccountProperties(ply,account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if amount == 0 then
				callback(ARCBANK_ERROR_NONE) --Confirmed both accounts are accessable, but locking out accounts for reasons like these is stupid
				return
			end
			ply, account = sterilizePlayerAccount(ply,account)
			ARCBank.WriteBalanceAdd(account,nil,ply,nil,amount,tonumber(transaction_type) or ARCBANK_TRANSACTION_OTHER,comment,callback,true,ARCBank.Settings["money_max_"..data.rank.."_"..ARCBANK_ACCOUNTSTRINGS[data.rank]])
		else
			callback(err)
		end
	end,true)
end
function ARCBank.CanAfford(ply,account,amount,callback)
	assert(isstring(account),"ARCBank.CanAfford: Argument #2 is not a string")
	assert(isnumber(amount),"ARCBank.CanAfford: Argument #3 is not a number")
	assert(isfunction(callback),"ARCBank.CanAfford: Argument #4 is not a function")
	ARCBank.GetBalance(ply,account,function(err,money)
		if err == ARCBANK_ERROR_NONE then
			if (money - amount) + ARCBank.Settings.account_debt_limit >= 0 then
				callback(ARCBANK_ERROR_NONE)
			else
				callback(ARCBANK_ERROR_NO_CASH)
			end
		else
			callback(err)
		end
	end,true)
end

function ARCBank.GetBalance(ply,account,callback,sa_internal)
	assert(isstring(account),"ARCBank.GetBalance: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.GetBalance: Argument #3 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ARCBank.GetAccountProperties(ply,account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			ply, account = sterilizePlayerAccount(ply,account)
			ARCBank.ReadBalance(account,callback,true) -- We can ignore checking if the account exists since it obviously does as we just got the permissions!!!
		else
			callback(err)
		end
	end,sa_internal)
end
function ARCBank.GetLog(ply,account,timestamp,transaction_type,callback)
	assert(isstring(account),"ARCBank.GetLog: Argument #2 is not a string")
	assert(isnumber(timestamp),"ARCBank.GetLog: Argument #3 is not a number")
	assert(isnumber(transaction_type),"ARCBank.GetLog: Argument #4 is not a number")
	assert(isfunction(callback),"ARCBank.GetLog: Argument #5 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	--ply, account = sterilizePlayerAccount(ply,account)
	--if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.GetAccountProperties(ply,account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			ply, account = sterilizePlayerAccount(ply,account)
			ARCBank.ReadTransactions(account,timestamp,transaction_type,callback)
		else
			callback(err)
		end
	end)
end

function ARCBank.GetAccessableAccounts(ply,callback)
	assert(isfunction(callback),"ARCBank.GetAccessableAccounts: Argument #2 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ply = sterilizePlayerAccount(ply,"")
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadOwnedAccounts(ply,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadMemberedAccounts(ply,function(err,data2)
				if err == ARCBANK_ERROR_NONE then
					table.Add( data, data2 )
					callback(ARCBANK_ERROR_NONE,data)
				else
					callback(err)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.GetGroupAccounts(ply,callback)
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ply = sterilizePlayerAccount(ply,"")
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadMemberedAccounts(ply,callback)
end
function ARCBank.GetOwnedAccounts(ply,callback)
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	ply = sterilizePlayerAccount(ply,"")
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadOwnedAccounts(ply,callback)
end

function ARCBank.GroupGetPlayers(ply,account,callback)
	assert(isstring(account),"ARCBank.GroupGetPlayers: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.GroupGetPlayers: Argument #3 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sa = specialAccess(ply,true)
	ply, account = sterilizePlayerAccount(ply,account)
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadAccountProperties(account,function(err,accountdata)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadGroupMembers(account,function(errcode,data)
				if errcode == ARCBANK_ERROR_NONE then
					if sa or accountdata.owner == ply or table.HasValue(data,ply) then
						callback(ARCBANK_ERROR_NONE,data)
					else
						callback(ARCBANK_ERROR_NO_ACCESS)
					end
				else
					callback(errcode)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.GroupRemovePlayer(ply,account,otherply,comment,callback)
	assert(isstring(account),"ARCBank.GroupRemovePlayer: Argument #2 is not a string")
	--assert(isstring(otherply) or (IsValid(otherply) and otherply:IsPlayer()),"ARCBank.GroupRemovePlayer: Argument #3 is not a string or player")
	assert(isstring(comment),"ARCBank.GroupRemovePlayer: Argument #4 is not a string")
	assert(isfunction(callback),"ARCBank.GroupRemovePlayer: Argument #5 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sa = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	otherply = sterilizePlayerAccount(otherply)
	if !otherply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner != ply and not sa then
				callback(ARCBANK_ERROR_NO_ACCESS)
				return
			end
			ARCBank.ReadGroupMembers(account,function(errcode,data)
				if errcode == ARCBANK_ERROR_NONE then
					if table.HasValue(data,otherply) then
						ARCBank.WriteGroupMemberRemove(account,otherply,function(errcode)
							if errcode == ARCBANK_ERROR_NONE then
								ARCBank.WriteTransaction(account,nil,ply,otherply,0,nil,ARCBANK_TRANSACTION_GROUP_REMOVE,nil,callback)
							else
								callback(errcode)
							end
						end)
					else
						callback(ARCBANK_ERROR_NIL_PLAYER)
					end
				else
					callback(errcode)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.GroupAddPlayer(ply,account,otherply,comment,callback)
	assert(isstring(account),"ARCBank.GroupAddPlayer: Argument #2 is not a string")
	--assert(isstring(otherply) or (IsValid(otherply) and otherply:IsPlayer()),"ARCBank.GroupAddPlayer: Argument #3 is not a string or player")
	assert(isstring(comment),"ARCBank.GroupAddPlayer: Argument #4 is not a string")
	assert(isfunction(callback),"ARCBank.GroupAddPlayer: Argument #5 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sa = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	otherply = sterilizePlayerAccount(otherply)
	if !otherply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	ARCBank.ReadAccountProperties(account,function(err,accountdata)
		if err == ARCBANK_ERROR_NONE then
			if accountdata.owner != ply and not sa then
				callback(ARCBANK_ERROR_NO_ACCESS)
				return
			end
			if accountdata.owner == otherply then
				callback(ARCBANK_ERROR_DUPE_PLAYER)
				return
			end
			ARCBank.ReadGroupMembers(account,function(errcode,data)
				if errcode == ARCBANK_ERROR_NONE then
					if #data >= ARCBank.Settings["account_group_member_limit"] then
						callback(ARCBANK_ERROR_TOO_MANY_PLAYERS)
					elseif table.HasValue(data,otherply) then
						callback(ARCBANK_ERROR_DUPE_PLAYER)
					else
						ARCBank.ReadMemberedAccounts(otherply,function(errcode,data)
							if errcode == ARCBANK_ERROR_NONE then
								if #data < (192-ARCBank.Settings["account_group_limit"]) then
									ARCBank.WriteGroupMemberAdd(account,otherply,function(errcode)
										if errcode == ARCBANK_ERROR_NONE then
											ARCBank.WriteTransaction(account,nil,ply,otherply,0,nil,ARCBANK_TRANSACTION_GROUP_ADD,nil,callback)
										else
											callback(errcode)
										end
									end)
								else
									callback(ARCBANK_ERROR_TOO_MANY_ACCOUNTS)
								end
							else
								callback(errcode)
							end
						end)
					end
				else
					callback(errcode)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.CreateAccount(ply,groupname,rank,callback)
	assert(isstring(groupname),"ARCBank.CreateAccount: Argument #2 is not a string")
	assert(isnumber(rank),"ARCBank.CreateAccount: Argument #3 is not a number")
	assert(isfunction(callback),"ARCBank.CreateAccount: Argument #4 is not a function")
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	if not IsValid(ply) or not ply:IsPlayer() then
		callback(ARCBANK_ERROR_NIL_PLAYER)
		return
	end
	local newb = true
	if table.HasValue(ARCBank.Settings["usergroup_all"],string.lower(ply:GetUserGroup())) then
		newb = false
	end
	
	if newb then
		if rank < ARCBANK_GROUPACCOUNTS_ then
			for i=rank,ARCBANK_PERSONALACCOUNTS_GOLD do
				if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],string.lower(ply:GetUserGroup())) then
					newb = false
					break
				end
			end
		else
			for i=rank,ARCBANK_GROUPACCOUNTS_PREMIUM do
				if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],string.lower(ply:GetUserGroup())) then
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
	local plyid = ARCBank.GetPlayerID(ply)
	ARCBank.ReadOwnedAccounts(plyid,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			local accounts = #data
			local hasPersonalAccount = false
			for i=1,#data do
				if string.StartWith( data[i], "_" ) then
					hasPersonalAccount = true
					break
				end					
			end
			if rank < ARCBANK_GROUPACCOUNTS_ then
				if hasPersonalAccount then
					callback(ARCBANK_ERROR_NAME_DUPE)
				else
					ARCBank.WriteNewAccount(name,plyid,rank,initbalance,name,callback)
				end
			else
				if hasPersonalAccount then
					accounts = accounts - 1
				end
				if accounts < ARCBank.Settings.account_group_limit then
					ARCBank.WriteNewAccount(name,plyid,rank,initbalance,name,callback)
				else
					callback(ARCBANK_ERROR_TOO_MANY_ACCOUNTS)
				end
			end
		else
			callback(err)
		end
	end)
end
function ARCBank.RemoveAccount(ply,account,comment,callback)
	assert(isstring(groupname),"ARCBank.RemoveAccount: Argument #2 is not a string")
	assert(isstring(reason),"ARCBank.RemoveAccount: Argument #3 is not a string")
	assert(isfunction(callback),"ARCBank.RemoveAccount: Argument 4 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sa = specialAccess(ply)
	ply, account = sterilizePlayerAccount(ply,account)
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
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


function ARCBank.CanAccessAccount(ply,account,callback,sa_internal)
	assert(isstring(account),"ARCBank.GetAccountProperties: Argument #2 is not a string")
	assert(isfunction(callback),"ARCBank.GetAccountProperties: Argument #3 is not a function")
	if ARCBank.Busy then callback(ARCBANK_ERROR_BUSY) return end
	local sc = specialAccess(ply,not sa_internal)
	ply, account = sterilizePlayerAccount(ply,account)
	if !ply then callback(ARCBANK_ERROR_NIL_PLAYER) return end
	if #account >= 255 then
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NAME_TOO_LONG) end)
	end
	ARCBank.ReadAccountProperties(account,function(err,data)
		if err == ARCBANK_ERROR_NONE then
			if data.owner == ply or sc then
				callback(ARCBANK_ERROR_NONE,data)
			elseif data.rank > ARCBANK_GROUPACCOUNTS_ then
				ARCBank.ReadGroupMembers(account,function(err,gdata)
					if err == ARCBANK_ERROR_NONE then
						if table.HasValue(gdata,ply) then
							callback(ARCBANK_ERROR_NONE,data)
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
ARCBank.GetAccountProperties = ARCBank.CanAccessAccount

--ANYTHING BELOEW THIS POINT IS FOR INTERNAL USE ONLY


function ARCBank.IntergrityCheck(callback)
	-- Check if all transfers have matches
	-- Check if created account logs have properties or deleted log entries
	-- Check if group members match up with logs
	-- Check for locked accounts
	callback(ARCBANK_ERROR_NONE)
end

local function accountInterest(accounts,i,callback)
	if i <= #accounts then
		ARCBank.ReadTransactions(accounts[i].account,os.time()-(ARCBank.Settings["account_interest_time_limit"]*86400),bit.band(ARCBANK_TRANSACTION_EVERYTHING,bit.bnot(ARCBANK_TRANSACTION_INTEREST)),function(errcode,progress,data)
			if errcode == ARCBANK_ERROR_NONE then
				if #data > 0 then
					local interest = ARCBank.Settings["interest_"..accounts[i].rank.."_"..ARCBANK_ACCOUNTSTRINGS[accounts[i].rank]] or 0
					ARCBank.WriteBalanceMultiply(accounts[i].account,nil,"__SYSTEM",nil,1+(interest/100),ARCBANK_TRANSACTION_INTEREST,interest.."%",function(err)
						if err != ARCBANK_ERROR_NONE --[[ and err != ARCBANK_ERROR_NO_CASH ]] then
							ARCBank.Msg("Failed to give interest to "..accounts[i].account.." - "..ARCBANK_ERRORSTRINGS[err])
						else
							ARCBank.Msg("Gave interest to "..accounts[i].account)
						end
						accountInterest(accounts,i + 1,callback)
					end,ARCBank.Settings["interest_perpetual_debt"])
				else
					ARCBank.Msg(accounts[i].account.." is unused")
					accountInterest(accounts,i + 1,callback)
				end
			elseif errcode != ARCBANK_ERROR_DOWNLOADING then
				ARCBank.Msg("Failed to give interest to "..accounts[i].account..". "..ARCBANK_ERRORSTRINGS[errcode])
				accountInterest(accounts,i + 1,callback)
			end
		end)
	else
		ARCBank.Msg("Interest finished")
		callback()
	end
end

function ARCBank.AddAccountInterest(callback)
	if !isfunction(callback) then callback = NULLFUNC end
	if !ARCBank.Loaded then return end
	if ARCBank.Busy then return end
	if !ARCBank.Settings["interest_enable"] then return end
	ARCBank.Msg("Giving out bank interest...")
	ARCBank.ReadAllAccountProperties(function(errcode,data)
		if errcode == ARCBANK_ERROR_NONE then
			accountInterest(data,1,callback)
		else
			ARCBank.Msg("Failed to get list of all accounts ("..errcode..")")
			callback()
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
		ARCBank.MySQL.Query("SELECT * FROM arcbank_accounts WHERE owner='"..ARCBank.MySQL.Escape(user).."' ORDER BY rank ASC;",function(err,data)
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
		fsReadOwners[#fsReadOwners + 1] = files
	end
end
local fsReadMembers = {}
function ARCBank.ReadMemberedAccounts(user,callback)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_groups WHERE user='"..ARCBank.MySQL.Escape(user).."';",function(err,data)
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
		fsReadMembers[#fsReadMembers + 1] = files
	end
end

function ARCBank.EraseAccount(account,person,comment,callback,curbal)
	curbal = tonumber(curbal)
	if curbal then
		curbal = -curbal
	end
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
	name = string.Replace( string.Replace( string.Replace( tostring(name), "\n", " " ), "\r", " " ), "\t", " " )
	owner = tostring(owner)
	amount = tonumber(amount) or 0
	rank = tonumber(rank) or 1
	local account
	if rank < ARCBANK_GROUPACCOUNTS_ then
		account = "_"..string.lower(ARCLib.basexx.to_base32(owner)).."_"
	else
		account = string.lower(ARCLib.basexx.to_base32(name)).."_"
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
				ARCBank.MySQL.Query("INSERT INTO arcbank_accounts(account,name,owner,rank) VALUES('"..ARCBank.MySQL.Escape(account).."','"..ARCBank.MySQL.Escape(name).."','"..ARCBank.MySQL.Escape(owner).."',"..rank..");",cb)
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

function ARCBank.WriteAccountProperties(account,name,owner,rank,callback)
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
		q = string.sub(q,1,#q-1).." WHERE account='"..ARCBank.MySQL.Escape(tostring(account)).."';"
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

function ARCBank.WriteBalanceMultiply(account1,account2,user1,user2,amount,transaction_type,comment,callback,allowdebt,maxcash)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if allowdebt == nil then allowdebt = true end
	ARCBank.LockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadBalance(account1,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					local total = math.floor(currentbalance * amount)
					local difference = total - currentbalance
					if total + ARCBank.Settings.account_debt_limit*ARCLib.BoolToNumber(allowdebt) < 0 then
						ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
						callback(ARCBANK_ERROR_NO_CASH)
					elseif amount > 1 and total > (maxcash or 99999999999999) then
						ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
						callback(ARCBANK_ERROR_TOO_MUCH_CASH)
					else
						ARCBank.WriteTransaction(account1,account2,user1,user2,difference,total,transaction_type,comment,function(err)
							if err == ARCBANK_ERROR_NONE then
								ARCBank.UnlockAccount(account1,callback)
							else
								callback(err)
							end
						end)
					end
				else
					ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
					callback(err)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.WriteBalanceAdd(account1,account2,user1,user2,amount,transaction_type,comment,callback,allowdebt,maxcash)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if allowdebt == nil then allowdebt = true end
	ARCBank.LockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadBalance(account1,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					local total = currentbalance + amount
					if amount < 0 and total + ARCBank.Settings.account_debt_limit*ARCLib.BoolToNumber(allowdebt) < 0 then
						ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
						callback(ARCBANK_ERROR_NO_CASH)
					elseif amount > 0 and total > (maxcash or 99999999999999) then
						ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
						callback(ARCBANK_ERROR_TOO_MUCH_CASH)
					else
						ARCBank.WriteTransaction(account1,account2,user1,user2,amount,total,transaction_type,comment,function(err)
							if err == ARCBANK_ERROR_NONE then
								ARCBank.UnlockAccount(account1,callback)
							else
								callback(err)
							end
						end)
					end
				else
					ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
					callback(err)
				end
			end)
		else
			callback(err)
		end
	end)
end

function ARCBank.WriteBalanceSet(account1,account2,user1,user2,amount,transaction_type,comment,callback,allowdebt,maxcash)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if allowdebt == nil then allowdebt = true end
	ARCBank.LockAccount(account1,function(err)
		if err == ARCBANK_ERROR_NONE then
			ARCBank.ReadBalance(account1,function(err,currentbalance)
				if err == ARCBANK_ERROR_NONE then
					if amount + ARCBank.Settings.account_debt_limit*ARCLib.BoolToNumber(allowdebt) < 0 then
						ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
						callback(ARCBANK_ERROR_NO_CASH)
					elseif amount > (maxcash or 99999999999999) then
						ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
						callback(ARCBANK_ERROR_TOO_MUCH_CASH)
					else
						local difference = amount - currentbalance
						ARCBank.WriteTransaction(account1,account2,user1,user2,difference,amount,transaction_type,comment,function(err)
							if err == ARCBANK_ERROR_NONE then
								ARCBank.UnlockAccount(account1,callback)
							else
								callback(err)
							end
						end)
					end
				else
					ARCBank.UnlockAccount(account1,NULLFUNC) -- Hope it works
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
function ARCBank.WriteTransaction(account1,account2,user1,user2,moneydiff,money,transaction_type,comment,callback,time_override,no_mysql_override)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	moneydiff = tonumber(moneydiff)
	--This was from when I decided 
	--[[
	if moneydiff and math.abs(moneydiff) > 2147483647 then
		callback(ARCBANK_ERROR_MONEYDIFF_TOO_BIG)
		return
	end
	]]
	time_override = tonumber(time_override) or os.time()
	if ARCBank.IsMySQLEnabled() and !no_mysql_override then
		local keys = "INSERT INTO arcbank_log(timestamp"
		local values = "VALUES ("..time_override
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
			if money and (moneydiff != 0 or transaction_type == 128) then
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
				moneydiff = moneydiff or 0
				if tonumber(transaction_type) != ARCBANK_TRANSACTION_TRANSFER or moneydiff > 0 then
					hook.Call( "ARCBank_OnTransaction", GM, tonumber(transaction_type) or 0, account1 or "", account2 or "", user1 or "", user2 or "", moneydiff, tonumber(money), comment or "")
				end
			end
		end)
	else
		if currentLogFile == "" then
			currentLogs = file.Find( ARCBank.Dir.."/logs_1.4/*", "DATA")
			if #currentLogs == 0 then
				currentLogFile = ARCBank.Dir.."/logs_1.4/"..time_override..".txt"
				currentLogLine = 1
			else
				currentLogFile = ARCBank.Dir.."/logs_1.4/"..currentLogs[#currentLogs]
				
				currentLogLine = #string.Explode("\r\n",file.Read(currentLogFile,"DATA"))
				if currentLogLine > 4096 then
					currentLogFile = ARCBank.Dir.."/logs_1.4/"..time_override..".txt"
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
		--10+12+255+255+255+255+10+10+2+255
		file.Append( currentLogFile, ((currentLogsLen-1)*4096+currentLogLine).."\t"..time_override.."\t"..(account1 or "").."\t"..(account2 or "").."\t"..(user1 or "").."\t"..(user2 or "").."\t"..(tonumber(moneydiff) or "0").."\t"..(tonumber(money) or "").."\t"..(tonumber(transaction_type) or "").."\t"..string.Replace( comment or "", "\r\n", "" ).."\r\n" )
		--transaction_type,account1,account2,user1,user2,money_difference,money,comment
		if currentLogLine >= 4096 then
			currentLogFile = ARCBank.Dir.."/logs_1.4/"..time_override..".txt"
			currentLogLine = 1
		else
			currentLogLine = currentLogLine + 1
		end
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE) end)
		moneydiff = moneydiff or 0
		if tonumber(transaction_type) != ARCBANK_TRANSACTION_TRANSFER or moneydiff > 0 then
			hook.Call( "ARCBank_OnTransaction", GM, tonumber(transaction_type) or 0, account1 or "", account2 or "", user1 or "", user2 or "", moneydiff, tonumber(money), comment or "")
		end
	end
end
function ARCBank.UnDeadlock(account,callback)
	ARCBank.GetLockedAccounts(function(err,accounts)
		if err == ARCBANK_ERROR_NONE then
			if table.HasValue(accounts,account) then
				ARCBank.ReadBalance(account,function(err,data)
					if data.transaction_type == ARCBANK_TRANSACTION_TRANSFER and data.user2 != "" and data.user2 != "__SYSTEM" and data.user2 != "__UNKNOWN" then
						if data.moneydiff >= 0 then -- Money is taken from the giver before given to the receiver. If we've received the money, we can assume the transaction was completed.
							ARCBank.UnlockAccount(account,function(err)
								if err == ARCBANK_ERROR_NONE then
									if table.HasValue(accounts,data.account2) then
										ARCBank.UnlockAccount(data.account2,callback) -- Might as well undeadlock that account while we're at it
									else
										callback(err)
									end
								else
									callback(err)
								end
							end)
						else
							if table.HasValue(accounts,data.account2) then
								ARCBank.ReadBalance(data.account2,function(err,dataa)
									if dataa.transaction_type == ARCBANK_TRANSACTION_TRANSFER and dataa.account2 == data.account1 and -data.moneydiff == dataa.moneydiff and dataa.comment==data.comment then
										ARCBank.UnlockAccount(account,function(err)
											if err == ARCBANK_ERROR_NONE then
												ARCBank.UnlockAccount(data.account2,callback) -- Might as well undeadlock that account while we're at it
											else
												callback(err)
											end
										end)
									else -- The giver's account is unlocked BEFORE the receiver. If the giver's account was deadlocked, we can assume that they have not received the transfer yet
										ARCBank.WriteBalanceAdd(data.account2,data.account1,data.user2,data.user1,-data.moneydiff,ARCBANK_TRANSACTION_TRANSFER,data.comment,function(err)
											if err == ARCBANK_ERROR_NONE then
												ARCBank.UnlockAccount(account,function(err)
													if err == ARCBANK_ERROR_NONE then
														ARCBank.UnlockAccount(data.account2,callback) -- Might as well undeadlock that account while we're at it
													else
														callback(err)
													end
												end)
											else
												callback(err)
											end
										end)
									end
								end,false,true)
							else
								ARCBank.UnlockAccount(account,callback) -- Since the receiver is not locked and the givers account is locked before the receiver, we can conclude that this is in fact an older transaction and whatever "new" transaction didn't initiate yet
							end
						end
					else
						ARCBank.UnlockAccount(account,callback) -- Transaction was not a transfer no extra checks necessary
					end
				end,false,true)
			else
				callback(ARCBANK_ERROR_NIL_ACCOUNT)
			end
		else
			callback(err)
		end
	end)
end


local loackedAccounts = {}
function ARCBank.GetLockedAccounts(callback)

	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("SELECT * FROM arcbank_lock;",function(err,ddata)
			if err then
				callback(ARCBANK_ERROR_READ_FAILURE)
			else
				local result = {}
				for i=1,#ddata do
					result[i] = ddata[i].account
				end
				callback(ARCBANK_ERROR_NONE,result)
			end
		end)
	else
		local result = {}
		local i = 0
		for k,v in pairs(loackedAccounts) do
			i = i + 1
			result[i] = k
		end
		timer.Simple(0.0001, function() callback(ARCBANK_ERROR_NONE,result) end)
	end
end

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
local DupeSQLError = "Duplicate entry "
function ARCBank.LockAccount(filename,callback,retries)
	if not ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	retries = retries or 0
	if ARCBank.IsMySQLEnabled() then
		ARCBank.MySQL.Query("INSERT INTO arcbank_lock(account) VALUES('"..ARCBank.MySQL.Escape(filename).."');",function(err,ddata)
			if err then
				if string.Left( err, #DupeSQLError ) == DupeSQLError then
					if retries > 20 then 
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
			if retries > 20 then 
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
			if tab and tab[2] then
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
function ARCBank.ReadBalance(filename,callback,ignorecheck,fulltransaction)
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	if ARCBank.IsMySQLEnabled() then
		--local function res(errcode)
			--if errcode == ARCBANK_ERROR_NONE then
				ARCBank.MySQL.Query("SELECT * FROM arcbank_log where money IS NOT NULL AND account1='"..ARCBank.MySQL.Escape(filename).."' ORDER BY transaction_id DESC LIMIT 1;",function(err,data)
					if err then
						callback(ARCBANK_ERROR_READ_FAILURE)
					else
						if #data == 0 then
							callback(ARCBANK_ERROR_NIL_ACCOUNT)
						else
							if fulltransaction then
								callback(ARCBANK_ERROR_NONE,data[1])
							else
								callback(ARCBANK_ERROR_NONE,tonumber(data[1].money)) -- Some MySQL modules convert BIGINT to string. I don't want that.
							end
						end
					end
				end)
			--else
			--	callback(errcode)
			--end
		--end
		--if ignorecheck then
		--	res(ARCBANK_ERROR_NONE)
		--else
		--	ARCBank.ReadAccountProperties(filename,res)
		--end
	else
		local fullpath = ARCBank.Dir.."/accounts_1.4/"..tostring(filename)..".txt"
		if ignorecheck or file.Exists( fullpath, "DATA" ) then
			local files = table.Reverse(currentLogs)
			local i = #files
			
			i = i + 1
			files[i] = fulltransaction or false
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
	ttype = tonumber(ttype) or 0
	ttype = bit.band( ttype, ARCBANK_TRANSACTION_EVERYTHING ) -- Clamp it to 16 bit
	--print("ttype:",ttype)
	if ARCBank.IsMySQLEnabled() then
		local q = "SELECT * FROM arcbank_log WHERE timestamp >= "..timestamp
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
				callback(ARCBANK_ERROR_NONE,1,data)
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
	while i <= #fsReadTransactions do
		local files = fsReadTransactions[i]
		local callback = table.remove(files)
		local ttype = table.remove(files)
		local timestampstart = table.remove(files)
		local filename = table.remove(files)
		
		local datalen = 0
		local data = {}
		for k,v in ipairs(files) do 
			local line = string.Explode( "\r\n", readLog(v) or "")
			
			coroutine.yield()
			line[#line] = nil --Last line of a log is always blank
			for kk,vv in ipairs(line) do
				local stuffs = string.Explode("\t",vv)
				local transaction_type = tonumber(stuffs[9])
				local timestamp = tonumber(stuffs[2]) or 0
				local account1 = stuffs[3]
				
				if (filename == "" or account1 == filename) and (ttype == 0 or bit.band(transaction_type,ttype) > 0) and timestamp >= timestampstart then
					datalen = datalen + 1
					data[datalen] = {}
					data[datalen].transaction_id = tonumber(stuffs[1]) or 0
					data[datalen].timestamp = tonumber(stuffs[2]) or 0
					data[datalen].account1 = account1
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
		timer.Simple(0.001,function() callback(ARCBANK_ERROR_NONE,1,data) end)
		i = i + 1
	end
	fsReadTransactions = {}
	coroutine.yield() 

	i = 1
	while i <= #fsReadBalance do
		local files = fsReadBalance[i]
		local callback = table.remove(files)
		local filename = table.remove(files)
		local fulltransaction = table.remove(files)
		
		local money
		for k,v in ipairs(files) do 
			local line = string.Explode( "\r\n", readLog(v))
			line[#line] = nil --Last line of a log is always blank
			
			local ii = #line
			local stuffs
			while ii > 0 do
				stuffs = string.Explode("\t",line[ii])
				if stuffs[3] == filename then
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
			timer.Simple(0.001,function() callback(ARCBANK_ERROR_NIL_ACCOUNT) end)
		else
			if fulltransaction then
				transaction = {}
				transaction.transaction_id = tonumber(stuffs[1]) or 0
				transaction.timestamp = tonumber(stuffs[2]) or 0
				transaction.account1 = stuffs[3]
				transaction.account2 = stuffs[4]
				transaction.user1 = stuffs[5]
				transaction.user2 = stuffs[6]
				transaction.moneydiff = tonumber(stuffs[7]) or 0
				transaction.money = tonumber(stuffs[8])
				transaction.transaction_type = tonumber(stuffs[9]) or 0
				transaction.comment = stuffs[10]
				timer.Simple(0.001,function() callback(ARCBANK_ERROR_NONE,transaction) end)
			else
				timer.Simple(0.001,function() callback(ARCBANK_ERROR_NONE,money) end)
			end
		end
		
		i = i + 1
	end
	fsReadBalance = {}
	coroutine.yield() 
	
	i = 1
	while i <= #fsReadMembers do
		local files = fsReadMembers[i]
		local callback = table.remove(files)
		local user = table.remove(files)
		
		local accounts = {}
		local accountslen = 0
		for k,v in ipairs(files) do 
			if string.find(file.Read(ARCBank.Dir.."/groups_1.4/"..v,"DATA") or "",user,1,true) then
				accountslen = accountslen + 1
				accounts[accountslen] = string.sub(v,1,#v-4)
			end
			coroutine.yield() 
		end
		timer.Simple(0.001,function() callback(ARCBANK_ERROR_NONE,accounts) end)
		i = i + 1
	end
	fsReadMembers = {}
	coroutine.yield() 
	
	i = 1
	while i <= #fsReadOwners do
		local files = fsReadOwners[i]
		local callback = table.remove(files)
		local user = table.remove(files)
		
		local accounts = {}
		local accountslen = 0
		for k,v in ipairs(files) do 
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
		timer.Simple(0.001,function() callback(ARCBANK_ERROR_NONE,accounts) end)
		i = i + 1
	end
	fsReadOwners = {}
	coroutine.yield() 
	
	i = 1
	while i <= #fsReadAllProperties do
		local files = fsReadAllProperties[i]
		local callback = table.remove(files)
		
		local accounts = {}
		local accountslen = 0
		for k,v in ipairs(files) do 
			local data = util.JSONToTable(file.Read(ARCBank.Dir.."/accounts_1.4/"..v,"DATA") or "")
			if data then
				accountslen = accountslen + 1
				accounts[accountslen] = data
			end
			coroutine.yield() 
		end
		timer.Simple(0.001,function() callback(ARCBANK_ERROR_NONE,accounts) end)
		i = i + 1
	end
	fsReadAllProperties = {}
	coroutine.yield() 
	
	--
	
	if lastClearCash <= CurTime() then
		logCache = {}
		lastClearCash = CurTime() + 20
		collectgarbage()
	end
end)

local function createOldAccount(oldAccounts,i)
	local accountdata = oldAccounts[i]
	if not accountdata then
		ARCBank.Msg("Finished converting old accounts.")
		for _,plys in ipairs(player.GetAll()) do
			ARCBank.MsgCL(plys,"Finished converting old accounts.")
		end
		ARCBank.Busy = false
		return
	end
	ARCBank.Msg("Converting old accounts... ("..i.."/"..#oldAccounts..") DO NOT SHUT DOWN THE SERVER!")
	for _,plys in ipairs(player.GetAll()) do
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
	ARCBank.WriteNewAccount(accountdata.name,owner,accountdata.rank,accountdata.money,"Converted from an older version of ARCBank",function(errcode,filename)
		if errcode == ARCBANK_ERROR_NONE then
			if accountdata.isgroup then
				ARCLib.ForEachAsync(accountdata.members,function(k,v,callback)
					ARCBank.WriteGroupMemberAdd(filename,v,function(errcode) --I know I don't check errcode here shhh
						callback()
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
			if #data > 0 then
				ARCBank.Busy = true
				createOldAccount(data,1)
			else
				ARCBank.Msg("No bank accounts from v1.3.8 or older have been found.")
			end
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
				if accountdata then
					table.insert(accounts, accountdata )
				else
					ARCBank.Msg(ARCBank.Dir.."/accounts/group/"..v.." is corrupt. Not converting.")
				end
			end
			local files, directories = file.Find( ARCBank.Dir.."/accounts/personal/*.txt","DATA" )
			for _,v in pairs( files ) do
				local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts/personal/"..v,"DATA"))
				if accountdata then
					table.insert(accounts, accountdata )
				else
					ARCBank.Msg(ARCBank.Dir.."/accounts/personal/"..v.." is corrupt. Not converting.")
				end
			end
			local files, directories = file.Find( ARCBank.Dir.."/accounts_unused/group/*.txt","DATA" )
			for _,v in pairs( files ) do
				local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts_unused/group/"..v,"DATA"))
				if accountdata then
					table.insert(accounts, accountdata )
				else
					ARCBank.Msg(ARCBank.Dir.."/accounts_unused/group/"..v.." is corrupt. Not converting.")
				end
			end
			local files, directories = file.Find( ARCBank.Dir.."/accounts_unused/personal/*.txt","DATA" )
			for _,v in pairs( files ) do
				local accountdata = util.JSONToTable(file.Read( ARCBank.Dir.."/accounts_unused/personal/"..v,"DATA"))
				if accountdata then
					table.insert(accounts, accountdata )
				else
					ARCBank.Msg(ARCBank.Dir.."/accounts_unused/personal/"..v.." is corrupt. Not converting.")
				end
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
