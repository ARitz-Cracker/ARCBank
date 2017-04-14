-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
util.AddNetworkString( "arcbank_hacker_status" )
util.AddNetworkString( "arcbank_hacker_spark" )
ARCBank.Loaded = false
ENT.ARitzDDProtected = true
function ENT:Initialize()
	self:SetModel( "models/props_lab/reciever01d.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.phys = self:GetPhysicsObject()
	if self.phys:IsValid() then
		self.phys:Wake()
	end
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		self.spark = ents.Create("env_spark")
		self.spark:SetPos( self:GetPos() )
		self.spark:Spawn()
		self.spark:SetKeyValue("Magnitude",1)
		self.spark:SetKeyValue("TrailLength",1)
		self.spark:SetParent( self.Entity )
	self.PickupTime = math.huge
	self.Hacking = false
	self.CopRefresh = CurTime()
	self.whirang = 0
	self.RebootTime = CurTime() + 6
	self.Hero = NULL
end
function ENT:SpawnFunction( ply, tr )
 	if ( !tr.Hit ) then return end
	local blarg = ents.Create ("sent_arc_atmhack")
	blarg:SetPos(tr.HitPos + tr.HitNormal * 40)
	blarg:Spawn()
	blarg:Activate()
	blarg.Hacker = ply
	return blarg
end
function ENT:Setup(hacker,ent,energy,amount,rand,side)
	self.Hacker = hacker
	self.HackEnt = ent
	self.EnergyLevel = energy
	self.HackAmount = amount
	self.HackRandom = rand
	--MsgN(self.EnergyLevel)
	if (!IsValid(self:GetParent())) then
		ErrorNoHalt("Parent not set!")
	end

	if (type(self:GetParent().HackStart) != "function") then
		ErrorNoHalt("type(Parent.HackStart) != \"function\"")
		self:Remove()
		self.Hacker:Give("weapon_arc_atmhack")
		self.Hacker:SelectWeapon("weapon_arc_atmhack")
		return
	end
	if (type(self:GetParent().HackStop) != "function") then
		ErrorNoHalt("type(Parent.HackStop) != \"function\"")
		self:Remove()
		self.Hacker:Give("weapon_arc_atmhack")
		self.Hacker:SelectWeapon("weapon_arc_atmhack")
		return
	end
	if (type(self:GetParent().HackProgress) != "function") then
		ErrorNoHalt("type(Parent.HackProgress) != \"function\"")
		self:Remove()
		self.Hacker:Give("weapon_arc_atmhack")
		self.Hacker:SelectWeapon("weapon_arc_atmhack")
		return
	end
	if (type(self:GetParent().HackSpark) != "function") then
		ErrorNoHalt("type(Parent.HackSpark) != \"function\"")
		self:Remove()
		self.Hacker:Give("weapon_arc_atmhack")
		self.Hacker:SelectWeapon("weapon_arc_atmhack")
		return
	end
	if (type(self:GetParent().HackComplete) != "function") then
		ErrorNoHalt("type(Parent.HackComplete) != \"function\"")
		self:Remove()
		self.Hacker:Give("weapon_arc_atmhack")
		self.Hacker:SelectWeapon("weapon_arc_atmhack")
		return
	end
	self:GetParent()._HackAttached = true
	if (self:GetParent():GetClass() != self.HackEnt.Class) then
		ErrorNoHalt("Parent class is "..self:GetParent():GetClass().." while the specified class is "..self.HackEnt.Class.."!!")
		self:Remove()
		self.Hacker:Give("weapon_arc_atmhack")
		self.Hacker:SelectWeapon("weapon_arc_atmhack")
		return
	end
	if (!side) then
		self.left = 1
	else
		self.left = -1
	end
	
	net.Start( "arcbank_hacker_status" )
	net.WriteUInt(self:EntIndex(),16)
	net.WriteUInt(0,4)
	net.WriteEntity(hacker)
	net.WriteUInt(self.HackEnt._i,8)
	net.WriteDouble(energy)
	net.WriteUInt(amount,32)
	net.WriteBool(rand)
	net.WriteBool(side)
	net.Broadcast()
	self:EmitSound("npc/roller/blade_cut.wav")
end
function ENT:HackBegin()
	if (!self.HackEnt) then
		error("ENT:HackBegin called before ENT:Setup!")
	end
	self.Rotate = true
	self:EmitSound("npc/dog/dog_servo12.wav",70,70)
end

function ENT:HackStop()
	self.GottaStop = true
end

function ENT:Break(hero)
	if IsValid(hero) then
		self.Hero = hero
	end
	if self.GottaStop then
		self.GottaBreak = true
		return
	end
	if self.spark && self.spark != NULL && !self.Broken then
		self.Broken = true
		self.spark:Fire( "SparkOnce","",0.01 )
		self.spark:Fire( "SparkOnce","",0.02 )
		for i=1,math.random(5,40) do
			self.spark:Fire( "SparkOnce","",math.random(i/10,i) )
		end
		self.spark:Fire( "Kill","",41 )
		--math.random(10,40)
		local rtime = math.random(5,35)
		for i=1,28 do
			self.spark:Fire( "SparkOnce","",rtime+(i/10) )
		end
		timer.Simple(rtime+math.Rand(1,3),function()
			if !self || self == NULL then return end
			local effectdata = EffectData()
			effectdata:SetStart(self:GetPos()) -- not sure if we need a start and origin (endpoint) for this effect, but whatever.
			effectdata:SetOrigin(self:GetPos())
			effectdata:SetScale(1)
			self:EmitSound("physics/glass/glass_impact_bullet"..math.random(1,4)..".wav")
			self:EmitSound("physics/plastic/plastic_box_break"..math.random(1,2)..".wav")
			self:EmitSound("ambient/levels/labs/electric_explosion"..ARCLib.RandomExclude(1,5,3)..".wav")
			
			
			util.Effect( "HelicopterMegaBomb", effectdata )	
			util.Effect( "cball_explode", effectdata )	
			self:Remove()
		end)
		self:HackStop()
		hook.Call("ARCBank_OnHackBroken",GM,self.Hacker,self,self.Hero)
	end

end

ENT.OurHealth = 50; -- Amount of damage that the entity can handle - set to 0 to make it indestructible
function ENT:OnTakeDamage(dmg)
	--if self.GottaStop then return end
	self:TakePhysicsDamage(dmg); -- React physically when getting shot/blown
	self.OurHealth = self.OurHealth - dmg:GetDamage(); -- Reduce the amount of damage took from our health-variable
	MsgN(self.OurHealth)
	if(self.OurHealth <= 0) then -- If our health-variable is zero or below it
		self.Hero = dmg:GetAttacker()
		if self.Hacking then
			local attname
			if self.Hero:IsPlayer() then
				attname = dmg:GetAttacker():Nick()
			elseif IsEntity(self.Hero ) then
				attname = self.Hero:GetClass()
			else
				attname "UNKNOWN"
			end
			if IsValid(self.Hacker) && dmg:GetAttacker() != self.Hacker && self.Hacker:IsPlayer() && !self.Broken && !self.GottaStop then 
				self.Hacker:ConCommand("say "..string.Replace( ARCBank.Msgs.UserMsgs.HackIdiot, "%HERO%", tostring(attname) ) )
				ARCLib.NotifyBroadcast(string.Replace( string.Replace( ARCBank.Msgs.UserMsgs.HackHero, "%IDIOT%",tostring(self.Hacker:Nick())), "%HERO%", tostring(attname) ),NOTIFY_GENERIC,15,true)
			end
			
			
		end
		
		self:Break()
		net.Start( "arcbank_hacker_status" )
		net.WriteUInt(self:EntIndex(),16)
		net.WriteUInt(6,4)
		net.Broadcast()
		
	end

end
function ENT:Think()
	if self.Rotate then
		if self.whirang < 90 then
			self.whirang = self.whirang + 2.5
			local ang = self:GetAngles()
			--ang:RotateAroundAxis( ang:Up(), -22.5*self.left )
			ang:RotateAroundAxis( ang:Up(), 2.5*self.left )
			self:SetAngles(ang)
			local pos = self:GetParent():WorldToLocal(self:GetPos()) - Vector(0.02,0,0)
			self:SetPos(pos)
			self:NextThink( CurTime() )
			return true
		else
			self.spark:Fire( "SparkOnce","",0.01)
			self.spark:Fire( "SparkOnce","",0.5)
			self:EmitSound("buttons/button6.wav")
			self.Cops = {}
			self.StartPos = self:GetParent():WorldToLocal(self:GetPos())
			timer.Simple(0.5,function()
				if !IsValid(self) || !IsValid(self:GetParent()) then return end
				
				for k,v in pairs(ARCBank.Settings["atm_hack_notify"]) do
					for _,ply in pairs(player.GetAll()) do
						if ply:Team() == _G[v] then
							ARCLib.NotifyPlayer(ply,tostring(ARCBank.Msgs.UserMsgs.Hack),NOTIFY_ERROR,10,false)
							ply:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav")
							self.Cops[#self.Cops + 1] = ply
						end
					end
				end
				
				self.spark:Fire( "SparkOnce","",0.01)
				
				self:EmitSound("weapons/stunstick/alyx_stunner2.wav",100,math.random(92,125))
				self.HackSound = CreateSound(self, "ambient/energy/electric_loop.wav" )
				self.HackSound:Play();
				self.HackSound:ChangePitch( 85, 0.1 ) 
				if self.HackRandom then
					self.HackSound:ChangeVolume( 0.05, 0.05 ) 
				end
				
				self.EnergyStart = CurTime()
				--MsgN(self.EnergyLevel)
				self.EnergyEnd = CurTime() + self.EnergyLevel
				local hacktime = ARCBank.HackTimeCalculate(self.HackEnt,self.HackAmount,self.HackRandom)
				local hackoffset = ARCBank.HackTimeOffset(self.HackEnt,hacktime)
				
				self.HackStart = CurTime()
				self.HackEnd = CurTime() + math.Rand(hacktime-hackoffset,hacktime+hackoffset)
				
				net.Start( "arcbank_hacker_status" )
				net.WriteUInt(self:EntIndex(),16)
				net.WriteUInt(1,4)
				net.WriteDouble(self.EnergyEnd)
				net.WriteDouble(self.HackEnd)
				net.Broadcast()
				self:GetParent():HackStart()
				
				if ARCBank.Settings.atm_hack_radar then
					net.Start("arcbank_hacker_spark")
					net.WriteVector(self:GetPos())
					net.WriteBit(false)
					net.Send(self.Cops)
				end
				self.Hacking = true
				hook.Call("ARCBank_OnHackBegin",GM,self.Hacker,self,self:GetParent(),self.HackAmount,self.HackRandom)
			end)
			self.Rotate = false
		end
	end
	if self.GottaBreak then
		if math.random(1,3) == 1 && IsValid(self.spark) then
			self.spark:Fire( "SparkOnce","",0.01)
		end
	end
	if !self.Hacking then return end
	if self.GottaStop then
		if (!self:GetParent():HackStop()) then
			self.Hacking = false
			self.GottaStop = false
			self.PickupTime = CurTime() + 13
			net.Start( "arcbank_hacker_status" )
			net.WriteUInt(self:EntIndex(),16)
			net.WriteUInt(2,4)
			net.Broadcast()
			self:EmitSound("ambient/energy/powerdown2.wav")
			if self.HackSound then
				self.HackSound:Stop()
			end
			self.EnergyLevel = self.EnergyEnd - CurTime()
			if self.EnergyLevel < 0 then
				self.EnergyLevel = 0
			end
			self:GetParent()._HackAttached = false
			local detachtime = 3
			if(self.OurHealth <= 0) then
				detachtime = 0.5
			end
			timer.Simple(detachtime,function()
				if !IsValid(self) || !IsValid(self:GetParent()) then return end
				local pos = self:GetParent():WorldToLocal(self:GetPos()) - Vector(0,self.left,0)
				self:SetPos(pos)
				self:SetParent()
				self:GetPhysicsObject():Wake()
				if(self.OurHealth > 0) then
					self:EmitSound("npc/roller/blade_in.wav")
				else
					self:EmitSound("physics/metal/metal_box_impact_bullet"..math.random(1,3)..".wav")
				end
			end)
			if self.GottaBreak then
				self:Break()
			end
			hook.Call("ARCBank_OnHackEnd",GM,self.Hacker,self)
		end
		return
	end
	if self.EnergyEnd < CurTime() then
		self:HackStop()
		return
	end
	
	
	if #player.GetHumans() < ARCBank.Settings["atm_hack_min_player"] then
		ARCLib.NotifyPlayer(self.Hacker,ARCBank.Msgs.UserMsgs.HackNoPlayers.." (< "..ARCBank.Settings["atm_hack_min_player"]..")",NOTIFY_ERROR,6,true)
		self:HackStop()
		return
	end
	
	if #self.Cops < ARCBank.Settings["atm_hack_min_hackerstoppers"] then
		ARCLib.NotifyPlayer(self.Hacker,ARCBank.Msgs.UserMsgs.HackNoCops.." (< "..ARCBank.Settings["atm_hack_min_hackerstoppers"]..")",NOTIFY_ERROR,6,true)
		self:HackStop()
		return
	end

	if self.CopRefresh < CurTime() then
		self.Cops = {}
		for k,v in pairs(ARCBank.Settings["atm_hack_notify"]) do
			for _,ply in pairs(player.GetAll()) do
				if ply:Team() == _G[v] then
					self.Cops[#self.Cops + 1] = ply
				end
			end
		end
		self.CopRefresh = CurTime() + 5
	end
	
	if self.HackEnd < CurTime() then
		self:GetParent():HackComplete(self.Hacker,self.HackAmount,self.HackRandom)
		net.Start("arcbank_hacker_spark")
		net.WriteVector(self:GetPos())
		net.WriteBit(true)
		net.Send(self.Cops)
		net.Start( "arcbank_hacker_status" )
		net.WriteUInt(self:EntIndex(),16)
		net.WriteUInt(5,4)
		net.Broadcast()
		self:NextThink( CurTime() + 2 )
		self:HackStop()
		self:EmitSound("weapons/stunstick/alyx_stunner1.wav",100,math.random(125,155))
		if self.HackSound then
			self.HackSound:Stop()
		end
		timer.Simple(0,function() hook.Call("ARCBank_OnHackSuccess",GM,self.Hacker,self,self:GetParent()) end)
		return true
	end
	
	self.HackSound:ChangePitch( 85+ARCLib.BetweenNumberScale(self.HackStart,CurTime(),self.HackEnd)*100,0.2)
	local pos = self.StartPos - Vector(0.0,ARCLib.BetweenNumberScale(self.HackStart,CurTime(),self.HackEnd)*0.32*-self.left,0)
	self:SetPos(pos)
	if !self.HackRandom || math.random(1,501) == 501 then
		self.spark:Fire( "SparkOnce","",math.Rand(0,0.2) )
		if ARCBank.Settings.atm_hack_radar then
			net.Start("arcbank_hacker_spark")
			net.WriteVector(self:GetPos())
			net.WriteBit(false)
			net.Send(self.Cops)
		end
		net.Start( "arcbank_hacker_status" )
		net.WriteUInt(self:EntIndex(),16)
		net.WriteUInt(4,4)
		net.Broadcast()
		self:GetParent():HackSpark()
	end
end

function ENT:OnRemove()
	if self.spark && self.spark != NULL then
		self.spark:Fire( "Kill","",0.01 )
	end
	net.Start( "arcbank_hacker_status" )
	net.WriteUInt(self:EntIndex(),16)
	net.WriteUInt(3,4)
	net.Broadcast()
	if self.HackSound then
		self.HackSound:Stop()
	end
end

function ENT:Use( ply, caller )--self:HackStop()
	if (IsValid(self.Hacker) && self.Hacker:IsPlayer() && (ply != self.Hacker && self.PickupTime > CurTime())) || self.OurHealth <= 0 then return end
	if IsValid(self:GetParent()) then
		self:HackStop()
	else
		if ARCBank.Settings.atm_hack_allowed_use then
			local notAllowed = true
			for k,v in ipairs(ARCBank.Settings.atm_hack_allowed) do
				if ply:Team() == _G[v] then
					notAllowed = false
					break
				end
			end
			if notAllowed then return end
		end
		ply:Give("weapon_arc_atmhack")
		ply:SelectWeapon("weapon_arc_atmhack")
		self.OurHealth = 0
		local StartEnergyTime = CurTime() - (self.EnergyLevel / ARCBank.Settings["atm_hack_charge_rate"])
		timer.Simple(0,function()
			ply:GetActiveWeapon().StartEnergyTime = StartEnergyTime
			ply:SendLua("LocalPlayer():GetActiveWeapon().StartEnergyTime = "..StartEnergyTime)
		end)
		self:Remove()
	end
end

function ENT:CPPICanTool(ply,tool)
	if !ply:IsPlayer() || self.ARCBank_MapEntity then
		return false
	else
		return true
	end
end


