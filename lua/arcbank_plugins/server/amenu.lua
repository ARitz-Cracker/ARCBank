-- GUI for ARitz Cracker Bank (Serverside)
-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

ARCLib.RegisterBigMessage("arcbank_comm_admin_log_dl",16000,255,true)
local maxloglen = 16000*255

util.AddNetworkString( "ARCBank_Admin_GUI" )
ARCBank.Commands["admin_gui"] = {
	command = function(ply,args) 
		--if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
		if IsValid(ply) && !table.HasValue(ARCBank.Settings.admins,string.lower(ply:GetUserGroup())) && !table.HasValue(ARCBank.Settings.moderators,string.lower(ply:GetUserGroup())) then
			_G[addon].MsgCL(ply,ARCLib.PlaceholderReplace(ARCBank.Msgs.CommandOutput.AdminCommand,{RANKS=table.concat( ARCBank.Settings.admins, ", " )..", "..table.concat( ARCBank.Settings.moderators, ", " )}))
			return
		end
		if ply then
			if !args[1] then
				net.Start( "ARCBank_Admin_GUI" )
				net.WriteString("")
				net.WriteTable({})
				net.Send(ply)
			elseif args[1] == "logs" then
				if args[2] then
					local safeFilePath = string.GetFileFromFilename( args[2] ) --Someone's being lazy
					if safeFilePath == "" then
						safeFilePath = args[2]
					end
					ARCLib.SendBigMessage("arcbank_comm_admin_log_dl",file.Read(ARCBank.Dir.."/syslogs/"..safeFilePath,"DATA") or "",ply,NULLFUNC) -- Client gets notified of errors anyway
				else
					net.Start( "ARCBank_Admin_GUI" )
					net.WriteString("logs")
					net.WriteTable(file.Find( ARCBank.Dir.."/syslogs/*.log.txt", "DATA", "datedesc" ) )
					net.Send(ply)
				end
			else
				ARCBank.MsgCL(ply,"Invalid AdminGUI request")
			end
		else
			ARCBank.MsgCL(ply,"This command doesn't work via RCON. Please enter the command in a console from within Garry's Mod.")
		end
	end, 
	usage = "",
	description = "Opens the admin interface.",
	adminonly = false,
	hidden = false
}

