-- aacore.lua -Misc functions

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

-- You know, I hate it that I have to use a billion callback functions now that SQL was implimented.
-- An entire rework of the account system is due at v1.3.7
ARCBank.LogFileWritten = false
ARCBank.LogFile = ""
ARCBank.Loaded = false
ARCBank.Busy = true
ARCBank.Dir = "_arcbank"
ARCBank.AccountPrefix = "account_" -- THIS IS DUMB AND I HAVE NO IDEA WHY DID THIS

ARCBank.EasterEggsEnabled = false

ARCBank.Disk = {}
ARCBank.Disk.NommedCards = {}
ARCBank.Disk.EmoPlayers = {}
ARCBank.Disk.BlindPlayers = {}
ARCBank.Disk.OldPlayers = {} 
ARCBank.Disk.ProperShutdown = false

function ARCBank.FuckIdiotPlayer(ply,reason) --Created by an edgy teenager. I'm not sure if this function gets called anymore as people developing their own DLC for ARCBank wouldn't like to be kicked from their own server just because they set their stuff up wrong.
	ARCBank.Msg("ARCBANK ANTI-CHEAT WARNING: Some stupid shit by the name of "..ply:Nick().." ("..ARCBank.GetPlayerID(ply)..") tried to use an exploit: ["..tostring(reason).."]")
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

function ARCBank.IsMySQLEnabled()
	return ARCBank.MySQL && ARCBank.MySQL.EnableMySQL 
end


function ARCBank.MaxAccountRank(ply,group)
	if group then
		local result = ARCBANK_GROUPACCOUNTS_
		if table.HasValue(ARCBank.Settings["usergroup_all"],string.lower(ply:GetUserGroup())) then
			result = ARCBANK_GROUPACCOUNTS_PREMIUM
		end
		if result>ARCBANK_GROUPACCOUNTS_ then return result end
		for i=ARCBANK_GROUPACCOUNTS_STANDARD,ARCBANK_GROUPACCOUNTS_PREMIUM do
			if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],string.lower(ply:GetUserGroup())) then
				result = i
				break
			end
		end
		return result
	else
		local result = ARCBANK_PERSONALACCOUNTS_
		if table.HasValue(ARCBank.Settings["usergroup_all"],string.lower(ply:GetUserGroup())) then
			result = ARCBANK_PERSONALACCOUNTS_GOLD
		end
		if result>ARCBANK_PERSONALACCOUNTS_ then return result end
		for i=ARCBANK_PERSONALACCOUNTS_STANDARD,ARCBANK_PERSONALACCOUNTS_GOLD do
			if table.HasValue(ARCBank.Settings["usergroup_"..i.."_"..ARCBANK_ACCOUNTSTRINGS[i]],string.lower(ply:GetUserGroup())) then
				result = i
				break
			end
		end
		return result
	end
	
end

function ARCBank.Load()
	ARCBank.Loaded = false
		if #player.GetAll() == 0 then
			ARCBank.Msg("A player must be online before continuing...")
		end
		timer.Simple(1,function()

		ARCBank.Msg("Post-loading ARCBank...")
		if not ARCLib.IsVersion("1.7.0") then
			ARCBank.Msg("CRITICAL ERROR! This addon requires ARCLib 1.7.0 or later!")
			ARCBank.Msg("LOADING FALIURE!")
			return
		end
		
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
		if !file.IsDir( ARCBank.Dir.."/groups_1.4","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/groups_1.4")
			file.CreateDir(ARCBank.Dir.."/groups_1.4")
		end
		if !file.IsDir( ARCBank.Dir.."/accounts_1.4","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/accounts_1.4")
			file.CreateDir(ARCBank.Dir.."/accounts_1.4")
		end
		if !file.IsDir( ARCBank.Dir.."/logs_1.4","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/logs_1.4")
			file.CreateDir(ARCBank.Dir.."/logs_1.4")
		end
		if !file.IsDir( ARCBank.Dir.."/syslogs","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/syslogs")
			file.CreateDir(ARCBank.Dir.."/syslogs")
		end
		
		if !file.IsDir( ARCBank.Dir.."/saved_atms","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/saved_atms")
			file.CreateDir(ARCBank.Dir.."/saved_atms")
		end
		if !file.IsDir( ARCBank.Dir.."/custom_atms","DATA" ) then
			ARCBank.Msg("Created Folder: "..ARCBank.Dir.."/custom_atms")
			file.CreateDir(ARCBank.Dir.."/custom_atms")
		end
		
		ARCBank.LogFile = ARCBank.Dir.."/syslogs/"..os.date("%Y-%m-%d")..".log.txt"
		if not file.Exists(ARCBank.LogFile,"DATA") then
			file.Write(ARCBank.LogFile,"***ARCBank System Log***\r\n"..table.Random({"Oh my god. You're reading this!","WINDOWS LOVES TYPEWRITER COMMANDS IN TXT FILES","What you're referring to as 'Linux' is in fact GNU/Linux.","... did you mess something up this time?"}).."\r\nDates are in YYYY-MM-DD\r\n")
			ARCBank.LogFileWritten = true
			ARCBank.Msg("Log File Created at "..ARCBank.LogFile)
		end
		
		
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
		ARCLib.LoadDefaultLanguages("ARCBank","https://raw.githubusercontent.com/ARitz-Cracker/aritzcracker-addon-translations/master/default_arcbank_languages.json",function(langChoices)
			ARCLib.AddonAddSettingMultichoice("ARCBank","language",langChoices)
			ARCLib.AddonLoadSettings("ARCBank",{hack_max = "atm_hack_max", hack_min = "atm_hack_min", standard_interest = "interest_1_standard", bronze_interest = "interest_2_bronze", silver_interest = "interest_3_silver", gold_interest = "interest_4_gold", group_standard_interest = "interest_6_group_standard", group_premium_interest = "interest_7_group_premium", standard_requirement = "usergroup_1_standard", bronze_requirement = "usergroup_2_bronze", silver_requirement = "usergroup_3_silver", gold_requirement = "usergroup_4_gold", group_standard_requirement = "usergroup_6_group_standard", group_premium_requirement = "usergroup_7_group_premium", everything_requirement = "usergroup_all", starting_cash = "account_starting_cash", debt_limit = "account_debt_limit", starting_cash = "account_starting_cash", group_account_limit = "account_group_limit",perpetual_debt = "interest_perpetual_debt"})
			ARCLib.SetAddonLanguage("ARCBank")

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
			local f,d = file.Find( ARCBank.Dir.."/systemlog*", "DATA", "datedesc" )
			for k,v in ipairs(f) do
				file.Delete( ARCBank.Dir.."/"..v ) -- Delete inaccessible logs
			end
			f,d = file.Find( ARCBank.Dir.."/systemlog/*.log.txt", "DATA", "datedesc" )
			for k,v in ipairs(f) do
				if file.Time( ARCBank.Dir.."/systemlog/"..v, "DATA" ) < (os.time()-ARCBank.Settings["syslog_delete_time"]*86400) then 
					file.Delete( ARCBank.Dir.."/systemlog/"..v ) -- Delete old logs
				end
			end
			timer.Create( "ARCBANK_SAVEDISK", 300, 0, function() 
				if !ARCBank.Disk.LastInterestTime then
					ARCBank.Disk.LastInterestTime = os.time() - ARCBank.Settings["interest_time"]*3600
				end
				local missedtimes = math.floor((os.time() - ARCBank.Disk.LastInterestTime)/(ARCBank.Settings["interest_time"]*3600))
				if missedtimes > 0 then
					if missedtimes > 1 then
						ARCBank.Msg("MISSED "..missedtimes.." INTEREST PAYMENTS! Looks like we'll have to catch up!")
					end
					ARCBank.Disk.LastInterestTime = os.time()
					local recursiveCallback
					recursiveCallback = function()
						if missedtimes > 0 then
							ARCBank.AddAccountInterest(recursiveCallback)
							missedtimes = missedtimes - 1
						else
							ARCBank.Msg("Interest will be given next on "..os.date( "%X - %d-%m-%Y", ARCBank.Disk.LastInterestTime+ARCBank.Settings["interest_time"]*3600 ))
						end
					end
					recursiveCallback()
				end
				file.Write(ARCBank.Dir.."/__data.txt", util.TableToJSON(ARCBank.Disk) )
				--ARCBank.UpdateLang(ARCBank.Settings["atm_language"])

				if ARCBank.Settings["notify_update"] then
					ARCBank.Msg("TODO: Check for updates")
				end
				
			end )
			timer.Start( "ARCBANK_SAVEDISK" ) 
			if ARCBank.IsMySQLEnabled() then
				ARCBank.MySQL.Connect()
			else
				ARCBank.Msg("ARCBank is ready!")
				ARCBank.Loaded = true
				ARCBank.Busy = false
				ARCBank.ConvertOldAccounts()
				ARCBank.CapAccountRank()
			end
			for k,ply in pairs(player.GetAll()) do
				local f = ARCBank.Dir.."/accounts_unused/"..string.lower(string.gsub(ARCBank.GetPlayerID(ply), "[^_%w]", "_"))..".txt" 
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
	end)
end

