MsgN("NET TEST!!!!!!!!!!!!!!")
if SERVER then
	util.AddNetworkString( "aritz_net_test" )
	
	hook.Add( "PlayerInitialSpawn", "ARCNetTest", function(ply)
		MsgN("NET TEST!!!!!!!!!!!!!! SENDING TO "..tostring(ply))
		for i=0,100 do
			net.Start("aritz_net_test")
			net.WriteUInt(i,8)
			net.Send(ply)
		end
	end)
else
	
	net.Receive("aritz_net_test",function(len)
		MsgN(net.ReadUInt(8))
	end)
end

