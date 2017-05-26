-- xtras.lua - Non-critical enhancment functions

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

function ARCBank.OnSettingChanged(key,val)
	if string.StartWith( key, "usergroup_" ) then
		for i=1,#val do
			print(val[i])
			val[i] = string.lower(val[i])
		end
	end
end

function ARCBank.CapAccountRank(ply)
	if not IsValid(ply) then
		ARCBank.FixInvalidAccountRanks(function()
			for k,v in ipairs(player.GetHumans()) do
				
				ARCBank.CapAccountRank(v)
			end
		end)
		return
	end
	local user1 = ARCBank.GetPlayerID(ply)
	if not user1 then return end
	ARCBank.ReadOwnedAccounts(user1,function(err,data)
		if err != ARCBANK_ERROR_NONE then return end
		if not IsValid(ply) then return end
		
		for i=1,#data do
			local account = data[i]
			ARCBank.ReadAccountProperties(account,function(err,data)
				if err != ARCBANK_ERROR_NONE then return end
				if not IsValid(ply) then return end
				local isgroup = data.rank > ARCBANK_GROUPACCOUNTS_
				local maxrank = ARCBank.MaxAccountRank(ply,isgroup)
				if maxrank == ARCBANK_PERSONALACCOUNTS_ or maxrank == ARCBANK_GROUPACCOUNTS_ then return end
				if data.rank > maxrank then
					ARCBank.WriteAccountProperties(account,nil,nil,maxrank,function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.WriteTransaction(account,nil,user1,nil,0,nil,ARCBANK_TRANSACTION_DOWNGRADE,"Usergroup Cap",NULLFUNC)
						end
					end)
				end
			end)
		end
	end)
end

function ARCBank.FixInvalidAccountRanks(callback)

	ARCBank.ReadAllAccountProperties(function(err,accounts)
		if err == ARCBANK_ERROR_NONE then
			ARCLib.ForEachAsync(accounts,function(k,accountdata,cb)
				local rank = 0
				if accountdata.rank == ARCBANK_PERSONALACCOUNTS_ then
					rank = ARCBANK_PERSONALACCOUNTS_STANDARD
				elseif accountdata.rank == ARCBANK_GROUPACCOUNTS_ then
					rank = ARCBANK_GROUPACCOUNTS_STANDARD
				end
				if rank > 0 then
					ARCBank.WriteAccountProperties(accountdata.account,nil,nil,rank,function(err)
						if err ~= ARCBANK_ERROR_NONE then
							ARCBank.Msg("Failed to correct invalid rank for "..accountdata.account..": "..ARCBANK_ERRORSTRINGS[err])
						end
						cb()
					end)
				else 
					cb()
				end
			end,function()
				callback()
			end)
		else
			callback()
		end
	end)
end
local fsReadAllProperties
local fsReadAllMembers
local fsReadCallback


local corruptThinkFunc = function() -- Look at this guy, re-inventing the wheel
	local fucked = false
	local corruptAccounts = {}
	local propertyTransactions = {}
	local memberTransactions = {}
	for k,v in ipairs(fsReadAllProperties) do 
		local data = util.JSONToTable(file.Read(ARCBank.Dir.."/accounts_1.4/"..v,"DATA") or "")
		local account1 = string.sub(v,1,-5)
		if not data then
			table.insert(corruptAccounts,account1)
			ARCBank.Msg(account1.." account properties are corrupt!")
			ARCBank.ReadTransactions(account1,0,bit.bor(ARCBANK_TRANSACTION_CREATE,ARCBANK_TRANSACTION_DELETE,ARCBANK_TRANSACTION_UPGRADE,ARCBANK_TRANSACTION_DOWNGRADE),function(err,progress,data)
				if (err == ARCBANK_ERROR_DOWNLOADING) then return end
				if (err == ARCBANK_ERROR_NONE) then
					propertyTransactions[account1] = data
				else
					ARCBank.Msg("Failed to get transaction history forrrr "..account1..": "..ARCBANK_ERRORSTRINGS[err])
					propertyTransactions[account1] = err
				end
			end)
		end
		coroutine.yield() 
	end
	for k,account1 in ipairs(corruptAccounts) do 
		while (propertyTransactions[account1] == nil) do
			coroutine.yield(true) -- Wait until transactions are retrieved. 
		end
		local log = propertyTransactions[account1]
		if (isnumber(log)) then
			ARCBank.Msg("Failed to get transaction history for "..account1..": "..ARCBANK_ERRORSTRINGS[log])
			continue --This is a GMod addon. I'm allowed to use this
		end
		if (log[1] and log[1].transaction_type == ARCBANK_TRANSACTION_CREATE) then
			local owner = log[1].user1
			local name
			local minrank
			local maxrank
			if string.sub(log[1].account1,1,1) == "_" then
				name = ARCLib.basexx.from_base32(string.upper(string.sub(log[1].account1,2,#log[1].account1-1)))
				minrank = ARCBANK_PERSONALACCOUNTS_STANDARD
				maxrank = ARCBANK_PERSONALACCOUNTS_GOLD
			else
				name = ARCLib.basexx.from_base32(string.upper(string.sub(log[1].account1,1,#log[1].account1-1)))
				minrank = ARCBANK_GROUPACCOUNTS_STANDARD
				maxrank = ARCBANK_GROUPACCOUNTS_PREMIUM
			end
			
			local exists = true
			local rank = minrank
			
			for i=2,#log do
				local entry = log[i]
				if entry.transaction_type == ARCBANK_TRANSACTION_DELETE then
					if not exists then
						ARCBank.Msg("Account "..account1.." Was deleted twice?? Looks like the logs are fucked.")
						fucked = true
						break
					end
					exists = false
				elseif entry.transaction_type == ARCBANK_TRANSACTION_CREATE then
					if exists then
						ARCBank.Msg("Account "..account1.." Was created twice?? Looks like the logs are fucked.")
						fucked = true
						break
					end
					exists = true
				elseif entry.transaction_type == ARCBANK_TRANSACTION_UPGRADE then
					if (rank < maxrank) then
						rank = rank + minrank
					else
						--Bitch about it if you want, but it's not important
					end
				elseif entry.transaction_type == ARCBANK_TRANSACTION_DOWNGRADE then
					rank = minrank
				end
				
				coroutine.yield()
			end
			if (fucked) then -- To this day, I have no idea how to break nested loops in Lua.
				break
			end
			file.Write(ARCBank.Dir.."/accounts_1.4/"..account1..".txt", util.TableToJSON({account=account1,owner=owner,name=name,rank=rank}))
			ARCBank.Msg("Recovered "..account1.." properties!")
			coroutine.yield()
		else
			ARCBank.Msg("First transaction for "..account1.." isn't the account being created? Looks like the logs are fucked.")
			fucked = true
			break
		end
		
	end
	propertyTransactions = nil
	
	if (fucked) then
		ARCBank.Loaded = false
		ARCBank.Busy = false
		ARCLib.RemoveThinkFunc("ARCBank ReadCorruptAccounts")
		ARCBank.Msg("CRITICAL ERROR: Account transaction logs are invalid! Unable to recover without the recovery information in the transaction logs! WE'RE DOOMED!! DOOOOOOOOOOOOMED!!!")
		return
	end
	
	corruptAccounts = {}
	for k,v in ipairs(fsReadAllMembers) do 
		local tab = string.Explode( ",", file.Read( ARCBank.Dir.."/groups_1.4/"..v, "DATA") or "")
		local account1 = string.sub(v,1,-5)
		if not (tab and tab[2]) then
			table.insert(corruptAccounts,account1)
			ARCBank.Msg(account1.." account members are corrupt!")
			ARCBank.ReadTransactions(account1,0,bit.bor(ARCBANK_TRANSACTION_GROUP_ADD,ARCBANK_TRANSACTION_GROUP_REMOVE),function(err,progress,data)
				if (err == ARCBANK_ERROR_DOWNLOADING) then return end
				if (err == ARCBANK_ERROR_NONE) then
					memberTransactions[account1] = data
				else
					memberTransactions[account1] = err
				end
			end)
		end
		coroutine.yield() 
	end

	for k,account1 in ipairs(corruptAccounts) do 
		while (memberTransactions[account1] == nil) do
			coroutine.yield(true) -- Wait until transactions are retrieved. 
		end
		local log = memberTransactions[account1]
		if (isnumber(log)) then
			ARCBank.Msg("Failed to get transaction history for "..account1..": "..ARCBANK_ERRORSTRINGS[log])
			continue --This is a GMod addon. I'm allowed to use this
		end
		local members = {}
		for i=1,#log do
			local entry = log[i]
			-- I could whine about OMG USER WAS ADDED/REMOVED TWICE!!1 but meh I just want to push this update.
			if entry.transaction_type == ARCBANK_TRANSACTION_GROUP_ADD then
				members[entry.user2] = true
			elseif entry.transaction_type == ARCBANK_TRANSACTION_GROUP_REMOVE then
				members[entry.user2] = nil
			end
		end
		local membersstr = ""
		for kk,vv in pairs(members) do
			membersstr = membersstr .. kk .. ","
		end
		ARCBank.Msg("Recovered "..account1.." members!")
		if (#membersstr == 0) then
			file.Delete(ARCBank.Dir.."/groups_1.4/"..account1..".txt")
		else
			file.Write(ARCBank.Dir.."/groups_1.4/"..account1..".txt", membersstr)
		end
	end
	ARCBank.Msg("Account corruption check complete!")
	if isfunction(fsReadCallback) then
		fsReadCallback()
	end
	fsReadAllProperties = nil
	fsReadAllMembers = nil
	fsReadCallback = nil
	ARCBank.Busy = false
	ARCLib.RemoveThinkFunc("ARCBank ReadCorruptAccounts")
end

function ARCBank.CheckForCorruptAccounts(callback)
	if (fsReadAllProperties) then
		error("Attempted to check for corrupted accounts while already checking for corrupted accounts!",2)
	end
	if (not ARCBank.Settings.account_corruption_check) then
		ARCBank.Msg("ARCBank.Settings.account_corruption_check is disabled. Will not check for corrupted accounts.")
		callback()
		return
	end
	if (ARCBank.IsMySQLEnabled()) then
		ARCBank.Msg("MySQL is enabled, no need to check for corrupted accounts.")
		callback()
		return
	end
	ARCBank.Busy = true
	ARCBank.Msg("Checking for corrupted accounts. ARCBank will be in \"busy\" mode during this time.")
	ARCBank.Msg("You can always disable the \"account_corruption_check\" setting and re-enable it when players are reporting corrupt accounts.")
	
	fsReadAllProperties = file.Find(ARCBank.Dir.."/accounts_1.4/*","DATA")
	fsReadAllMembers = file.Find(ARCBank.Dir.."/groups_1.4/*","DATA")
	fsReadCallback = callback
	ARCLib.AddThinkFunc("ARCBank ReadCorruptAccounts",corruptThinkFunc)
end


