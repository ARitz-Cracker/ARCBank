-- cmds.lua - Commands for ARCBank (Can be editable using a plugin)

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false
ARCBank.Commands = { --Make sure they are less then 16 chars long.$
	["about"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			ARCBank.MsgCL(ply,"ARitz Cracker Bank v"..ARCBank.Version.." Last updated on "..ARCBank.Update )
			ARCBank.MsgCL(ply,ARCBank.About)
		end, 
		usage = "",
		description = "About ARitz Cracker Bank.",
		adminonly = false,
		hidden = false
	},
	["test"] = {
		command = function(ply,args) 
			local str = "Arguments:"
			for _,arg in ipairs(args) do
				str = str.." | "..arg
			end
			ARCBank.MsgCL(ply,str)
		end, 
		usage = " [argument(any)] [argument(any)] [argument(any)]",
		description = "[Debug] Tests arguments",
		adminonly = false,
		hidden = true
	},
	["help"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if args[1] then
				if ARCBank.Commands[args[1]] then
					ARCBank.MsgCL(ply,args[1]..tostring(ARCBank.Commands[args[1]].usage).." - "..tostring(ARCBank.Commands[args[1]].description))
				else
					ARCBank.MsgCL(ply,"No such command as "..tostring(args[1]))
				end
			else
				local cmdlist = "\n*** ARCBANK HELP MENU ***\n\nSyntax:\n<name(type)> = required argument\n[name(type)] = optional argument\n\nList of commands:"
				for key,a in SortedPairs(ARCBank.Commands) do
					if !ARCBank.Commands[key].hidden then
						local desc = "*                                                 - "..ARCBank.Commands[key].description.."" -- +2
						for i=1,string.len( key..ARCBank.Commands[key].usage ) do
							desc = string.SetChar( desc, (i+2), string.GetChar( key..ARCBank.Commands[key].usage, i ) )
						end
						cmdlist = cmdlist.."\n"..desc
					end
				end
				for _,v in pairs(string.Explode( "\n", cmdlist ))do
					ARCBank.MsgCL(ply,v)
				end
			end
			
		end, 
		usage = " [command(string)]",
		description = "Gives you a description of every command.",
		adminonly = false,
		hidden = false
	},
	["owner"] = {
		command = function(ply,args) 
			ARCBank.MsgCL(ply,"{{ user_id }}")
			ARCBank.MsgCL(ply,"{{ user_id sha256 trackarcbank }}")
		end, 
		usage = "",
		description = "Who owns this copy of ARCBank?",
		adminonly = false,
		hidden = true
	},
	["atm_save"] = {
		command = function(ply,args)
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if ARCBank.SaveATMs() then
				ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.ATMSaved)
			else
				ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.ATMError)
			end
		end, 
		usage = "",
		description = "Makes all active ATMs a part of the map.",
		adminonly = true,
		hidden = false
	},
	["atm_unsave"] = {
		command = function(ply,args)
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if ARCBank.UnSaveATMs() then
				ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.ATMDSaved)
			else
				ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.ATMDError)
			end
		end, 
		usage = "",
		description = "Makes all saved ATMs moveable again.",
		adminonly = true,
		hidden = false
	},
	["atm_respawn"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if ARCBank.SpawnATMs() then
				ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.ATMRespawn)
			else
				ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.ATMRError)
			end
		end, 
		usage = "",
		description = "Respawns all Map-Based ATMs.",
		adminonly = true,
		hidden = false
	},
	["atm_spawn"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if !IsValid(ply) or !ply:IsPlayer() then MsgN("You're not a player, and therefore nothing can be spawned where you're looking at because you can't look at anything.") return end
			net.Start("arcbank_comm_atmspawn")
			local files,dirs = file.Find(ARCBank.Dir.."/custom_atms/*.txt","DATA")
			net.WriteUInt(#files,32)
			for i=1,#files do
				net.WriteString(string.Left(files[i], #files[i]-4))
			end
			net.Send(ply)
		end, 
		usage = "",
		description = "Spawn an ATM where you're looking.",
		adminonly = true,
		hidden = false
	},
	
	["give_money"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if IsValid(ply) && !table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) && !table.HasValue(ARCBank.Settings.moderators,string.lower(ply:GetUserGroup())) then
				_G[addon].MsgCL(ply,ARCLib.PlaceholderReplace(ARCBank.Msgs.CommandOutput.AdminCommand,{RANKS=table.concat( ARCBank.Settings.admins, ", " )..", "..table.concat( ARCBank.Settings.moderators, ", " )}))
				return
			end
			if !args[1] || !args[2] || args[1] == "" || args[2] == "" then
				ARCBank.MsgCL(ply,"Not enough argumetns!")
				return
			end
			local amount = tonumber(args[2]) or 0
			if amount == 0 then
				ARCBank.MsgCL(ply,"invalid amount")
			else
				ARCBank.AddMoney(ply,args[1],amount,ARCBANK_TRANSACTION_WITHDRAW_OR_DEPOSIT,"Admin Menu",function(err)
					ARCBank.MsgCL(ply,ARCBANK_ERRORSTRINGS[err])
				end)
			end
		end, 
		usage = " <accountid(str)> <money(num)>",
		description = "Gives or takes away money from an account",
		adminonly = false,
		hidden = false
	},
	
	["print_json"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			local translations = {}
			translations.errmsgs = ARCBANK_ERRORSTRINGS
			translations.msgs = ARCBank.Msgs
			translations.settingsdesc = ARCBank.SettingsDesc
			local strs = ARCLib.SplitString(util.TableToJSON(translations),4000)
			for i = 1,#strs do
				Msg(strs[i])
			end
			Msg("\n")
		end, 
		usage = "",
		description = "Prints a JSON of all the translation shiz.",
		adminonly = true,
		hidden = true
	},
	["darktheme"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if tobool(args[1]) then
				table.insert( ARCBank.Disk.EmoPlayers, ARCBank.GetPlayerID(ply) )
				table.RemoveByValue( ARCBank.Disk.BlindPlayers, ARCBank.GetPlayerID(ply) )
			else
				table.RemoveByValue( ARCBank.Disk.EmoPlayers, ARCBank.GetPlayerID(ply) )
				table.insert( ARCBank.Disk.BlindPlayers, ARCBank.GetPlayerID(ply) )
			end
		end, 
		usage = " <set(bool)>",
		description = "Enable/Disable dark mode",
		adminonly = false,
		hidden = true
	},
	["fullscreenmode"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if tobool(args[1]) then
				table.insert( ARCBank.Disk.OldPlayers, ARCBank.GetPlayerID(ply) )
			else
				table.RemoveByValue( ARCBank.Disk.OldPlayers, ARCBank.GetPlayerID(ply) )
			end
		end, 
		usage = " <set(bool)>",
		description = "Enable/Disable dark mode",
		adminonly = false,
		hidden = true
	},
	["unlock"] = {
		command = function(ply,args)
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if !args[1] or args[1] == "" then
				ARCBank.MsgCL(ply,"unlock: "..ARCBank.Msgs.CommandOutput.AccountNotSpecified)
				return
			end
			ARCBank.UnDeadlock(args[1],function(err)
				if err == ARCBANK_ERROR_NIL_ACCOUNT then
					ARCBank.MsgCL(ply,"unlock: "..ARCBank.Msgs.CommandOutput.AccountNotLocked)
				else
					ARCBank.MsgCL(ply,"unlock: "..ARCBANK_ERRORSTRINGS[err])
				end
			end)
		end,
		usage = " <accountid(str)>",
		description = "Unlocks an account that has been deadlocked",
		adminonly = true,
		hidden = false
	},
	["purge_accounts"] = {
		command = function(ply,args) 
			if (IsValid(ply) && ply:IsPlayer() && !ply:IsListenServerHost()) then
				ARCBank.MsgCL(ply,"This command cannot be used by a player.")
				return
			end
			if !ARCBank.CommitSedoku then
				ARCBank.MsgCL(ply,"/!\\ WARNING WARNING WARNING /!\\")
				ARCBank.MsgCL(ply,"YOU HAVE ENTERED THE COMMAND THAT WILL NUKE ALL ACCOUNTS ON THE SERVER!")
				ARCBank.MsgCL(ply,"NO BACKUPS WILL BE CREATED. THIS ACTION CANNOT BE REVERSED!!")
				ARCBank.MsgCL(ply,"If you are absolutely sure you want to reset your economy, enter \"arcbank purge_accounts\" again to confirm!")
				ARCBank.CommitSedoku = true
			else
				ARCBank.MsgCL(ply,"Purging ARCBank history...")
				ARCBank.PurgeAccounts(function(err)
					if err == 0 then
						ARCBank.MsgCL(ply,"ARCBank economy successfully reset!")
						ARCBank.MsgCL(ply,"Please enter \"arcbank reset\" to continue")
					else
						ARCBank.MsgCL(ply,"Failed to purge ARCBank history! this is bad. "..ARCBANK_ERRORSTRINGS[err])
					end
				end)
			end
			
		end, 
		usage = "",
		description = "Deletes all accounts on the server",
		adminonly = true,
		hidden = false
	},
	["reset_settings"] = {
		command = function(ply,args) 
			ARCBank.SettingsReset()
		end, 
		usage = "",
		description = "Resets all settings to their default. (Doesn't save)",
		adminonly = true,
		hidden = false
	},
	["reset"] = {
		command = function(ply,args) 
			ARCBank.MsgCL(ply,"Resetting ARCBank system...")
			ARCBank.SaveDisk()
			ARCBank.Load()
			timer.Simple(math.Rand(4,5),function()
				if ARCBank.Loaded then
					ARCBank.MsgCL(ply,"System reset!")
				else
					ARCBank.MsgCL(ply,"Error. Check server console for details.")
				end
			end)
		end, 
		usage = "",
		description = "Runs the ARCBank startup process. (SAVE YOUR SETTINGS BEFORE DOING THIS!)",
		adminonly = true,
		hidden = false}
}

ARCLib.AddSettingConsoleCommands("ARCBank")
ARCLib.AddAddonConcommand("ARCBank","arcbank")