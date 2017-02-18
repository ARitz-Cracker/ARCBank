-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

-- I actually got off my ass and started to make ARCBank compatable with MySQL. 
-- After started, I realized that this... WILL BE HARD!	

local MYSQL_TYPE = 0

if system.IsLinux() then
	ARCBank.Msg(table.Random{"You know, I created a skin using LXDE that made ubuntu look like, sound like, and feel like windows 98.","GANOO/LOONIX","I <3 Linux","Linux is best","I don't like systemd."})
	if file.Exists( "lua/bin/gmsv_tmysql4_linux.dll", "MOD") then
		MYSQL_TYPE = 2
		require( "tmysql4" )
	elseif file.Exists( "lua/bin/gmsv_mysqloo_linux.dll", "MOD") then
		MYSQL_TYPE = 1
		require( "mysqloo" )
	end
	if file.Exists( "lua/bin/gmsv_mysqloo_win32.dll", "MOD") || file.Exists( "lua/bin/gmsv_tmysql4_win32.dll", "MOD") then
		ARCBank.Msg("...You do realize that you tried to install a windows .dll on a linux machine, right?")
	end
elseif system.IsWindows() then
	ARCBank.Msg(table.Random{"Windows server... >_>","I hope you aren't using a windows server by choice.","Once you learn a little bit more about computers in general, you'll hate windows server. (Unless you're an idiot.)"})
	if file.Exists( "lua/bin/gmsv_tmysql4_win32.dll", "MOD") then
		MYSQL_TYPE = 2
		require( "tmysql4" )
	elseif file.Exists( "lua/bin/gmsv_mysqloo_win32.dll", "MOD") then
		MYSQL_TYPE = 1
		require( "mysqloo" )
	end
	if file.Exists( "lua/bin/gmsv_mysqloo_linux.dll", "MOD") || file.Exists( "lua/bin/gmsv_tmysql4_linux.dll", "MOD") then
		ARCBank.Msg("...You do realize that you tried to install a linux .dll on a windows machine, right?")
	end
elseif system.IsOSX() then
	ARCBank.Msg("Is there even such a thing as an OSX server? Can it run mysqloo?")
end
--1.3: arcbank_account_members arcbank_personal_account arcbank_personal_account
local arcbank_log = [[CREATE TABLE IF NOT EXISTS arcbank_log
(
transaction_id BIGINT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
timestamp BIGINT UNSIGNED NOT NULL DEFAULT 0,
account1 varchar(255) NOT NULL,
account2 varchar(255) NOT NULL DEFAULT "",
user1 varchar(255) NOT NULL,
user2 varchar(255) NOT NULL DEFAULT "",
moneydiff BIGINT NOT NULL DEFAULT 0,
money BIGINT,
transaction_type SMALLINT UNSIGNED NOT NULL,
comment varchar(255) NOT NULL DEFAULT ""
) DEFAULT CHARSET=utf8;]]

local arcbank_accounts = [[CREATE TABLE IF NOT EXISTS arcbank_accounts
(
account varchar(255) PRIMARY KEY,
name varchar(255) NOT NULL,
owner varchar(255) NOT NULL,
rank TINYINT UNSIGNED NOT NULL
) DEFAULT CHARSET=utf8;]]

local arcbank_groups = [[CREATE TABLE IF NOT EXISTS arcbank_groups
(
account varchar(255) NOT NULL,
user varchar(255) NOT NULL,
CONSTRAINT pk_PersonID UNIQUE (account,user)
);]]

local arcbank_lock = [[CREATE TABLE IF NOT EXISTS arcbank_lock
(
account varchar(255) PRIMARY KEY
);]]
	
ARCBank = ARCBank or {}
ARCBank.Loaded = false
ARCBank.MySQL = {}
ARCBank.MySQL.EnableMySQL = false
ARCBank.MySQL.Host = "192.168.0.2"
ARCBank.MySQL.Username = "tester" 
ARCBank.MySQL.Password = "tester123"
ARCBank.MySQL.DatabaseName = "test_db"
ARCBank.MySQL.DatabasePort = 3306

function ARCBank.MySQL.Escape(str)
	if MYSQL_TYPE == 1 then
		return ARCBank.DataBase:escape(str)
	elseif MYSQL_TYPE == 2 then
		return ARCBank.DataBase:Escape(str)
	end
end

function ARCBank.MySQL.CreateQuery(str,succfunc,errfunc)
	if MYSQL_TYPE == 1 then
		local q = ARCBank.DataBase:query( str )
		function q:onSuccess( data )
			succfunc(data)
		end
		function q:onError( err, sqlq )
			errfunc(err,sqlq)
		end
		q:start()
	elseif MYSQL_TYPE == 2 then
		local function onCompleted( results )
			if #results == 1 then
				if results[1].status then
					succfunc(results[1].data)
				else
					errfunc(results[1].error,str)
				end
				--ARCBank.Msg("tmysql4 query took "..results[1].time.." seconds and affected "..results[1].affected.." rows with error "..tostring(results[1].error) )
			else
				ARCBank.Msg("I HAVE NO IDEA WHAT TO DO WITH THE RESULT TO QUERY: "..str)
				ARCBank.Msg("The result table was as follows:")
				PrintTable(results)
				ARCBank.Msg("Finished printing result to console.")
				errfunc("ARCBank tmysql4 support error!",str)
			end
		end
		ARCBank.DataBase:Query( str, onCompleted )
	end
end

local function InitOnError( err, sql )
	ARCBank.Loaded = false
	ARCBank.Busy = false
	ARCBank.Msg( "FAILED!! "..tostring(err) )
end
local function InitOnSuccess( data )
	ARCBank.Msg( "Everything appears to be A-OK!" )
	ARCBank.Loaded = true
	ARCBank.Busy = false
	ARCBank.Msg("ARCBank is ready!")
	ARCBank.ConvertOldAccounts()
	ARCBank.CapAccountRank()
end

local function InitGroupSuccess( data )
	ARCBank.Msg( "Checking if in-use accounts table exists..." )
	ARCBank.MySQL.CreateQuery(arcbank_lock,InitOnSuccess,InitOnError)
end

local function InitAccountSuccess( data )
	ARCBank.Msg( "Checking if group member table exists..." )
	ARCBank.MySQL.CreateQuery(arcbank_groups,InitGroupSuccess,InitOnError)
end

local function InitLogSuccess( data )
	ARCBank.Msg( "Checking if account properties table exists..." )
	ARCBank.MySQL.CreateQuery(arcbank_accounts,InitAccountSuccess,InitOnError)
end

function ARCBank.MySQL.Connect()
	ARCBank.Msg("INITIALIZING MYSQL SEQUENCE!")
	if MYSQL_TYPE == 0 then
		ARCBank.Msg("No suitable MySQL module has been found. This addon supports MySQLOO or tmysql4.")
		ARCBank.Msg("You can download MySQLOO v9 here: https://facepunch.com/showthread.php?t=1515853")
		return 
	end
	if MYSQL_TYPE == 2 then
		ARCBank.Msg("Still running tmysql4? Why not try MySQLOO v9? tmysql4 was abandoned by its creator and MySQLOO v9 fixed all the memory leaks and crash bugs that MySQLOO v8 had!")
		ARCBank.Msg("You can download MySQLOO v9 here: https://facepunch.com/showthread.php?t=1515853")
	end
	
	ARCBank.Msg("Connecting to database. Hopefully nothing blows up....")
	if MYSQL_TYPE == 1 then
		ARCBank.DataBase = mysqloo.connect( ARCBank.MySQL.Host, ARCBank.MySQL.Username, ARCBank.MySQL.Password, ARCBank.MySQL.DatabaseName, ARCBank.MySQL.DatabasePort )
		function ARCBank.DataBase:onConnectionFailed( err )
			ARCBank.Msg( "...SOMETHING BROKE! "..tostring(err) )
		end
		function ARCBank.DataBase:onConnected()
			ARCBank.Msg( "Database connected. So far so good!" )
			ARCBank.MySQL.CreateQuery(arcbank_log,InitLogSuccess,InitOnError)
		end
		ARCBank.DataBase:connect()
	elseif MYSQL_TYPE == 2 then
		local Database, err = tmysql.Connect(ARCBank.MySQL.Host, ARCBank.MySQL.Username, ARCBank.MySQL.Password, ARCBank.MySQL.DatabaseName, ARCBank.MySQL.DatabasePort, nil, CLIENT_MULTI_STATEMENTS)
		if err then
			ARCBank.Msg( "...SOMETHING BROKE! "..tostring(err) )
			ARCBank.Busy = false
		else
			ARCBank.DataBase = Database
			ARCBank.Msg( "Database connected. So far so good!" )
			ARCBank.Msg( "Checking if log table exists..." )
			ARCBank.MySQL.CreateQuery(arcbank_log,InitLogSuccess,InitOnError)
		end
	end
	

end
local ignorableErrors = {"Duplicate entry "}
local resetErrors = {}
function ARCBank.MySQL.Query(str,callback)
	local function onSuccess( data )
		callback(nil,data)
	end
	local function onError( err, sqlq )
		local ignoreError = false
		for k,v in ipairs(ignorableErrors) do
			if string.Left( err, #v ) == v then
				ignoreError = true
			end			
		end
		if ignoreError then
			ARCBank.Msg( "Ignoring MySQL Error: \""..tostring(err).."\" Query: \""..tostring(sqlq).."\"")
		else
			for _,plys in pairs(player.GetAll()) do
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL1)
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL2)
			end
		
			ARCBank.Msg( "MySQL ERROR: "..tostring(err))
			ARCBank.Msg( "In Query \""..tostring(sqlq).."\"")
			ARCBank.Msg(tostring(#err).." - "..tostring(#sqlq))
			local resetError = false
			for k,v in ipairs(resetErrors) do
				if string.Left( err, #v ) == v then
					resetError = true
				end			
			end
			if resetError then
				for _,plys in pairs(player.GetAll()) do
					ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL3)
				end
				ARCBank.Msg( "This error can be corrected by re-connecting to the MySQL server (which I am about to do)" )
				ARCBank.Msg( "If you're getting errors like this very consistently (like every 5 or 10 minutes) try increasing the connection time limit on the MySQL server" )
				ARCBank.Busy = true
				timer.Simple(5,function()
					if ARCBank.Loaded then return end
					ARCBank.MySQL.Connect()
					timer.Simple(15,function()
						if !ARCBank.Loaded then
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL4)
							end
						end
					end)
				end)
			else
				ARCBank.Msg( "REPORT THIS TO ARITZ CRACKER ASAP!!! (Unless it's your fault)" )
			end
			ARCBank.Loaded = false
		end
		callback(err)
	end
	ARCBank.MySQL.CreateQuery(str,onSuccess,onError)
end
--
function ARCBank.MySQL.RunCustomCommand(str)
	local function onSuccess( data )
		print( "Query successful!" )
		print(#data)
		PrintTable( data )
		if #data == 0 then
			print( "Blank table result" )
		end
	
	end
	
	local function onError( err, sql )

		print( "Query errored!" )
		print( "Query:", sql )
		print( "Error:", err )
	
	end

	ARCBank.MySQL.CreateQuery(str,onSuccess,onError)
end

ARCBank.Commands["mysql"] = { --TODO: FINISH
	command = function(ply,args) 
		if !ARCBank.Loaded then ARCBank.MsgCL(ply,"System reset required!") return end -- This is just to check if the ARCBank system is working properly. 
		if !ARCBank.IsMySQLEnabled() then ARCBank.MsgCL(ply,"MySQL must be enabled.") return end
		if (IsValid(ply) && ply:IsPlayer() && !ply:IsListenServerHost()) then
			ARCBank.MsgCL(ply,"This command cannot be used by a player.")
			return
		end
		if args[1] == "copy_to_database" then
			ARCBank.Msg(ARCBank.Msgs.CommandOutput.MySQLCopy)
			for _,plys in pairs(player.GetAll()) do
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopy)
			end
			ARCBank.Busy = true
			timer.Simple(1,function()
				local Queries = {}
				table.insert(Queries,"DELETE FROM arcbank_log;")
				table.insert(Queries,"DELETE FROM arcbank_accounts;")
				table.insert(Queries,"DELETE FROM arcbank_groups;")
				local logs = file.Find( ARCBank.Dir.."/logs_1.4/*", "DATA")
				local properties = file.Find( ARCBank.Dir.."/accounts_1.4/*", "DATA")
				local groups = file.Find( ARCBank.Dir.."/groups_1.4/*", "DATA")
				
				
				for k,v in ipairs(logs) do 
					local line = string.Explode( "\r\n", file.Read(ARCBank.Dir.."/logs_1.4/"..v) or "")
					line[#line] = nil --Last line of a log is always blank
					for kk,vv in ipairs(line) do
						local stuffs = string.Explode("\t",vv)
						
						local transaction_id = tonumber(stuffs[1]) or 0
						local timestamp = tostring(tonumber(stuffs[2]) or 0)
						local account1 = "'"..ARCBank.MySQL.Escape(stuffs[3]).."'"
						local account2 = "'"..ARCBank.MySQL.Escape(stuffs[4]).."'"
						local user1 = "'"..ARCBank.MySQL.Escape(stuffs[5]).."'"
						local user2 = "'"..ARCBank.MySQL.Escape(stuffs[6]).."'"
						local moneydiff = tostring(tonumber(stuffs[7]) or 0)
						local money = tonumber(stuffs[8])
						if money == nil then
							money = "NULL"
						else
							money = tostring(money)
						end
						local transaction_type = tostring(tonumber(stuffs[9]) or 0)
						local comment = "'"..ARCBank.MySQL.Escape(stuffs[10]).."'"
						
						table.insert(Queries,"INSERT INTO arcbank_log(timestamp,account1,account2,user1,user2,moneydiff,money,transaction_type,comment) VALUES("..timestamp..","..account1..","..account2..","..user1..","..user2..","..moneydiff..","..money..","..transaction_type..","..comment..");")
					end
				end
				
				for k,v in ipairs(properties) do 
					--""
					data = file.Read( ARCBank.Dir.."/accounts_1.4/"..v, "DATA")
					if !data or data == "" then
						ARCBank.Msg("Corrupted account "..v)
					else
						local accountdata = util.JSONToTable(data)
						table.insert(Queries,"INSERT INTO arcbank_accounts(account,name,owner,rank) VALUES('"..ARCBank.MySQL.Escape(tostring(accountdata.account)).."','"..ARCBank.MySQL.Escape(tostring(accountdata.name)).."','"..ARCBank.MySQL.Escape(tostring(accountdata.owner)).."',"..tonumber(accountdata.rank or 0)..");")
					end
				end
				for k,v in ipairs(groups) do 
					tab = string.Explode( ",", file.Read( ARCBank.Dir.."/groups_1.4/"..v, "DATA"))
					if tab and tab[2] then
						local account = string.sub(v,1,#v-4)
						tab[#tab] = nil --Last person is blank because lazy
						for kk,vv in ipairs(tab) do
							table.insert(Queries,"INSERT INTO arcbank_groups(account,user) VALUES('"..ARCBank.MySQL.Escape(account).."','"..ARCBank.MySQL.Escape(vv).."');")
						end	
					else
						ARCBank.Msg("Corrupted group list "..v)
					end
				end
				local recrusivecopy
				recrusivecopy = function(num)
					if num > #Queries then 
							ARCBank.Msg(ARCBANK_ERRORSTRINGS[0])
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,ARCBANK_ERRORSTRINGS[0])
							end
							ARCBank.Busy = false
						return 
					end
					ARCBank.MySQL.Query(Queries[num],function(err,data)
						if !err then
							ARCBank.Msg(ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/#Queries)*100))..")")
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/#Queries)*100))..")")
							end
							recrusivecopy(num+1)
						else
							ARCBank.Loaded = false
							ARCBank.Msg("[ERROR!] (%"..tostring(math.floor((num/#Queries)*100))..") Halting ARCBank. System reset required.")
							ARCBank.Msg(err)
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,"[ERROR!] (%"..tostring(math.floor((num/#Queries)*100))..") Halting ARCBank. System reset required.")
							end
						end
					end)
				end
				timer.Simple(1,function() recrusivecopy(1) end)
			end)

			ARCBank.Msg(ARCBank.Msgs.CommandOutput.MySQLCopy)
			for _,plys in pairs(player.GetAll()) do
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopy)
			end
		elseif args[1] == "copy_from_database" then
			ARCBank.Msg(ARCBank.Msgs.CommandOutput.MySQLCopyFrom)
			for _,plys in pairs(player.GetAll()) do
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopyFrom)
			end
			ARCBank.Busy = true
			ARCBank.ReadTransactions(nil,nil,nil,function(errcode,progress,data)
				if errcode == ARCBANK_ERROR_DOWNLOADING then return end
				if errcode == ARCBANK_ERROR_NONE then
					local datalen = #data
					local recrusivecopy
					recrusivecopy = function(num)
						if num > datalen then
							ARCBank.ReadAllAccountProperties(function(errcode,data)
								if errcode == ARCBANK_ERROR_NONE then
									local datalen = #data
									local recrusivecopyy
									recrusivecopyy = function(num)
										if num > datalen then
											ARCBank.Msg(ARCBANK_ERRORSTRINGS[0])
											for _,plys in pairs(player.GetAll()) do
												ARCBank.MsgCL(plys,ARCBANK_ERRORSTRINGS[0])
											end
											ARCBank.Busy = false
											return
										end
										if data[num].rank > ARCBANK_GROUPACCOUNTS_ then
											ARCBank.ReadGroupMembers(data[num].account,function(err,gdata)
												if err == ARCBANK_ERROR_NONE then
													local groupstr = ""
													for k,v in ipairs(gdata) do
														groupstr = groupstr .. v .. ","
													end
													file.Write(ARCBank.Dir.."/groups_1.4/"..tostring(data[num].account)..".txt",groupstr)
													file.Write(ARCBank.Dir.."/accounts_1.4/"..tostring(data[num].account)..".txt",util.TableToJSON(data[num]))
													
													ARCBank.Msg(ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/datalen)*50)+50)..")")
													for _,plys in pairs(player.GetAll()) do
														ARCBank.MsgCL(plys,ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/datalen)*50)+50)..")")
													end
													timer.Simple(0.0001,function() recrusivecopyy(num+1) end)
												else
													ARCBank.Msg("[ERROR!] ARCBank.ReadGroupMembers: "..ARCBANK_ERRORSTRINGS[errcode])
													for _,plys in pairs(player.GetAll()) do
														ARCBank.MsgCL(plys,"[ERROR!] ARCBank.ReadGroupMembers: "..ARCBANK_ERRORSTRINGS[errcode])
													end
												end
											end)
										else
											file.Write(ARCBank.Dir.."/accounts_1.4/"..tostring(data[num].account)..".txt",util.TableToJSON(data[num]))
											ARCBank.Msg(ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/datalen)*50)+50)..")")
											for _,plys in pairs(player.GetAll()) do
												ARCBank.MsgCL(plys,ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/datalen)*50)+50)..")")
											end
											timer.Simple(0.0001,function() recrusivecopyy(num+1) end)
										end
									end
									recrusivecopyy(1)
								else
									ARCBank.Msg("[ERROR!] ARCBank.ReadAllAccountProperties: "..ARCBANK_ERRORSTRINGS[errcode])
									for _,plys in pairs(player.GetAll()) do
										ARCBank.MsgCL(plys,"[ERROR!] ARCBank.ReadAllAccountProperties: "..ARCBANK_ERRORSTRINGS[errcode])
									end
								end
							end)
						else
							ARCBank.WriteTransaction(data[num].account1,data[num].account2,data[num].user1,data[num].user2,data[num].moneydiff,data[num].money,data[num].transaction_type,data[num].comment,function(errcode)
								if errcode == ARCBANK_ERROR_NONE then
									ARCBank.Msg(ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/datalen)*50))..")")
									for _,plys in pairs(player.GetAll()) do
										ARCBank.MsgCL(plys,ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/datalen)*50))..")")
									end
									recrusivecopy(num+1)
								else
									ARCBank.Msg("[ERROR!] (%"..tostring(math.floor((num/datalen)*50))..") "..ARCBANK_ERRORSTRINGS[errcode])
									for _,plys in pairs(player.GetAll()) do
										ARCBank.MsgCL(plys,"[ERROR!] (%"..tostring(math.floor((num/datalen)*50))..") "..ARCBANK_ERRORSTRINGS[errcode])
									end
								end
							end,data[num].timestamp,true)
						end
					end
					recrusivecopy(1)
				else
					ARCBank.Msg("[ERROR!] ARCBank.ReadTransactions: "..ARCBANK_ERRORSTRINGS[errcode])
					for _,plys in pairs(player.GetAll()) do
						ARCBank.MsgCL(plys,"[ERROR!] ARCBank.ReadTransactions: "..ARCBANK_ERRORSTRINGS[errcode])
					end
				end
			end)
		else
			MsgN("ARCBank: Invalid Command.")
		end
	end, 
	usage = " [command(string)]",
	description = "Copies local database to remote SQL and back.",
	adminonly = false,
	hidden = false}

