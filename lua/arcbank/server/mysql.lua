-- This file is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
-- However, you must credit me.

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
transaction_id UNSIGNED BIGINT NOT NULL AUTO_INCREMENT,
timestamp UNSIGNED BIGINT NOT NULL,
account1 varchar(255) NOT NULL,
account2 varchar(255) NOT NULL,
user1 varchar(255) NOT NULL,
user2 varchar(255) NOT NULL,
moneydiff BIGINT NOT NULL,
money BIGINT,
transaction_type UNSIGNED SMALLINT NOT NULL,
comment varchar(255) NOT NULL
);]]

local arcbank_accounts = [[CREATE TABLE IF NOT EXISTS arcbank_accounts
(
account varchar(255) PRIMARY KEY,
name varchar(255) NOT NULL,
owner varchar(255) NOT NULL,
rank UNSIGNED TINYINT NOT NULL
);]]

local arcbank_groups = [[CREATE TABLE IF NOT EXISTS arcbank_groups
(
account varchar(255) NOT NULL,
user varchar(255) NOT NULL,
CONSTRAINT pk_PersonID UNIQUE (account,user)
);]]

local arcbank_lock = [[CREATE TABLE arcbank_lock
(
account varchar(255) PRIMARY KEY
}]]
	
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
		else
			ARCBank.DataBase = Database
			ARCBank.Msg( "Database connected. So far so good!" )
			ARCBank.Msg( "Checking if log table exists..." )
			ARCBank.MySQL.CreateQuery(arcbank_log,InitLogSuccess,InitOnError)
		end
	end
	

end
local ignorableErrors = {}
local resetErrors = {}
function ARCBank.MySQL.Query(str,callback)
	local function onSuccess( data )
		callback(nil,data)
	end
	
	local function onError( err, sqlq )
		if not ignorableErrors[err] then
			for _,plys in pairs(player.GetAll()) do
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL1)
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL2)
			end
		
			ARCBank.Msg( "MySQL ERROR: "..tostring(err))
			ARCBank.Msg( "In Query ("..tostring(sqlq)..")")
			ARCBank.Msg(tostring(#err).." - "..tostring(#sqlq))
		
			if resetErrors[err] then
				for _,plys in pairs(player.GetAll()) do
					ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL3)
				end
				ARCBank.Msg( "This error can be corrected by re-connecting to the MySQL server (which I am about to do)" )
				ARCBank.Msg( "If you're getting errors like this very consistently (like every 5 or 10 minutes) try increasing the connection time limit on the MySQL server" )
				timer.Simple(5,function()
					if ARCBank.Loaded then return end
					ARCBank.MySQL.Connect()
					timer.Simple(5,function()
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
		if (IsValid(ply) && ply:IsPlayer() && !ply:IsListenServerHost()) then -- For Singleplayer and localhost testing. Note: Remove SteamID when released.
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
				table.insert(Queries,"DELETE FROM arcbank_log")
				table.insert(Queries,"DELETE FROM arcbank_accounts")
				table.insert(Queries,"DELETE FROM arcbank_groups")
				local logs = file.Find( ARCBank.Dir.."/logs_1.4/*", "DATA")
				local properties = file.Find( ARCBank.Dir.."/accounts_1.4/*", "DATA")
				local groups = file.Find( ARCBank.Dir.."/groups_1.4/*", "DATA")
				
				
			for k,v in ipairs(logs) do 
				local line = string.Explode( "\r\n", file.Read(ARCBank.Dir.."/logs_1.4/"..v) or "")
				line[#line] = nil --Last line of a log is always blank
				for kk,vv in ipairs(line) do
					local stuffs = string.Explode("\t",vv)
					
					local timestamp = tonumber(stuffs[2]) or 0
					local account1 = stuffs[3]
					local account2 = stuffs[4]
					local transaction_type = tonumber(stuffs[9])
					--local = stuffs[5]
						data[datalen].user2 = stuffs[6]
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
				
				local iii = 1
				
				local function recrusivecopy(num)
					if num > #Queries then 
							ARCBank.Msg(ARCBANK_ERRORSTRINGS[0])
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,ARCBANK_ERRORSTRINGS[0])
							end
							ARCBank.Busy = false
						return 
					end
					ARCBank.MySQL.Query(Queries[num],function(didwork,reason)
						if didwork then
							ARCBank.Msg(ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/#Queries)*100))..")")
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/#Queries)*100))..")")
							end
							iii = iii + 1
							recrusivecopy(iii)
						else
							ARCBank.Loaded = false
							ARCBank.Msg("[ERROR!] (%"..tostring(math.floor((num/#Queries)*100))..") Halting ARCBank. System reset required.")
							for _,plys in pairs(player.GetAll()) do
								ARCBank.MsgCL(plys,"[ERROR!] (%"..tostring(math.floor((num/#Queries)*100))..") Halting ARCBank. System reset required.")
							end
						end
					end)
				end
				timer.Simple(2,function() recrusivecopy(iii) end)
			end)
		elseif args[1] == "copy_from_database" then
			ARCBank.Msg(ARCBank.Msgs.CommandOutput.MySQLCopyFrom)
			for _,plys in pairs(player.GetAll()) do
				ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopyFrom)
			end
			ARCBank.GetAllAccountsUnordered(true,function(errcode,accounts)
				ARCBank.Busy = true
				if errcode == 0 then
					for k,v in pairs(accounts) do
						v.money = tostring(v.money)
						v.isgroup = tobool(v.isgroup)
						if v.isgroup then
							--v.members = string.Explode(" ",v.members)
							--if v.members[1] == "" then v.members = {} end
							file.Write( ARCBank.Dir.."/accounts/group/"..v.filename..".txt", util.TableToJSON(v) )
						else
							file.Write( ARCBank.Dir.."/accounts/personal/"..v.filename..".txt", util.TableToJSON(v) )
						end
					end
					ARCBank.Msg(ARCBANK_ERRORSTRINGS[0])
					for _,plys in pairs(player.GetAll()) do
						ARCBank.MsgCL(plys,ARCBANK_ERRORSTRINGS[0])
					end
					ARCBank.Busy = false
				else
					ARCBank.Msg("[ERROR!] "..tostring(errcode))
					for _,plys in pairs(player.GetAll()) do
						ARCBank.MsgCL(plys,"[ERROR!] "..tostring(errcode))
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

