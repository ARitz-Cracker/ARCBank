-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
include('shared.lua')
language.Add("sent_arc_atm","ARCBank ATM")
local hexarr = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

local initEnts = {} --Sometimes ents don't exist on the client, but they do on the server. This is to make sure that everything is still synced up.
local startEnts = {} 

local function IsValidHacker(ent)
	return IsValid(ent) && ent:GetClass() == "sent_arc_atmhack"
end

net.Receive( "arcbank_hacker_status", function(length)
	local enti = net.ReadUInt(16)
	local ent = Entity(enti)
	
	local operation = net.ReadUInt(4)
	
	local parent = NULL
	if IsValidHacker(ent) then
		parent = ent:GetParent()
	end
	if operation == 0 then -- Setup
		local stuff = {}
		stuff.Hacker = net.ReadEntity()
		stuff.HackEnt = ARCBank.HackableDevices[net.ReadUInt(8)]
		stuff.EnergyLevel = net.ReadDouble()
		stuff.HackAmount = net.ReadUInt(32)
		stuff.HackRandom = net.ReadBool()
		stuff.Orientation = net.ReadBool()
		if IsValidHacker(ent) then
			table.Merge( ent, stuff ) 
		else
			initEnts[enti] = stuff
		end
	elseif operation == 1 then -- Start
		local stuff = {}
		stuff.EnergyStart = CurTime()
		stuff.EnergyEnd = net.ReadDouble()
		--MsgN(ent.EnergyLevel)
		--MsgN(stuff.EnergyEnd)
		--MsgN(stuff.EnergyEnd - CurTime())
		stuff.HackStart = CurTime()
		stuff.HackEnd = net.ReadDouble()
		
		stuff.Hacking = true
		
		if IsValidHacker(ent) and IsValid(parent) then
			table.Merge( ent, stuff )
			parent:HackStart()
		else
			startEnts[enti] = stuff
		end

	elseif operation == 2 then -- Stop
		if IsValidHacker(ent) and IsValid(parent) then
			ent.EnergyLevel = ent.EnergyEnd - CurTime()
			if ent.EnergyLevel < 0 then
				ent.EnergyLevel = 0
			end
			ent.Hacking = false
			parent:HackStop()
		elseif istable(initEnts[enti]) and istable(startEnts[enti]) then
			initEnts[enti].EnergyLevel = startEnts[enti].EnergyEnd - CurTime()
			if initEnts[enti].EnergyLevel < 0 then
				initEnts[enti].EnergyLevel = 0
			end
		else
			ARCBank.Msg("Warning! Hacker entity isn't loaded but the loading table doesn't exist? "..tostring(initEnts[enti]).." "..tostring(startEnts[enti]))
		end
		startEnts[enti] = nil
	elseif operation == 3 then -- Delete
		initEnts[enti] = nil
	elseif operation == 4 then -- Spark
		if IsValidHacker(ent) then
			ent:Spark()
		end
	elseif operation == 5 then -- Complete
		if IsValidHacker(ent) then
			ent:HackComplete()
		end
	elseif operation == 6 then -- Broke
		if IsValidHacker(ent) then
			ent.Broken = true
		end
	end
end)
function ENT:Initialize()
	self.energy = CurTime() + 100
	self.energyt = 100
	self.code1 = ARCLib.RandomString(14,hexarr)
	self.code2 = ARCLib.RandomString(14,hexarr)
	self.HackPercent = 0
	self.Hacking = false
	self.HackStart = 0
	self.HackEnd = 1
	self.EnergyLevel = self.EnergyLevel || 0
end

function ENT:Spark()
	if self.Hacking && IsValid(self:GetParent()) then
		self:GetParent():HackSpark()
	end
end
function ENT:HackComplete()
	if self.Hacking && IsValid(self:GetParent()) then
		self:GetParent():HackComplete(self.Hacker,self.HackAmount,self.HackRandom)
	end
end

function ENT:Think()
	if !IsValid(self:GetParent()) then return end
	local enti = self:EntIndex()
	if initEnts[enti] then
		table.Merge( self, initEnts[enti] )
		initEnts[enti] = nil
	end
	if startEnts[enti] then
		table.Merge( self, startEnts[enti] )
		startEnts[enti] = nil
		self:GetParent():HackStart()
	end
	if self.Hacking then
		self.HackPercent = ARCLib.BetweenNumberScale(self.HackStart,CurTime(),self.HackEnd)
		self:GetParent():HackProgress(self.HackPercent)
	end
end

function ENT:OnRestore()

end



function ENT:Draw()
	self:DrawModel()
	self:DrawShadow( true )
	local DisplayPos = self:GetPos() + ((self:GetAngles():Up() * -0.41) + (self:GetAngles():Forward() * 5.8) + (self:GetAngles():Right() * 2.7 ))
	local DisplayAng
	--MsgN(self.Orientation)
	if self.Orientation then
		DisplayAng = self:GetAngles()+Angle( 0, 0, 180 )
	else
		DisplayAng = self:GetAngles()
	end
	DisplayAng:RotateAroundAxis( DisplayAng:Right(), -90 )
	--displayangle1:RotateAroundAxis( self.displayangle1:Forward(), -13 )
	
	cam.Start3D2D(DisplayPos, DisplayAng, 0.0245)
		surface.SetDrawColor( 125, 150, 90, 255 )
		surface.DrawRect(100/-2, 200/-2, 100, 200 ) 
			
		surface.SetDrawColor( 0,0, 0, 255 )
		surface.DrawOutlinedRect( (102)/-2, (202)/-2, 102, 202 )
		if self.Broken then
			draw.SimpleText( "*Ha$$$$ DEAD", "ARCBankATM", -49, -90, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )	
			draw.SimpleText( "Power: */ARCBa", "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "Hack: nk ATM S", "ARCBankATM", -49, -54, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "Datastream:", "ARCBankATM", -49, -30, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )		
			draw.SimpleText( "B16B00B50000A5", "ARCBankATM", -49, -18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			draw.SimpleText( "415269747A2043", "ARCBankATM", -49, -6, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )

			surface.DrawRect( -48, 24, 35, 10 ) 
			surface.DrawRect( -18, 36, 40, 10 ) 
			surface.DrawRect( 0, 48, 26, 10 ) 
			surface.DrawRect( -48, 60, 75, 10 ) 
			surface.DrawRect( -18, 72, 65, 10 ) 
		else
		
		
			draw.SimpleText( "*Hacking Unit*", "ARCBankATM", -49, -90, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )	
			draw.SimpleText( "Datastream:", "ARCBankATM", -49, -30, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )		
			local atm = self:GetParent()
			
			if self.Hacking then
				ARCLib.BetweenNumberScale(self.HackStart,CurTime(),self.HackEnd)
				if self.energy < CurTime() then
					draw.SimpleText( "Power: 0", "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				else
					draw.SimpleText( "Power: "..math.Clamp(math.Round(self.EnergyEnd-CurTime()),0,math.huge), "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
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
				draw.SimpleText( "Progress: "..math.Clamp(math.Round(self.HackPercent*100),0,100).."%", "ARCBankATM", -49, 18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				surface.DrawRect(-48, 24, math.Clamp((self.HackPercent^2)*96,0,96), 10 )
				surface.DrawRect(-48, 36, math.Clamp(self.HackPercent*96,0,96), 10 ) 
				surface.DrawRect(-48, 48, 75 + math.sin(CurTime())*math.random(18,21), 10 ) 
				surface.DrawRect(-48, 60, 75 + math.sin(CurTime())*math.random(18,21), 10 )
				if self.HackRandom then
					surface.DrawRect(-48, 72, 22 + math.sin(CurTime()*10)*math.random(1,15), 10 ) 
				else
					surface.DrawRect(-48, 72, 82 + math.sin(CurTime()*10)*math.random(1,15), 10 ) 
				end			
			else
				draw.SimpleText( "Power: "..math.Round(self.EnergyLevel), "ARCBankATM", -49, -66, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( "Hack: OFF", "ARCBankATM", -49, -54, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( "00000000000000", "ARCBankATM", -49, -18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( "00000000000000", "ARCBankATM", -49, -6, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
				draw.SimpleText( "Progress: ---%", "ARCBankATM", -49, 18, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER )
			end
		end
		surface.DrawOutlinedRect( -48, 24, 96, 10 ) 
		surface.DrawOutlinedRect( -48, 36, 96, 10 ) 
		surface.DrawOutlinedRect( -48, 48, 96, 10 ) 
		surface.DrawOutlinedRect( -48, 60, 96, 10 ) 
		surface.DrawOutlinedRect( -48, 72, 96, 10 ) 
	cam.End3D2D()
end

