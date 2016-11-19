-- accnt.lua - Accounts and File manager

-- This file is under copyright.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016 Aritz Beobide-Cardinal All rights reserved.

-- Group members are stored seperatly from group accounts
-- 
--[[
__p_
1 - Withdraw/deposit
2 - Transfer
4 - Interest
8 - Upgrade
16 - Downgrade
32 - Add member
64 - Remove member

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
account varchar(255),
user varchar(255)
);

CREATE TABLE arcbank_lock
(
account_id varchar(255) PRIMARY KEY
}
]]


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
		if file.Exists( fullpath, "DATA" ) 
			data = file.Read( fullpath, "DATA")
			if !data || data == "" then 
				timer.Simple(0.0001, function() callback(ARCBANK_ERROR_CORRUPT_ACCOUNT) end)
			else
				local tab = util.JSONToTable(data)
				if tab then
					tab.money = tonumber(tab.money)
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

local fsReadTransactions = {}
function ARCBank.ReadTransactions(filename,timestamp,ttype,callback) -- TODO: LIKE clause to search through transactions?
	if !ARCBank.Loaded then callback(ARCBANK_ERROR_NOT_LOADED) return end
	timestamp = tonumber(timestamp) or 0
	filename = filename or ""
	ttype = ttype or 0
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
		local files = file.Find( ARCBank.Dir.."/logs_1.4/*", "DATA" )
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
ARCLib.AddThinkFunc("ARCBank ReadTransactions",function()
	local i = 1
	while i < #fsReadTransactions do
		local files = fsReadTransactions[i]
		local callback = table.remove(files)
		local timestamp = table.remove(files)
		local ttype = table.remove(files)
		local filename = table.remove(files)
		for k,v in iparis(files) do 
			local line = string.Explode( "\r\n", file.Read(ARCBank.Dir.."/logs_1.4/"..v))
		end
		
		i = i + 1
	end
	fsReadTransactions = {}
	coroutine.yield() 


end)


function ARCBank.ConvertOldAccounts()
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
					
					--ARCBank.WriteAccountFile(datatadada)
					--
					--ARCBank.AccountExists(ARCBank.GetAccountID(string.Replace(v,".txt" "")),false)
				end
			end
		end
		ARCLib.DeleteAll(ARCBank.Dir.."/group_account")
		ARCLib.DeleteAll(ARCBank.Dir.."/personal_account")
	end
end





