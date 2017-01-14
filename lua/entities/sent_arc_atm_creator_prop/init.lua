-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:Initialize()
	--self:SetModel( "models/thedoctor/crackmachine_on.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake() 
		phys:SetMaterial( "metal" )
	end
	self.buttonpos = {}
	--self:SetSkin( 2 )
	self.MonehDelay = CurTime()
	self.UseDelay = CurTime() + 1
	self.RemoveTime = CurTime() + 5
	self:SetUseType(SIMPLE_USE)
end
function ENT:SpawnFunction( ply, tr )
	ARCLib.NotifyPlayer(ply,"Plz no spawn plz thx plz",NOTIFY_ERROR,5,true)
end

function ENT:Think()
	if self.PlayerNeedsToDoSomething then
		self.Beep = true
	elseif self.Beep && self.TakingMoney then
		self:EmitSoundTable(self.ATMType.CloseSound,65,100)
		if self.ATMType.ModelOpen != "" then
			self:SetModel( self.ATMType.Model )
		end
		self:SetSkin(self.ATMType.CloseSkin)
		if self.ATMType.CloseAnimation != "" then
			self:ARCLib_SetAnimationTime(atm.ATMType.CloseAnimation,atm.ATMType.CloseAnimationLength)
		end
		self.Beep = false
	end
	if self.Beep then
		self:EmitSoundTable(self.ATMType.WaitSound,65,100)
		self:NextThink( CurTime() + 1 )
		if self.ATMType.UseMoneylight then
			net.Start("ARCATM_COMM_BEEP")
			net.WriteEntity(self.Entity)
			net.WriteBit(true)
			net.Broadcast()
		end
		self:SetSkin(self.ATMType.LightSkin)
		timer.Simple(0.5, function() 
			if self.ATMType.UseMoneylight then
				net.Start("ARCATM_COMM_BEEP")
				net.WriteEntity(self.Entity)
				net.WriteBit(false)
				net.Broadcast()
			end
			self:SetSkin(self.ATMType.OpenSkin)
		end)
		return true
	end
	--ATMCreatorProp.CreatorPerson
	if !IsValid(self.CreatorPerson) then
		self:Remove()
	end
	if self:GetPos():DistToSqr( self.CreatorPerson:GetPos() ) > 50000 then
		if self.RemoveTime <= CurTime() then
			ARCLib.NotifyPlayer(self.CreatorPerson,ARCBank.Msgs.ATMCreator.Removed,NOTIFY_UNDO,5,false)
			self:Remove()
		else
			ARCLib.NotifyPlayer(self.CreatorPerson,ARCBank.Msgs.ATMMsgs.PlayerTooFar,NOTIFY_HINT,2,false)
			self:NextThink( CurTime() + 1 )
			self:EmitSound("buttons/blip1.wav")
			return true
		end
	else
		self.RemoveTime = CurTime() + 5
	end
end

function ENT:CPPICanTool(ply,tool)
	if !ply:IsPlayer() || self.ARCBank_MapEntity then
		return false
	else
		return true
	end
end
function ENT:Use( ply, caller )
	if self.PlayerNeedsToDoSomething then
		
		local hit,dir,frac = util.IntersectRayWithOBB(ply:GetShootPos(),ply:GetAimVector()*100, self:LocalToWorld(self.ATMType.MoneyHitBoxPos), self:LocalToWorldAngles(self.ATMType.MoneyHitBoxAng), vector_origin, self.ATMType.MoneyHitBoxSize)  
		if hit && self.MonehDelay < CurTime() then
			self.MonehDelay = CurTime() + 1
			if self.TakingMoney then
				if self.ATMType.UseMoneyModel then
					self.moneyprop:Remove()
				end
				self:EmitSoundTable("foley/alyx_hug_eli.wav",65,math.random(225,255))
				self.PlayerNeedsToDoSomething = false
			else
				if !self.fail then
					self:EmitSoundTable(self.ATMType.DepositDoneSound,65,100)
					if self.ATMType.DepositAnimation != "" then
						self:ARCLib_SetAnimationTime(self.ATMType.DepositAnimation,self.ATMType.DepositAnimationLength)
					end
					if self.ATMType.UseMoneyModel then

						self.moneyprop = ents.Create( "prop_physics" )
						self.moneyprop:SetModel( self.ATMType.MoneyModel )
						self.moneyprop:SetKeyValue("spawnflags","516")
						self.moneyprop:SetPos( self:LocalToWorld(self.ATMType.DepositAnimationPos))
						self.moneyprop:SetAngles( self:LocalToWorldAngles(self.ATMType.DepositAnimationAng) )
						self.moneyprop:Spawn()
						self.moneyprop:GetPhysicsObject():EnableCollisions(false)
						self.moneyprop:GetPhysicsObject():EnableGravity(false)
						self.moneyprop:GetPhysicsObject():SetVelocity(self.moneyprop:GetForward()*self.ATMType.DepositAnimationSpeed.x + self.moneyprop:GetRight()*self.ATMType.DepositAnimationSpeed.y + self.moneyprop:GetUp()*self.ATMType.DepositAnimationSpeed.z)
						--MsgN(tostring(self.moneyprop:GetAngles():Up()).." + "..tostring(self.ATMType.DepositAnimationSpeed).." = ".. tostring(self.moneyprop:GetAngles():Up() * self.ATMType.DepositAnimationSpeed))
						timer.Simple(self.ATMType.DepositAnimationLength,function() self.moneyprop:Remove() end)
					end
					timer.Simple(self.ATMType.PauseAfterDepositAnimation,function() self.TakingMoney = true end)
				else
					self:EmitSoundTable(self.ATMType.DepositFailSound,65,100)
					timer.Simple(self.ATMType.PauseAfterDepositAnimationFail,function() self.TakingMoney = true end)
				end
				if self.whirsound then
					self.whirsound:Stop()
				end
				self.PlayerNeedsToDoSomething = false
			end
		end
	elseif self.CreatorPerson == ply then
		net.Start("ARCBank ATM CreatorUse" )
		net.WriteEntity(self)
		net.Send(ply)
	end
end
function ENT:OnRemove()

end
function ENT:ATM_USE(activator)

end
