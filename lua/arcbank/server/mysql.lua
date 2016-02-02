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

	
ARCBank = ARCBank or {}
ARCBank.Loaded = false
ARCBank.MySQL = {}
ARCBank.MySQL.EnableMySQL = false
ARCBank.MySQL.Host = "127.0.0.1"
ARCBank.MySQL.Username = "root" 
ARCBank.MySQL.Password = "password"
ARCBank.MySQL.DatabaseName = "arcbank"
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

function ARCBank.MySQL.Connect()
	ARCBank.Msg("INITIALIZING MYSQL SEQUENCE!")
	if MYSQL_TYPE == 0 then
		ARCBank.Msg("No suitable MySQL module has been found. This addon supports MySQLOO or tmysql4 is supported.")
		ARCBank.Msg("You can download tmysql4 here: https://facepunch.com/showthread.php?t=1442438")
		return 
	end
	if MYSQL_TYPE == 1 then
		ARCBank.Msg("Still running MySQLOO? Why not try tmysql4? MySQLOO is full of memory-leaks and crashes.")
		ARCBank.Msg("You can download tmysql4 here: https://facepunch.com/showthread.php?t=1442438")
	end
	

	local function onConnected()

		ARCBank.Msg( "Database connected. Good, nothing broke" )
		local function gqonSuccess( data )
			ARCBank.Msg("Created/Verified Group account table!")
			function pqonSuccess( data )
				ARCBank.Msg("Created/Verified Personal account table!")
				function aqonSuccess( data )
					ARCBank.Msg("Created/Verified account members table!")
					ARCBank.Loaded = true
					ARCBank.Busy = false
					ARCBank.Msg("ARCBank is ready!")
					ARCBank.CapAccountRank();
			
				end
				function aqonError( err, sql )
					ARCBank.Msg( "Unable to create account members table. "..tostring(err) )
				end
				ARCBank.MySQL.CreateQuery("CREATE TABLE IF NOT EXISTS arcbank_account_members(filename varchar(255),steamid varchar(255));",aqonSuccess,aqonError)
				--lua_run ARCBank.CreateAccount(player.GetAll()[1],1,1000,"",function(err) MsgN(err) end)
			end
	
			function pqonError( err, sql )
				ARCBank.Msg( "Unable to create personal account table. "..tostring(err) )
			end
			ARCBank.MySQL.CreateQuery("CREATE TABLE IF NOT EXISTS arcbank_personal_account(filename varchar(255),isgroup boolean,name varchar(255),money BIGINT,rank int);",pqonSuccess,pqonError)
			
		end
	
		local function gqonError( err, sql )
			ARCBank.Msg( "Unable to create group account table. "..tostring(err) )
		end
		ARCBank.MySQL.CreateQuery("CREATE TABLE IF NOT EXISTS arcbank_group_account(filename varchar(255),isgroup boolean,name varchar(255),owner varchar(255),money BIGINT,rank int);",gqonSuccess,gqonError)
	end


	
	
	local function onConnectionFailed( err )

		ARCBank.Msg( "...SOMETHING BROKE! "..tostring(err) )

	end
	
	ARCBank.Msg("Connecting to database. Hopefully nothing blows up....")
	if MYSQL_TYPE == 1 then
		ARCBank.DataBase = mysqloo.connect( ARCBank.MySQL.Host, ARCBank.MySQL.Username, ARCBank.MySQL.Password, ARCBank.MySQL.DatabaseName, ARCBank.MySQL.DatabasePort )
		function ARCBank.DataBase:onConnectionFailed( err )
			onConnectionFailed(err)
		end
		function ARCBank.DataBase:onConnected()
			onConnected()
		end
		ARCBank.DataBase:connect()
	elseif MYSQL_TYPE == 2 then
		local Database, err = tmysql.Connect(ARCBank.MySQL.Host, ARCBank.MySQL.Username, ARCBank.MySQL.Password, ARCBank.MySQL.DatabaseName, ARCBank.MySQL.DatabasePort, nil, CLIENT_MULTI_STATEMENTS)
		if err then
			onConnectionFailed(err)
		else
			ARCBank.DataBase = Database
			onConnected()
		end
	end
	

end
function ARCBank.MySQL.Query(str,callback)
	local function onSuccess( data )
		callback(true,data)
	end
	
	local function onError( err, sqlq )
		ARCBank.Msg( "MySQL ERROR: "..tostring(err))
		ARCBank.Msg( "In Query ("..tostring(sqlq)..")")
		ARCBank.Msg(tostring(#err).." - "..tostring(#sqlq))
		for _,plys in pairs(player.GetAll()) do
			ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL1)
			ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL2)
			ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL3)
		end
		callback(false,err)
		ARCBank.Loaded = false
		if string.find( err, "gone") then
			ARCBank.Msg( "This error can be ignored. Correcting...." )
			ARCBank.Msg( "If you have had this error too many times, try upping the timeout time on your MySQL server." )
			timer.Simple(10,function()
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
		print( "Error:", err ) -- Check error %%CONFIRMATION_HASH%% ????
	
	end

	ARCBank.MySQL.CreateQuery(str,onSuccess,onError)
end

ARCBank.Commands["mysql"] = {
	command = function(ply,args) 
		if !ARCBank.Loaded then ARCBank.MsgCL(ply,"System reset required!") return end -- This is just to check if the ARCBank system is working properly. 
		if !ARCBank.IsMySQLEnabled() then ARCBank.MsgCL(ply,"MySQL must be enabled.") return end
		if (IsValid(ply) && ply:IsPlayer() && !ply:IsListenServerHost()) then -- For Singleplayer and localhost testing. Note: Remove SteamID when released.
			ARCBank.MsgCL(ply,"This command cannot be used by a player.")
			return
		end
		if args[1] == "copy_to_database" then
			ARCBank.GetAllAccountsUnordered(false,function(errcode,accounts)
				ARCBank.Msg(ARCBank.Msgs.CommandOutput.MySQLCopy)
				for _,plys in pairs(player.GetAll()) do
					ARCBank.MsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopy)
				end
				ARCBank.Busy = true
				if errcode == 0 then
					local Queries = {}
					table.insert(Queries,"DELETE FROM arcbank_account_members")
					table.insert(Queries,"DELETE FROM arcbank_group_account")
					table.insert(Queries,"DELETE FROM arcbank_personal_account")
					for k,v in pairs(accounts) do
						if v.isgroup then
							for kk,vv in pairs(v.members) do
								table.insert(Queries,"INSERT INTO arcbank_account_members (filename,steamid) VALUES ('"..v.filename.."','"..vv.."')")
							end
							table.insert(Queries,"INSERT INTO arcbank_group_account (filename, isgroup, name, owner, money, rank) VALUES ('"..tostring(v.filename).."',"..tostring(v.isgroup)..",'"..ARCBank.MySQL.Escape(tostring(v.name)).."','"..tostring(v.owner).."',"..tonumber(v.money)..","..tostring(v.rank).."); ")
						else
							table.insert(Queries,"INSERT INTO arcbank_personal_account (filename, isgroup, name, money, rank) VALUES ('"..tostring(v.filename).."',"..tostring(v.isgroup)..",'"..ARCBank.MySQL.Escape(tostring(v.name)).."',"..tonumber(v.money)..","..tostring(v.rank).."); ")
						end
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
					

				else
					ARCBank.Msg("Failed to get all accounts. Error code "..tostring(errcode))
				end
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

