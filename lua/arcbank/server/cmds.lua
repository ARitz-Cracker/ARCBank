-- cmds.lua - Commands for ARCBank (Can be editable using a plugin)

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false
ARCBank.VarTypeExamples = {}
ARCBank.VarTypeExamples["list"] = {"aritz,snow,cathy,kenzie,isaac,tasha,bubby","bob,joe,frank,bill","red,green,blue,yellow","lol,wtf,omg,rly"}
ARCBank.VarTypeExamples["number"] = {"1337","15","27","9","69","19970415"}
ARCBank.VarTypeExamples["boolean"] = {"true","false"}
ARCBank.VarTypeExamples["string"] = {"word","helloworld","iloveyou","MONEY!","bob","aritz"}
ARCBank.Commands = { --Make sure they are less then 16 chars long.$
	["about"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			ARCBankMsgCL(ply,"ARitz Cracker Bank v"..ARCBank.Version.." Last updated on "..ARCBank.Update )
			ARCBankMsgCL(ply,ARCBank.About)
		end, 
		usage = "",
		description = "About ARitz Cracker Bank.",
		adminonly = false,
		hidden = false
	},
	["help"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if args[1] then
				if ARCBank.Commands[args[1]] then
					ARCBankMsgCL(ply,args[1]..tostring(ARCBank.Commands[args[1]].usage).." - "..tostring(ARCBank.Commands[args[1]].description))
				else
					ARCBankMsgCL(ply,"No such command as "..tostring(args[1]))
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
					ARCBankMsgCL(ply,v)
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
			ARCBankMsgCL(ply,"%%SID%%")
		end, 
		usage = "",
		description = "Who owns this copy of ARCBank?",
		adminonly = false,
		hidden = true
	},
	["test"] = {
		command = function(ply,args) 
			local str = "Arguments:"
			for _,arg in ipairs(args) do
				str = str.." | "..arg
			end
			ARCBankMsgCL(ply,str)
		end, 
		usage = " [argument(any)] [argument(any)] [argument(any)]",
		description = "[Debug] Tests arguments",
		adminonly = false,
		hidden = true
	},
	["settings"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if !args[1] then ARCBankMsgCL(ply,"You didn't enter a setting!") return end
			if ARCBank.Settings[args[1]] || isbool(ARCBank.Settings[args[1]]) then
				if isnumber(ARCBank.Settings[args[1]]) then
					if tonumber(args[2]) then
						ARCBank.Settings[args[1]] = tonumber(args[2])
						
						
						for k,v in pairs(player.GetAll()) do
							ARCBankMsgCL(v,string.Replace( string.Replace( ARCBank.Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", tostring(tonumber(args[2])) ))
							
						end
					else
						ARCBankMsgCL(ply,"You cannot set "..args[1].." to "..tostring(tonumber(args[2])))
					end
				elseif istable(ARCBank.Settings[args[1]]) then
					if args[2] == "" || args[2] == " " then
						ARCBank.Settings[args[1]] = {}
					else
						ARCBank.Settings[args[1]] = string.Explode( ",", args[2])
					end
					for k,v in pairs(player.GetAll()) do
						ARCBankMsgCL(v,string.Replace( string.Replace( ARCBank.Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", args[2] ))
					end
				elseif isstring(ARCBank.Settings[args[1]]) then
					ARCBank.Settings[args[1]] = args[2]--string.gsub(args[2], "[^_%w]", "_")
					for k,v in pairs(player.GetAll()) do
						ARCBankMsgCL(v,string.Replace( string.Replace( ARCBank.Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", args[2] ))
					end
				elseif isbool(ARCBank.Settings[args[1]]) then
					ARCBank.Settings[args[1]] = tobool(args[2])
					for k,v in pairs(player.GetAll()) do
						ARCBankMsgCL(v,string.Replace( string.Replace( ARCBank.Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", tostring(tobool(args[2])) ))
					end
				end
				net.Start("arcbank_comm_client_settings_changed")
				local typ = TypeID(ARCBank.Settings[args[1]])
				net.WriteUInt(typ,16)
				net.WriteString(args[1])
				if typ == TYPE_NUMBER then
					net.WriteDouble(ARCBank.Settings[args[1]])
				elseif typ == TYPE_STRING then
					net.WriteString(ARCBank.Settings[args[1]])
				elseif typ == TYPE_BOOL then
					net.WriteBit(ARCBank.Settings[args[1]])
				elseif typ == TYPE_TABLE then
					net.WriteTable(ARCBank.Settings[args[1]])
				else
					error("Attempted to send unknown setting type. (wat)")
				end
				net.Broadcast()
			else
				ARCBankMsgCL(ply,"Invalid setting "..args[1])
			end
		end, 
		usage = " <setting(str)> <value(any)>",
		description = "Changes settings (see settings_help)",
		adminonly = true,
		hidden = false
	},
	["settings_help"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if !args[1] then 
				for k,v in SortedPairs(ARCBank.Settings) do
					if istable(v) then
						local s = ""
						for o,p in pairs(v) do
							if o > 1 then
								s = s..","..p
							else
								s = p
							end
						end
						ARCBankMsgCL(ply,tostring(k).." = "..s)
					else
						ARCBankMsgCL(ply,tostring(k).." = "..tostring(v))
					end
				end
				ARCBankMsgCL(ply,"Type 'settings_help (setting) for a more detailed description of a setting.")
				return
			end
			if ARCBank.Settings[args[1]] || isbool(ARCBank.Settings[args[1]]) then
				if isnumber(ARCBank.Settings[args[1]]) then
					ARCBankMsgCL(ply,"Type: number")
					ARCBankMsgCL(ply,"Example: "..args[1].." "..table.Random(ARCBank.VarTypeExamples["number"]))
					ARCBankMsgCL(ply,"Description: "..tostring(ARCBank.SettingsDesc[args[1]]))
					ARCBankMsgCL(ply,"Currently set to: "..tostring(ARCBank.Settings[args[1]]))
				elseif istable(ARCBank.Settings[args[1]]) then
					local s = ""
					for o,p in pairs(ARCBank.Settings[args[1]]) do
						if o > 1 then
							s = s..","..p
						else
							s = p
						end
					end
					ARCBankMsgCL(ply,"Type: list")
					ARCBankMsgCL(ply,"Example: "..args[1].." "..table.Random(ARCBank.VarTypeExamples["list"]))
					ARCBankMsgCL(ply,"Description: "..tostring(ARCBank.SettingsDesc[args[1]]))
					ARCBankMsgCL(ply,"Currently set to: "..s)
				elseif isstring(ARCBank.Settings[args[1]]) then
					ARCBankMsgCL(ply,"Type: string")
					ARCBankMsgCL(ply,"Example: "..args[1].." "..table.Random(ARCBank.VarTypeExamples["string"]))
					ARCBankMsgCL(ply,"Description: "..tostring(ARCBank.SettingsDesc[args[1]]))
					ARCBankMsgCL(ply,"Currently set to: "..ARCBank.Settings[args[1]])
				elseif isbool(ARCBank.Settings[args[1]]) then
					ARCBankMsgCL(ply,"Type: boolean")
					ARCBankMsgCL(ply,"Example: "..args[1].." "..table.Random(ARCBank.VarTypeExamples["boolean"]))
					ARCBankMsgCL(ply,"Description: "..tostring(ARCBank.SettingsDesc[args[1]]))
					ARCBankMsgCL(ply,"Currently set to: "..tostring(ARCBank.Settings[args[1]]))
				end
			else
				ARCBankMsgCL(ply,"Invalid setting")
			end
		end, 
		usage = " [setting(str)]",
		description = "Shows you and gives you a description of all the settings",
		adminonly = false,
		hidden = false
	},
	["settings_save"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			file.Write(ARCBank.Dir.."/_saved_settings.txt",util.TableToJSON(ARCBank.Settings))
			if file.Exists(ARCBank.Dir.."/_saved_settings.txt","DATA") then
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SettingsSaved)
				ARCBankMsg(ARCBank.Msgs.CommandOutput.SettingsSaved)
			else
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SettingsError)
				ARCBankMsg(ARCBank.Msgs.CommandOutput.SettingsError)
			end
		end, 
		usage = "",
		description = "Saves the current settings to the disk",
		adminonly = true,
		hidden = false
	},
	["atm_save"] = {
		command = function(ply,args)
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if ARCBank.SaveATMs() then
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.ATMSaved)
			else
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.ATMError)
			end
		end, 
		usage = "",
		description = "Makes all active ATMs a part of the map.",
		adminonly = true,
		hidden = false
	},
	["atm_unsave"] = {
		command = function(ply,args)
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if ARCBank.UnSaveATMs() then
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.ATMDSaved)
			else
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.ATMDError)
			end
		end, 
		usage = "",
		description = "Makes all saved ATMs moveable again.",
		adminonly = true,
		hidden = false
	},
	["atm_respawn"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if ARCBank.SpawnATMs() then
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.ATMRespawn)
			else
				ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.ATMRError)
			end
		end, 
		usage = "",
		description = "Respawns all Map-Based ATMs.",
		adminonly = true,
		hidden = false
	},
	["atm_spawn"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
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
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if !args[1] || !args[2] || !args[3] || args[1] == "" || args[2] == "" || args[3] == "" then
				ARCBankMsgCL(ply,"Not enough argumetns!")
				return
			end
			ARCBank.ReadAccountFile(args[1],tobool(args[2]),function(tab)
				if tab then
					tab.money = tab.money + tonumber(args[3])
					ARCBank.WriteAccountFile(tab,function(didwork)
						if didwork then
							ARCBankMsgCL(ply,ARCBANK_ERRORSTRINGS[0].." "..tostring(tab.money-tonumber(args[3])).." -> "..tab.money)
							ARCBankAccountMsg(tab,"ADMIN: "..tonumber(args[3]).." ("..tab.money..")")
						else
							ARCBankMsgCL(ply,ARCBANK_ERRORSTRINGS[16])
						end
					end)
				else
					ARCBankMsgCL(ply,ARCBANK_ERRORSTRINGS[1])
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
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
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
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if tobool(args[1]) then
				table.insert( ARCBank.Disk.EmoPlayers, ply:SteamID() )
				table.RemoveByValue( ARCBank.Disk.BlindPlayers, ply:SteamID() )
			else
				table.RemoveByValue( ARCBank.Disk.EmoPlayers, ply:SteamID() )
				table.insert( ARCBank.Disk.BlindPlayers, ply:SteamID() )
			end
		end, 
		usage = " <set(bool)>",
		description = "Enable/Disable dark mode",
		adminonly = false,
		hidden = true
	},
	["fullscreenmode"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if tobool(args[1]) then
				table.insert( ARCBank.Disk.OldPlayers, ply:SteamID() )
			else
				table.RemoveByValue( ARCBank.Disk.OldPlayers, ply:SteamID() )
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
			ARCBankMsgCL(ply,"Resetting ARCBank system...")
			ARCBank.SaveDisk()
			ARCBank.Load()
			timer.Simple(math.Rand(4,5),function()
				if ARCBank.Loaded then
					ARCBankMsgCL(ply,"System reset!")
				else
					ARCBankMsgCL(ply,"Error. Check server console for details.")
				end
			end)
		end, 
		usage = "",
		description = "Updates settings and checks for any currupt or invalid accounts. (SAVE YOUR SETTINGS BEFORE DOING THIS!)",
		adminonly = true,
		hidden = false}}
concommand.Add( "arcbank", function( ply, cmd, args )
	local comm = args[1]
	table.remove( args, 1 )
	if ARCBank.Commands[comm] then
		if ARCBank.Commands[comm].adminonly && ply && ply:IsPlayer() && !ply:IsAdmin() && !ply:IsSuperAdmin() then
			ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.admin)
		return end
		if ARCBank.Commands[comm].adminonly && ARCBank.Settings["superadmin_only"] && ply && ply:IsPlayer() && !ply:IsSuperAdmin() then
			ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.superadmin)
		return end
		if ARCBank.Commands[comm].adminonly && ARCBank.Settings["owner_only"] && ply && ply:IsPlayer() && string.lower(ply:GetUserGroup()) != "owner" then
			ARCBankMsgCL(ply,ARCBank.Msgs.CommandOutput.superadmin)
		return end
		
		if ply && ply:IsPlayer() then
			local shitstring = ply:Nick().." ("..ply:SteamID()..") used the command: "..comm
			for i=1,#args do
				shitstring = shitstring.." "..args[i]
			end
			ARCBankMsg(shitstring)
		end
		ARCBank.Commands[comm].command(ply,args)
	elseif !comm then
		ARCBankMsgCL(ply,"No command. Type 'arcbank help' for help.")
	else
		ARCBankMsgCL(ply,"Invalid command '"..tostring(comm).."' Type 'arcbank help' for help.")
	end
end)


