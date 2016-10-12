-- cmds.lua - Commands for ARCBank (Can be editable using a plugin)

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014 Aritz Beobide-Cardinal All rights reserved.
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
	["test"] = { -- %%CONFIRMATION_HASH%%
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
			ARCBank.MsgCL(ply,"%%SID%%")
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
			if !args[1] || !args[2] || !args[3] || args[1] == "" || args[2] == "" || args[3] == "" then
				ARCBank.MsgCL(ply,"Not enough argumetns!")
				return
			end
			ARCBank.ReadAccountFile(args[1],tobool(args[2]),function(tab)
				if tab then
					tab.money = tab.money + tonumber(args[3])
					ARCBank.WriteAccountFile(tab,function(didwork)
						if didwork then
							ARCBank.MsgCL(ply,ARCBANK_ERRORSTRINGS[0].." "..tostring(tab.money-tonumber(args[3])).." -> "..tab.money)
							ARCBankAccountMsg(tab,"ADMIN: "..tonumber(args[3]).." ("..tab.money..")")
						else
							ARCBank.MsgCL(ply,ARCBANK_ERRORSTRINGS[16])
						end
					end)
				else
					ARCBank.MsgCL(ply,ARCBANK_ERRORSTRINGS[1])
				end
			end)
		end, 
		usage = " <name(str)> <group(bool)> <money(num)>",
		description = "Gives or takes away money from an account",
		adminonly = true,
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
		description = "Updates settings and checks for any currupt or invalid accounts. (SAVE YOUR SETTINGS BEFORE DOING THIS!)",
		adminonly = true,
		hidden = false}
}

ARCLib.AddSettingConsoleCommands("ARCBank")
ARCLib.AddAddonConcommand("ARCBank","arcbank")