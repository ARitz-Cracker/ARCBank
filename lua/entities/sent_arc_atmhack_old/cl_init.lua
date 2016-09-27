-- This 2014,2015 is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014 Aritz Beobide-Cardinal All rights reserved.
include('shared.lua')
language.Add("sent_arc_atm","ARCBank ATM")
function ENT:Initialize()
self.energy = CurTime() + 100
self.energyt = 100
self.code1 = "00000000000000"
self.code2 = "00000000000000"
self.HackPercent = 0
end

function ENT:Think()

end

function ENT:OnRestore()
end
--[[fadsadad
function ENT:Draw()
	self:DrawModel()
	self:DrawShadow( true )
end
--]]
net.Receive( "ARCATMHACK_BEGIN", function(length)
	local energytime = net.ReadDouble()
	local time = net.ReadDouble()
	local atm = net.ReadEntity()
	local hacker = net.ReadEntity()
	local hack = tobool(net.ReadBit())
	local orient = tobool(net.ReadBit())
	if !IsValid(atm) || (!atm.IsAFuckingATM && !atm.CasinoVault) || !IsValid(hacker) then return end
	hacker.hacking = hack
	hacker.ori = orient
	if hack then
		self.HackStart = CurTime()
		self.HackTime = time
		self.HackDelay = CurTime() + time
		atm.Hacked = true
		hacker.energyt = energytime
		hacker.energy = CurTime() + energytime
		hacker.code1 = ARCLib.RandomString(14,hexarr)
		hacker.code2 = ARCLib.RandomString(14,hexarr)
	else
		if (!hacker.energy) then
			hacker.energy = CurTime()
		end
		hacker.energyt = math.Round(hacker.energy - CurTime())
		if hacker.energyt < 0 then hacker.energyt = 0 end
		self.HackStart = CurTime()
		self.HackTime = 0
		self.HackDelay = 0
		atm.Hacked = false
		if !atm.CasinoVault then
			atm.HackRecover = time
		end
		atm.Percent = 0
	end
end)
local hexarr = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
function ENT:Draw()
	self:DrawModel()
	self:DrawShadow( true )
	local DisplayPos = self:GetPos() + ((self:GetAngles():Up() * -0.41) + (self:GetAngles():Forward() * 5.7) + (self:GetAngles():Right() * 2.7 ))
	if self.ori then
		self.displayangle1 = self:GetAngles()+Angle( 0, 0, 180 )
	else
		self.displayangle1 = self:GetAngles()
	end
	self.displayangle1:RotateAroundAxis( self.displayangle1:Right(), -90 )
	--displayangle1:RotateAroundAxis( self.displayangle1:Forward(), -13 )
	cam.Start3D2D(DisplayPos, self.displayangle1, 0.0245)
		surface.SetDrawColor( 125, 150, 90, 255 )
		surface.DrawRect(100/-2, 200/-2, 100, 200 ) 
			
		surface.SetDrawColor( 0,0, 0, 255 )
		surface.DrawOutlinedRect( (102)/-2, (202)/-2, 102, 202 )

		draw.SimpleText( "*Hacking Unit*", "ARCBankATM", -49, -90, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )	
		draw.SimpleText( "Datastream:", "ARCBankATM", -49, -30, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )		
		local atm = self:GetParent()
		
		if IsValid(atm) then
			ARCLib.BetweenNumberScale(self.HackStart,CurTime(),self.HackDelay)
			if self.energy < CurTime() then
				draw.SimpleText( "Power: 0", "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			else
				draw.SimpleText( "Power: "..tostring(math.Round(self.energy-CurTime())), "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			end
			draw.SimpleText( "Hack: ON", "ARCBankATM", -49, -54, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			if self.HackPercent == 0 then
				draw.SimpleText( "00000000000000", "ARCBankATM", -49, -18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( "00000000000000", "ARCBankATM", -49, -6, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			elseif self.HackPercent < 0.99 then
				draw.SimpleText( ARCLib.RandomString(14,hexarr), "ARCBankATM", -49, -18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( ARCLib.RandomString(14,hexarr), "ARCBankATM", -49, -6, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			else
				draw.SimpleText( self.code1, "ARCBankATM", -49, -18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( self.code2, "ARCBankATM", -49, -6, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			end
			draw.SimpleText( "Progress: "..tostring(math.Clamp(math.Round(self.HackPercent*100),0,100)).."%", "ARCBankATM", -49, 18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			surface.DrawRect(-48, 24, math.Clamp(self.HackPercent*96,0,96), 10 ) 
			surface.DrawRect(-48, 12, math.Clamp((self.HackPercent^2)*96,0,96), 10 )
			surface.DrawRect(-48, 36, 75 + math.sin(CurTime())*math.random(18,21), 10 ) 
			surface.DrawRect(-48, 48, 75 + math.sin(CurTime())*math.random(18,21), 10 )
			surface.DrawRect(-48, 60, 82 + math.sin(CurTime()*10)*math.random(1,15), 10 ) 			
		else
			draw.SimpleText( "Power: "..tostring(self.energyt), "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "Hack: OFF", "ARCBankATM", -49, -54, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "00000000000000", "ARCBankATM", -49, -18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "00000000000000", "ARCBankATM", -49, -6, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "Progress: ---%", "ARCBankATM", -49, 18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
		end
			surface.DrawOutlinedRect( -48, 24, 96, 10 ) 
			surface.DrawOutlinedRect( -48, 36, 96, 10 ) 
			surface.DrawOutlinedRect( -48, 48, 96, 10 ) 
			surface.DrawOutlinedRect( -48, 60, 96, 10 ) 
			surface.DrawOutlinedRect( -48, 72, 96, 10 ) 
	cam.End3D2D()
end

