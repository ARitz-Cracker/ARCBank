local tabOPos = {}
local scrpos = {}
net.Receive( "arcbank_hacker_spark", function(length)
	local stuffs = {}
	stuffs.StartTime = CurTime()
	stuffs.pos = net.ReadVector()
	stuffs.failed = tobool(net.ReadBit())
	if stuffs.failed then
		stuffs.EndTime = CurTime() + 5
	else
		stuffs.EndTime = CurTime() + 1.5
	end
	table.insert( tabOPos, stuffs )
end)
hook.Add("HUDPaint", "ARCBank ATMHackerDetector", function()
	--%%CONFIRMATION_HASH%%
	for i=1,#tabOPos do
		if !tabOPos[i] then
			continue
		end
		scrpos = tabOPos[i].pos:ToScreen()
		if scrpos.visible then
			local mul = ARCLib.BetweenNumberScaleReverse(tabOPos[i].StartTime,CurTime(),tabOPos[i].EndTime)
			--MsgN(255*mul)
			if tabOPos[i].failed then
				surface.SetDrawColor( 255, 0, 0, 255*mul )
			else
				surface.SetDrawColor( 255, 255, 255, 255*mul )
			end
			surface.SetMaterial( ARCLib.GetWebIcon32("atm"))
			surface.DrawTexturedRect( scrpos.x-16 ,scrpos.y-16,32,32 )
			surface.SetMaterial( ARCLib.GetWebIcon16("error"))
			surface.SetDrawColor( 255, 255, 255, 255*math.sin(CurTime()*10)^2*mul )
			surface.DrawTexturedRect( scrpos.x ,scrpos.y,16,16 )
		end
		if tabOPos[i].EndTime < CurTime() then
			table.remove(tabOPos,i)
		end
	end
	--surface.SetTexture( icon )
end)


