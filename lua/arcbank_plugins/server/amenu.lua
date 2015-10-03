-- GUI for ARitz Cracker Bank (Serverside)
-- This shit is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
-- However, you must credit me.
if ARCBank then
	util.AddNetworkString( "ARCBank_Admin_GUI" )
	ARCBank.Commands["admin_gui"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if !args[1] then
				net.Start( "ARCBank_Admin_GUI" )
				net.WriteString("")
				net.WriteTable({})
				net.Send(ply)
			elseif args[1] == "logs" then
				net.Start( "ARCBank_Admin_GUI" )
				net.WriteString("logs")
				net.WriteTable(file.Find( ARCBank.Dir.."/systemlog*", "DATA", "datedesc" ) )
				net.Send(ply)
			else
				ARCBank.MsgCL(ply,"Invalid AdminGUI request")
			end
		end, 
		usage = "",
		description = "Opens the admin interface.",
		adminonly = true,
		hidden = false
	}
end

