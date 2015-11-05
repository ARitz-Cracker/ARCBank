-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
util.AddNetworkString( "ARCATMHACK_BEGIN" )
util.AddNetworkString( "ARCATMHACK_BEACON" )
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
	self.whirang = 0
	self.hacktime = 0
	self.left = 1
	self.HackMoneh = 20
	self.baseenergy = 2000
		self.spark = ents.Create("env_spark")
		self.spark:SetPos( self:GetPos() )
		self.spark:Spawn()
		self.spark:SetKeyValue("Magnitude",1)
		self.spark:SetKeyValue("TrailLength",1)
		self.spark:SetParent( self.Entity )
	self.PickupTime = math.huge
	self.CopRefresh = CurTime()
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
function ENT:BeginHack()
	if self.OurHealth <= 0 then return end
	self:EmitSound("npc/dog/dog_servo12.wav",75,75)
	local atm = self:GetParent()
	if IsValid(atm) && (atm.IsAFuckingATM || atm.CasinoVault) then
		if atm.Hacked || atm.InUse then
			local pos = self:GetParent():WorldToLocal(self:GetPos()) - Vector(0,-self.left,0)
			self:SetPos(pos)
			atm.HackUnit = NULL
			self:SetParent()
			self:GetPhysicsObject():Wake()
		return end
		atm.Hacked = true
		atm.InUse = true
		if atm:WorldToLocal(self:GetPos()):__index("y") < 0 then
			self.left = -1
			----MsgN("LEFT")
		end
		self.init = true
	end
end
 ENT.OurHealth = 25; -- Amount of damage that the entity can handle - set to 0 to make it indestructible
function ENT:StopHack()
	if IsValid(self:GetParent()) && self.hacking then
		self.baseenergy = self.energy - CurTime()
		if self.baseenergy < 0 then self.baseenergy = 0 end
		local atm = self:GetParent()
		
		if self:GetParent().CasinoVault then
			self:GetParent().Vault.Screens[3]:SetScrType(3)
		else
			atm.HackRecover = CurTime() + math.Rand(5,60) + (self.bhacktime/23)
		end
		net.Start( "ARCATMHACK_BEGIN" )
		net.WriteDouble(atm.HackRecover)
		net.WriteDouble(atm.HackRecover)
		net.WriteEntity(atm)
		net.WriteEntity(self.Entity)
		net.WriteBit(false)
		net.WriteBit(true)
		net.Broadcast()
		--atm.CommInitDelay = CurTime() + 100
		atm.InUse = false
		atm.HackUnit = NULL
		atm.Hacked = false
		self.init = false
		local pos = self:GetParent():WorldToLocal(self:GetPos()) - Vector(0,-self.left,0)
		self:SetPos(pos)
		self:SetParent()
		self:EmitSound("ambient/energy/powerdown2.wav")
		if self.HackSound then
			self.HackSound:Stop()
		end
		self:GetPhysicsObject():Wake()
		self.PickupTime = CurTime() + 30
	end
end
function ENT:OnTakeDamage(dmg)
	self:TakePhysicsDamage(dmg); -- React physically when getting shot/blown
	self.OurHealth = self.OurHealth - dmg:GetDamage(); -- Reduce the amount of damage took from our health-variable
	if(self.OurHealth <= 0) then -- If our health-variable is zero or below it
		if self:GetParent() != NULL && self:GetParent().UsePlayer then return end
		if self:GetParent() != NULL && !self:GetParent().UsePlayer then
		
			local attname
			if dmg:GetAttacker():IsPlayer() then
				attname = dmg:GetAttacker():Nick()
			elseif IsEntity(dmg:GetAttacker()) then
				attname = dmg:GetAttacker():GetClass()
			else
				attname "UNKNOWN"
			end
			if IsValid(self.Hacker) && dmg:GetAttacker() != self.Hacker && self.Hacker:IsPlayer() && self.hacktime > 0 then 
				self.Hacker:ConCommand("say "..string.Replace( ARCBank.Msgs.UserMsgs.HackIdiot, "%HERO%", tostring(attname) ) )
				ARCLib.NotifyBroadcast(string.Replace( string.Replace( ARCBank.Msgs.UserMsgs.HackHero, "%IDIOT%",tostring(self.Hacker:Nick())), "%HERO%", tostring(attname) ),NOTIFY_GENERIC,15,true)
			end
		end
		self:StopHack()
		
		if self.spark && self.spark != NULL then
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
				self:EmitSound("npc/turret_floor/detonate.wav")
				util.Effect( "HelicopterMegaBomb", effectdata )	
				util.Effect( "cball_explode", effectdata )	
				self:Remove()
			end)
		end
	end
end
function ENT:Think()
	if !self.init || self.OurHealth <= 0 then return end
	if self:GetParent() == NULL then
		self.init = false
		return
	end
	if self.whirang < 90 then
		self.whirang = self.whirang + 2.5
		local ang = self:GetAngles()
		--ang:RotateAroundAxis( ang:Up(), -22.5*self.left )
		ang:RotateAroundAxis( ang:Up(), -2.5*self.left )
		self:SetAngles(ang)
		local pos = self:GetParent():WorldToLocal(self:GetPos()) - Vector(0.02,0,0)
		self:SetPos(pos)
		self:NextThink( CurTime() )
		return true
	end
	if self.hacking then
		if self.energy < CurTime() && IsValid(self:GetParent()) && !self:GetParent().UsePlayer then
			self:StopHack()
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
		if #player.GetHumans() < ARCBank.Settings["atm_hack_min_player"] then
			ARCLib.NotifyPlayer(self.Hacker,ARCBank.Msgs.UserMsgs.HackNoPlayers.." (< "..ARCBank.Settings["atm_hack_min_player"]..")",NOTIFY_ERROR,6,true)
			self:StopHack()
			return
		end
		
		if #self.Cops < ARCBank.Settings["atm_hack_min_hackerstoppers"] then
			ARCLib.NotifyPlayer(self.Hacker,ARCBank.Msgs.UserMsgs.HackNoCops.." (< "..ARCBank.Settings["atm_hack_min_hackerstoppers"]..")",NOTIFY_ERROR,6,true)
			self:StopHack()
			return
		end
		if self.hacktime > 0 then
			if self.hacktime <= CurTime() then
			self:EmitSound("weapons/stunstick/alyx_stunner1.wav",100,math.random(125,155))
			self:EmitSound("ambient/levels/citadel/stalk_poweroff_on_17_10.wav")
			self.HackSound:Stop()
			self.hacktime = 0
			net.Start("ARCATMHACK_BEACON")
			net.WriteVector(self:GetPos())
			net.WriteBit(true)
			net.Send(self.Cops)
			timer.Simple(math.random(),function()
				if !self || self == NULL then return end
				local atm = self:GetParent()
				if !IsValid(atm) || !atm.Hacked then return end
				if atm.CasinoVault then
					atm.Vault:BeginHacked(self.HackMoneh)
					return
				elseif !atm.IsAFuckingATM then 
					return
				end
				
				
				atm.TakingMoney = true
				if self.Hacker.ARCBank_Secrets then
					atm:EmitSound("^arcbank/atm/spit-out.wav")
					timer.Simple(6.5,function() atm:SetModel( "models/thedoctor/crackmachine_off.mdl" ) end)
					timer.Simple(6.8,function() 
						net.Start("ARCATM_COMM_BEEP")
						net.WriteEntity(atm)
						net.WriteBit(true)
						net.Broadcast()
						atm:EmitSound("arcbank/atm/lolhack.wav")
						local moneyproppos = atm:GetPos() + ((atm:GetAngles():Up() * 0.2) + (atm:GetAngles():Forward() * -4.0) + (atm:GetAngles():Right() * -0.4))
						atm.UsePlayer = nil
						timer.Destroy( "ATM_WIN" ) 
						timer.Create( "ATM_WIN", 0.2, math.Rand(10,20), function()
						
						local moneyprop = ents.Create( "base_anim" ) --I don't want to create another entity. 
						moneyprop:SetModel( "models/props/cs_assault/money.mdl" )
						moneyprop:SetPos( moneyproppos)
						local moneyang = atm:GetAngles()
						moneyang:RotateAroundAxis( moneyang:Up(), -90 )
						moneyprop:SetAngles( moneyang )
						moneyprop:PhysicsInit( SOLID_VPHYSICS )
						moneyprop:SetMoveType( MOVETYPE_VPHYSICS )
						moneyprop:SetSolid( SOLID_VPHYSICS )
						moneyprop:GetPhysicsObject():SetVelocity(moneyprop:GetRight()) 
						function moneyprop:Use( ply, caller )
							ARCBank.PlayerAddMoney(ply,1000)
							moneyprop:Remove()
						end
						moneyprop:Spawn()
						
						end)
					end)
					timer.Simple(11,function() 
						atm:SetModel( "models/thedoctor/crackmachine_on.mdl" ) 
						atm:EmitSound("arcbank/atm/close.wav")
						net.Start("ARCATM_COMM_BEEP")
						net.WriteEntity(atm)
						net.WriteBit(false)
						net.Broadcast()
					end)
				else
				
					----MsgN("HACK ERORR:"..tostring(accounts))
					--self:StopHack()
					atm.args = {} 
					atm.args.money = self.HackMoneh
					atm.UsePlayer = self.Hacker
				--[[
				if self.HackRandom then
					atm.args.name = "*STEAL FROM MULTIPLE ACCOUNTS!!*"
				else
					atm.args.name = accounts[arc_randomexp(1,#accounts)]
					PrintTable(accounts)
					--arc_randomexp
				end
				]]
					ARCBank.GetAllAccounts(self.HackMoneh,function(ercode,accounts)
						if ercode == 0 then
							local accounttable
							if self.HackRandom then
								accounttable = "*STEAL FROM MULTIPLE ACCOUNTS!!*"
							else
								accounttable = accounts[ARCLib.RandomExp(1,#accounts)]
							end
							local nextper = 0.1
							ARCBank.StealMoney(self.Hacker,self.HackMoneh,accounttable,false,function(errcode,per)
								if errcode == ARCBANK_ERROR_DOWNLOADING then
									if per > nextper then
										ARCBank.MsgCL(self.Hacker,ARCBank.Msgs.Items.Hacker..": (%"..math.floor(per)..")")
										nextper = nextper + 0.1
									end
									
								elseif errcode == 0 then
									ARCBank.MsgCL(self.Hacker,ARCBank.Msgs.Items.Hacker..": (%100)")
									
									
									timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation,function() 
										if atm.ATMType.ModelOpen != "" then
											atm:SetModel( atm.ATMType.ModelOpen ) 
											atm:SetSkin(atm.ATMType.OpenSkin)
										end
										if atm.ATMType.OpenAnimation != "" then
											atm:ARCLib_SetAnimationTime(atm.ATMType.OpenAnimation,atm.ATMType.OpenAnimationLength)
										end
									end)
									timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.PauseAfterWithdrawAnimation,function() 
										if atm.ATMType.UseMoneyModel then
											atm.moneyprop = ents.Create( "prop_physics" )
											atm.moneyprop:SetModel( atm.ATMType.MoneyModel )
											atm.moneyprop:SetKeyValue("spawnflags","516")
											atm.moneyprop:SetPos( atm:LocalToWorld(atm.ATMType.WithdrawAnimationPos))
											atm.moneyprop:SetAngles( atm:LocalToWorldAngles(atm.ATMType.WithdrawAnimationAng) )
											atm.moneyprop:Spawn()
											atm.moneyprop:GetPhysicsObject():EnableCollisions(false)
											atm.moneyprop:GetPhysicsObject():EnableGravity(false)
											timer.Simple(atm.ATMType.WithdrawAnimationLength,function() 
												atm.moneyprop:GetPhysicsObject():SetVelocity(Vector(0,0,0)) 
												atm.moneyprop:GetPhysicsObject():EnableMotion( false) 
											end)
											atm.moneyprop:GetPhysicsObject():SetVelocity(atm.moneyprop:GetForward()*atm.ATMType.WithdrawAnimationSpeed.x + atm.moneyprop:GetRight()*atm.ATMType.WithdrawAnimationSpeed.y + atm.moneyprop:GetUp()*atm.ATMType.WithdrawAnimationSpeed.z)
										end
										if atm.ATMType.WithdrawAnimation != "" then
											atm:ARCLib_SetAnimationTime(atm.ATMType.WithdrawAnimation,atm.ATMType.WithdrawAnimationLength)
										end
									end)
									atm:EmitSoundTable(atm.ATMType.WithdrawSound,65,100)
									
									atm.MonehDelay = CurTime() + 8.5
									timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.WithdrawAnimationLength + 0.5,function()
										atm.PlayerNeedsToDoSomething = true
									end)
								else
									ARCLib.NotifyPlayer(self.Hacker,ARCBank.Msgs.Items.Hacker..": "..ARCBANK_ERRORSTRINGS[errcode],NOTIFY_ERROR,6,true)
									self:StopHack()
									-- SHIT HAPPENED, BRAH
								end
							end)
						else
							ARCLib.NotifyPlayer(self.Hacker,ARCBank.Msgs.Items.Hacker..": "..ARCBANK_ERRORSTRINGS[ercode],NOTIFY_ERROR,6,true)
							self:StopHack()
							-- SHIT HAPPENED, BRAH
						end
					end)
				end
			end)
			else
			--[[
				if !self.Hacker || self.Hacker == NULL || !self.Hacker:IsPlayer() then
					self:StopHack()
				end
				]]
				self.HackSound:ChangePitch( 85+((((self.hacktime-CurTime())/self.bhacktime)-1)*-100), 0.2 ) 
				local pos = self.StartPos - Vector(0.0,((((self.hacktime-CurTime())/self.bhacktime)-1)*0.32)*-self.left,0)
				self:SetPos(pos)
				if !self.HackRandom || math.random(1,501) == 501 then
					self.spark:Fire( "SparkOnce","",math.Rand(0,0.2) )
					if ARCBank.Settings.atm_hack_radar then
						net.Start("ARCATMHACK_BEACON")
						net.WriteVector(self:GetPos())
						net.WriteBit(false)
						net.Send(self.Cops)
					end
				end
			end
		end
	else
		self.StartPos = self:GetParent():WorldToLocal(self:GetPos())
		self.spark:Fire( "SparkOnce","",0.01 )
		self.Cops = {}
		for k,v in pairs(ARCBank.Settings["atm_hack_notify"]) do
			for _,ply in pairs(player.GetAll()) do
				if ply:Team() == _G[v] then
					self.Cops[#self.Cops + 1] = ply
				end
			end
		end
		net.Start("ARCATMHACK_BEACON")
		net.WriteVector(self:GetPos())
		net.WriteBit(false)
		net.Send(self.Cops)
		--self.spark:Fire( "Kill","",0.01 )
		--self.spark:Fire("kill","",0.2)
		self.hacking = true
		self:EmitSound("buttons/button6.wav")
		self:EmitSound("weapons/stunstick/alyx_stunner2.wav",100,math.random(92,125))
		self.HackSound = CreateSound(self, "ambient/energy/electric_loop.wav" )
		self.HackSound:Play();
		self.HackSound:ChangePitch( 85, 0.1 ) 
		if self.HackRandom then
			self.HackSound:ChangeVolume( 0.05, 0.05 ) 
		
		end
		for k,v in pairs(ARCBank.Settings["atm_hack_notify"]) do
			for _,ply in pairs(player.GetAll()) do
				if ply:Team() == _G[v] then
					ARCLib.NotifyPlayer(ply,tostring(ARCBank.Msgs.UserMsgs.Hack),NOTIFY_ERROR,10,false)
					ply:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav")
				end
			end
		end
		self:NextThink( CurTime() + 0.5 )
		local basetime = math.Round((((self.HackMoneh/200)^2+28)*(1+ARCLib.BoolToNumber(self.HackRandom))/ARCBank.Settings["atm_hack_time_rate"]))
		if self:GetParent().CasinoVault then
			if self.HackRandom then
				self.bhacktime = basetime
			else
				self.bhacktime = basetime/4
			end
			self:GetParent().Vault.Screens[3]:SetScrType(9)
		else
			self.bhacktime = math.Rand(basetime-math.Round(basetime^0.725),basetime+math.Round(basetime^0.725))
		end
		self.hacktime = self.bhacktime + CurTime()
		self.energy = self.baseenergy + CurTime()
		net.Start( "ARCATMHACK_BEGIN" )
		net.WriteDouble(self.baseenergy)
		net.WriteDouble(self.bhacktime)
		net.WriteEntity(self:GetParent())
		net.WriteEntity(self.Entity)
		net.WriteBit(true)
		net.WriteBit(self.left == 1)
		net.Broadcast()
		self:GetParent().HackUnit = self.Entity
		return true
	end
end

function ENT:OnRemove()
	if self.spark && self.spark != NULL then
		self.spark:Fire( "Kill","",0.01 )
	end
	if self.OweMoney then
	
	
	end
end

function ENT:Use( ply, caller )--self:StopHack()
	if (IsValid(self.Hacker) && self.Hacker:IsPlayer() && (ply != self.Hacker && self.PickupTime > CurTime())) || self.OurHealth <= 0 then return end
	if self.init then
		if self:GetParent() != NULL && self:GetParent().UsePlayer then return end
		self:StopHack()
	else
		ply:Give("weapon_arc_atmhack")
		ply:SelectWeapon("weapon_arc_atmhack")
		self.OurHealth = 0
		timer.Simple(0,function()
			ply:GetActiveWeapon().energystart = CurTime() - (self.baseenergy / ARCBank.Settings["atm_hack_charge_rate"])
			ply:SendLua("LocalPlayer():GetActiveWeapon().energystart = "..tostring(CurTime() - (self.baseenergy /ARCBank.Settings["atm_hack_charge_rate"])))
		end)
		timer.Simple(0.1,function()
			self.Entity:Remove()
		end)
	end
end
--[[
function ENT:Touch(activator, caller) --Based on easy engine wrench
	if self.OurHealth <= 0 then return end
	if activator == self.Hacker && !self.init then
	end
end
]]
function ENT:CPPICanTool(ply,tool)
	if !ply:IsPlayer() || self.ARCBank_MapEntity then
		return false
	else
		return true
	end
end


