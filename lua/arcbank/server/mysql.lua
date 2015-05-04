-- This file is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
-- However, you must credit me.

-- I actually got off my ass and started to make ARCBank compatable with MySQL. 
-- After started, I realized that this... WILL BE HARD!	

if system.IsLinux() then
	ARCBankMsg(table.Random{"You know, I created a skin using LXDE that made ubuntu look like, sound like, and feel like windows 98.","GANOO/LOONIX","I <3 Linux","Linux is best","I don't like systemd."})
	if file.Exists( "lua/bin/gmsv_mysqloo_linux.dll", "MOD") then
		require( "mysqloo" )
	end
	if file.Exists( "lua/bin/gmsv_mysqloo_win32.dll", "MOD") then
		ARCBankMsg("...You do realize that you tried to install a windows .dll on a linux machine, right?")
	end
elseif system.IsWindows() then
	ARCBankMsg("Yeah, go ahead and waste system resources on GUIs that people won't see.")
	if file.Exists( "lua/bin/gmsv_mysqloo_win32.dll", "MOD") then
		require( "mysqloo" )
	end
	if file.Exists( "lua/bin/gmsv_mysqloo_linux.dll", "MOD") then
		ARCBankMsg("...You do realize that you tried to install a linux .dll on a windows machine, right?")
	end
elseif system.IsOSX() then
	ARCBankMsg("Is there even such a thing as an OSX server? Can it run mysqloo?")
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


function ARCBank.MySQL.Connect()
	ARCBankMsg("INITIALIZING MYSQL SEQUENCE!")
	if !mysqloo then
		ARCBankMsg("MySQLOO Not found.")
		ARCBankMsg("You might wanna go here. http://facepunch.com/showthread.php?t=1357773")
		return
	end
	ARCBank.DataBase = mysqloo.connect( ARCBank.MySQL.Host, ARCBank.MySQL.Username, ARCBank.MySQL.Password, ARCBank.MySQL.DatabaseName, ARCBank.MySQL.DatabasePort )

	function ARCBank.DataBase:onConnected()

		ARCBankMsg( "Database connected. Good, nothing broke" )
		local gq = self:query( "CREATE TABLE IF NOT EXISTS arcbank_group_account(filename varchar(255),isgroup boolean,name varchar(255),owner varchar(255),money BIGINT,rank int);" )
		function gq:onSuccess( data )
			ARCBankMsg("Created/Verified Group account table!")
			local pq = ARCBank.DataBase:query( "CREATE TABLE IF NOT EXISTS arcbank_personal_account(filename varchar(255),isgroup boolean,name varchar(255),money BIGINT,rank int);" )
			function pq:onSuccess( data )
				ARCBankMsg("Created/Verified Personal account table!")
				
				local aq = ARCBank.DataBase:query( "CREATE TABLE IF NOT EXISTS arcbank_account_members(filename varchar(255),steamid varchar(255));" )
				function aq:onSuccess( data )
					ARCBankMsg("Created/Verified account members table!")
					ARCBank.Loaded = true
					ARCBank.Busy = false
					ARCBankMsg("ARCBank is ready!")
			
				end
				function aq:onError( err, sql )
					ARCBankMsg( "Unable to create account members table. "..tostring(err) )
				end
				aq:start()
				--lua_run ARCBank.CreateAccount(player.GetAll()[1],1,1000,"",function(err) MsgN(err) end)
			end
	
			function pq:onError( err, sql )
				ARCBankMsg( "Unable to create personal account table. "..tostring(err) )
			end
			pq:start()
			
			
		end
	
		function gq:onError( err, sql )
			ARCBankMsg( "Unable to create group account table. "..tostring(err) )
		end
		gq:start()

	end

	function ARCBank.DataBase:onConnectionFailed( err )

		ARCBankMsg( "...SOMETHING BROKE! "..tostring(err) )

	end
	
	ARCBankMsg("Connecting to database. Hopefully nothing blows up....")
	ARCBank.DataBase:connect()

end
function ARCBank.MySQL.Query(str,callback)
	local q = ARCBank.DataBase:query( str )
	function q:onSuccess( data )
		callback(true,data)
	end
	
	function q:onError( err, sqlq )
		ARCBankMsg( "MySQL ERROR: "..tostring(err))
		ARCBankMsg( "In Query ("..tostring(sqlq)..")")
		ARCBankMsg(tostring(#err).." - "..tostring(#sqlq))
		for _,plys in pairs(player.GetAll()) do
			ARCBankMsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL1)
			ARCBankMsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL2)
			ARCBankMsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL3)
		end
		callback(false,err)
		ARCBank.Loaded = false
		if string.find( err, "gone") then
			ARCBankMsg( "This error can be ignored. Correcting...." )
			ARCBankMsg( "If you have had this error too many times, try upping the timeout time on your MySQL server." )
			timer.Simple(10,function()
				if ARCBank.Loaded then return end
				ARCBank.MySQL.Connect()
				timer.Simple(5,function()
					if !ARCBank.Loaded then
						for _,plys in pairs(player.GetAll()) do
							ARCBankMsgCL(plys,ARCBank.Msgs.CommandOutput.MySQL4)
						end
					end
				end)
			end)
		else
			ARCBankMsg( "REPORT THIS TO ARITZ CRACKER ASAP!!! (Unless it's your fault)" )
		end
	end

	q:start()
end
--
function ARCBank.MySQL.RunCustomCommand(str)
	local q = ARCBank.DataBase:query( str )
	function q:onSuccess( data )
		print( "Query successful!" )
		print(#data)
		PrintTable( data )
		if #data == 0 then
			print( "Blank table result" )
		end
	
	end
	
	function q:onError( err, sql )

		print( "Query errored!" )
		print( "Query:", sql )
		print( "Error:", err )
	
	end

	q:start()
end

ARCBank.Commands["mysql"] = {
	command = function(ply,args) 
		if !ARCBank.Loaded then ARCBankMsgCL(ply,"System reset required!") return end -- This is just to check if the ARCBank system is working properly.
		if !ARCBank.IsMySQLEnabled() then ARCBankMsgCL(ply,"MySQL must be enabled.") return end
		if (IsValid(ply) || ply:IsPlayer()) && !ply:SteamID() == "STEAM_0:0:18610144" then -- For Singleplayer and localhost testing. Note: Remove SteamID when released.
			ARCBankMsgCL(ply,"This command cannot be used by a player.")
			return
		end
		if args[1] == "copy_to_database" then
			ARCBank.GetAllAccountsUnordered(false,function(errcode,accounts)
				ARCBankMsg(ARCBank.Msgs.CommandOutput.MySQLCopy)
				for _,plys in pairs(player.GetAll()) do
					ARCBankMsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopy)
				end
				ARCBank.Busy = true
				if errcode == 0 then
					Queries = {}
					table.insert(Queries,"DELETE FROM arcbank_account_members")
					table.insert(Queries,"DELETE FROM arcbank_group_account")
					table.insert(Queries,"DELETE FROM arcbank_personal_account")
					for k,v in pairs(accounts) do
						if v.isgroup then
							for kk,vv in pairs(v.members) do
								table.insert(Queries,"INSERT INTO arcbank_account_members (filename,steamid) VALUES ('"..v.filename.."','"..vv.."')")
							end
							table.insert(Queries,"INSERT INTO arcbank_group_account (filename, isgroup, name, owner, money, rank) VALUES ('"..tostring(v.filename).."',"..tostring(v.isgroup)..",'"..ARCBank.DataBase:escape(tostring(v.name)).."','"..tostring(v.owner).."',"..tonumber(v.money)..","..tostring(v.rank).."); ")
						else
							table.insert(Queries,"INSERT INTO arcbank_personal_account (filename, isgroup, name, money, rank) VALUES ('"..tostring(v.filename).."',"..tostring(v.isgroup)..",'"..ARCBank.DataBase:escape(tostring(v.name)).."',"..tonumber(v.money)..","..tostring(v.rank).."); ")
						end
					end
					
					local iii = 1
					
					local function recrusivecopy(num)
						if num > #Queries then 
								ARCBankMsg(ARCBANK_ERRORSTRINGS[0])
								for _,plys in pairs(player.GetAll()) do
									ARCBankMsgCL(plys,ARCBANK_ERRORSTRINGS[0])
								end
								ARCBank.Busy = false
							return 
						end
						ARCBank.MySQL.Query(Queries[num],function(didwork,reason)
							if didwork then
								ARCBankMsg(ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/#Queries)*100))..")")
								for _,plys in pairs(player.GetAll()) do
									ARCBankMsgCL(plys,ARCBank.Msgs.ATMMsgs.LoadingMsg.." (%"..tostring(math.floor((num/#Queries)*100))..")")
								end
								iii = iii + 1
								recrusivecopy(iii)
							else
								ARCBank.Loaded = false
								ARCBankMsg("[ERROR!] (%"..tostring(math.floor((num/#Queries)*100))..") Halting ARCBank. System reset required.")
								for _,plys in pairs(player.GetAll()) do
									ARCBankMsgCL(plys,"[ERROR!] (%"..tostring(math.floor((num/#Queries)*100))..") Halting ARCBank. System reset required.")
								end
							end
						end)
					end
					timer.Simple(2,function() recrusivecopy(iii) end)
					

				else
					ARCBankMsg("Failed to get all accounts. Error code "..tostring(errcode))
				end
			end)
		elseif args[1] == "copy_from_database" then
			ARCBankMsg(ARCBank.Msgs.CommandOutput.MySQLCopyFrom)
			for _,plys in pairs(player.GetAll()) do
				ARCBankMsgCL(plys,ARCBank.Msgs.CommandOutput.MySQLCopyFrom)
			end
			ARCBank.GetAllAccountsUnordered(0,true,function(errcode,accounts)
				ARCBank.Busy = true
				if errcode == 0 then
					for k,v in pairs(accounts) do
						v.money = tostring(v.money)
						v.isgroup = tobool(v.isgroup)
						if v.isgroup then
							v.members = string.Explode(" ",v.members)
							if v.members[1] == "" then v.members = {} end
							file.Write( ARCBank.Dir.."/accounts/group/"..v.filename..".txt", util.TableToJSON(v) )
						else
							file.Write( ARCBank.Dir.."/accounts/personal/"..v.filename..".txt", util.TableToJSON(v) )
						end
					end
					ARCBankMsg(ARCBANK_ERRORSTRINGS[0])
					for _,plys in pairs(player.GetAll()) do
						ARCBankMsgCL(plys,ARCBANK_ERRORSTRINGS[0])
					end
					ARCBank.Busy = false
				else
					ARCBankMsg("[ERROR!] "..tostring(errcode))
					for _,plys in pairs(player.GetAll()) do
						ARCBankMsgCL(plys,"[ERROR!] "..tostring(errcode))
					end
				end
			end)
		else
			MsgN("ARCBank: Invalid Command.")
		end
	end, 
	usage = " [example(string)]",
	description = "An example command.",
	adminonly = false,
	hidden = false}

