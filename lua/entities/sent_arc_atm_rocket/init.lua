
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:Initialize()
	self:SetModel( "models/thedoctor/crackmachine_on.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self.phys = self:GetPhysicsObject()
	if self.phys:IsValid() then
		self.phys:Wake()
	end
	--self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self.NextBeep = 5
	self.NextBeepTime = CurTime() + 2
	self.Waiting = true
	self.StopTime = CurTime() + math.Rand(15,70)
	self.ATMTime = self.StopTime + math.Rand(5,3)
	self.OldPos = Vector(0,0,0)
	self.Speed = 0
	self.SpeedTime = CurTime() + 15
	self.LastPhysUpdate = CurTime()
end
function ENT:SpawnFunction( ply, tr )
 	if ( !tr.Hit ) then return end
	local blarg = ents.Create ("sent_arc_atm_rocket")
	blarg:SetPos(tr.HitPos + tr.HitNormal * 40)
	blarg:Spawn()
	blarg:Activate()
	return blarg
end
function ENT:Use( ply, caller )

end
function ENT:OnTakeDamage(dmg)

end
function ENT:Think()
	if !self:IsInWorld() then self:Remove() end
	if self.NextBeep < 0.00000001 then
		if self.StopTime > CurTime() then
			if self.Waiting then
				self.LastPhysUpdate = CurTime()
				self.phys:Wake()
				self.RocketSound = CreateSound( self, "^thrusters/rocket04.wav" ) 
				self.Waiting = false
				self.RocketSound:PlayEx(2, 100)
				self.RocketSound:SetSoundLevel( 180 ) 
			end
			for i = -7,8 do
				local relpoint = Vector(((i-1)%4)*2,math.ceil(i/4)*2,0)
				local vPoint = self:LocalToWorld(Vector(-17,-3,-46)+relpoint)
				local effectdata = EffectData()
				effectdata:SetStart( vPoint ) -- not sure if ( we need a start and origin ( endpoint ) for this effect, but whatever
				effectdata:SetOrigin( vPoint )
				effectdata:SetScale( 0.1 )
				util.Effect( "MuzzleEffect", effectdata )
			end
			self:NextThink(CurTime())
			if self.Random then
				if self.SpeedTime <= CurTime() then
					self.Speed = math.floor(self.OldPos:Distance(self:GetPos()))
					--MsgN(self.Speed)
					if self.Speed == 0 then
						self:EmitSound("ambient/levels/labs/electric_explosion"..math.random(1,5)..".wav")
						self:SetAngles(AngleRand())
					end
					self.OldPos = self:GetPos()
					self.SpeedTime = CurTime() + 1
					
				end
			end
			return true
		else
			if self.RocketSound:IsPlaying() then
				self.RocketSound:Stop()
			end
			if self.ATMTime < CurTime() then
				self:Remove()
			end
		end
	else
		if self.NextBeepTime < CurTime() then
			self.NextBeepTime = CurTime() + self.NextBeep
			self.NextBeep = self.NextBeep*0.5
			self:EmitSound("buttons/blip1.wav")
			self:NextThink(CurTime())
			return true
		end
	end
end

function ENT:PhysicsUpdate( phys )
	local diff = CurTime() - self.LastPhysUpdate
	self.LastPhysUpdate = CurTime()
	if self.StopTime > CurTime() && self.NextBeep < 0.00000001 then
		self.phys:ApplyForceCenter(self:GetUp()*phys:GetMass()*700*diff) 
	end
end

function ENT:OnRemove()
	if self.RocketSound then
		self.RocketSound:Stop()
	end
	if self.MapEnt then
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		util.Effect( "entity_remove", effectdata )
		self:EmitSound("Airboat.FireGunRevDown")
		timer.Simple(0.01,function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end
	local OldVel = self.phys:GetVelocity()	
	local OldAVel = self.phys:GetAngleVelocity()
	local oldpos = self:GetPos()
	local oldang = self:GetAngles()
	
	local welddummeh = ents.Create ("sent_arc_atm");
	if self.MapEnt then
		welddummeh:SetPos(self.MapEnt[1]);
		welddummeh:SetAngles(self.MapEnt[2])
		welddummeh:Spawn()
		--dummeh:SetColor( Color(0,0,0,0) )
		welddummeh.ARCBank_MapEntity = true
		local phys = welddummeh:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion( false )
		end
		timer.Simple(0.01,function()
			local effectdata = EffectData()
			effectdata:SetEntity( welddummeh )
			util.Effect( "propspawn", effectdata )
		end)
	else
		welddummeh:SetPos(oldpos);
		welddummeh:SetAngles(oldang)
		welddummeh:Spawn()
		--dummeh:SetColor( Color(0,0,0,0) )
		welddummeh:GetPhysicsObject():SetVelocityInstantaneous(OldVel)
		welddummeh:GetPhysicsObject():AddAngleVelocity(OldAVel)
	end
end

