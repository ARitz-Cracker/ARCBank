-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
--Stuff
util.AddNetworkString( "ARCBank CustomATM" )
net.Receive( "ARCBank CustomATM", function(length,ply)
	local atm = net.ReadEntity()
	if atm:GetClass() == "sent_arc_atm" then
		net.Start("ARCBank CustomATM")
		net.WriteEntity(atm)
		local data = util.Compress(util.TableToJSON(atm.ATMType)) -- For some reason JSON is more reliable at keeping them floats accurate than write.Table
		net.WriteUInt(#data,32)
		net.WriteData(data,#data)
		net.Send(ply)
	end
end)

util.AddNetworkString( "ARCATM_USE" )
util.AddNetworkString( "arcbank_atm_reboot" )
util.AddNetworkString( "ARCATM_COMM_WAITMSG" )
util.AddNetworkString("ARCATM_COMM_BEEP")
ARCBank.Loaded = false

function ENT:CanProperty( ply, property ) 
	if self.ARCBank_MapEntity then
		return false 
	end
end


function ENT:SetATMType(typ)
	if typ && file.Exists(ARCBank.Dir.."/custom_atms/"..typ..".txt","DATA") then
		local tab = util.JSONToTable(file.Read(ARCBank.Dir.."/custom_atms/"..typ..".txt","DATA"))
		if tab then
			self.ATMType = tab
			self:SetModel( tab.Model )
			self:PhysicsInit( SOLID_VPHYSICS )
			self:SetMoveType( MOVETYPE_VPHYSICS )
			self:SetSolid( SOLID_VPHYSICS )
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake() 
			end
			self:SetSkin(tab.CloseSkin)
			return true
		else
			return false
		end
	elseif file.Exists(ARCBank.Dir.."/custom_atms/default.txt","DATA") then
		local tab = util.JSONToTable(file.Read(ARCBank.Dir.."/custom_atms/default.txt","DATA"))
		if tab then
			self.ATMType = tab
			self:SetModel( tab.Model )
			self:PhysicsInit( SOLID_VPHYSICS )
			self:SetMoveType( MOVETYPE_VPHYSICS )
			self:SetSolid( SOLID_VPHYSICS )
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake() 
			end
			return true
		else
			return false
		end
	else
		return false
	end
end
function ENT:GetATMType()
	return self.ATMType.Name
end

function ENT:Hackable()
	return not self.Broken and self.RebootTime < CurTime() and self.UsePlayer == nil
end

function ENT:Break()
	self.Broken = true
	net.Start("arcbank_atm_reboot")
	net.WriteUInt(self:EntIndex(),16)
	net.WriteBool(true)
	net.WriteDouble(self.RebootTime)
	net.Broadcast()
end

function ENT:HackStop()
	if self.DoingSomething then
		return true
	end
	self.Hacked = false
	self:Break()
	self.InUse = false
	timer.Simple((CurTime()-self.StartHackTime)*0.5,function()
		if !IsValid(self) then return end
		if self.Broken then
			self:Reboot(3)
		end
	end)
end
function ENT:HackStart()
	self.Hacked = true
	self.StartHackTime = CurTime()
end
function ENT:HackSpark()

end
function ENT:HackProgress()

end


function ENT:HackComplete(ply,amount,rand)
	self.DoingSomething = true
	self.InUse = true
	self.TakingMoney = true
	if ply.ARCBank_Secrets && self.ATMType.UseMoneyModel then --TODO: Have this work with multiple ATM Types instead of only the default one
		self:EmitSound("^arcbank/atm/spit-out.wav")
		timer.Simple(6.5,function()
			if self.ATMType.ModelOpen != "" then
				self:SetModel( self.ATMType.ModelOpen ) 
			end
		end)
		timer.Simple(6.8,function() 
			net.Start("ARCATM_COMM_BEEP")
			net.WriteEntity(self)
			net.WriteBit(true)
			net.Broadcast()
			self:EmitSound("arcbank/atm/lolhack.wav")
			local moneyproppos = self:GetPos() + ((self:GetAngles():Up() * 0.2) + (self:GetAngles():Forward() * -4.0) + (self:GetAngles():Right() * -0.4))
			self.UsePlayer = nil
			self:SetARCBankUsePlayer(NULL)
			timer.Destroy( "ATM_WIN" ) 
			timer.Create( "ATM_WIN", 0.2, math.random(10,20), function()
				local moneyprop = ents.Create( "sent_arc_cash" )
				moneyprop:SetModel( self.ATMType.MoneyModel )
				moneyprop:SetPos( self:LocalToWorld(self.ATMType.WithdrawAnimationPos))
				moneyprop:SetAngles( self:LocalToWorldAngles(self.ATMType.WithdrawAnimationAng) )
				moneyprop:SetValue(1000)
				moneyprop:Spawn()
				timer.Simple(0,function()
					if IsValid(moneyprop) then
						moneyprop:GetPhysicsObject():SetVelocity((moneyprop:GetForward()*self.ATMType.WithdrawAnimationSpeed.x + moneyprop:GetRight()*self.ATMType.WithdrawAnimationSpeed.y + moneyprop:GetUp()*self.ATMType.WithdrawAnimationSpeed.z*10 )* 10)
					end
				end)
				constraint.NoCollide( self, moneyprop, 0, 0 ) 
			end)
		end)
		timer.Simple(11,function() 
			if self.ATMType.ModelOpen != "" then
				self:SetModel( self.ATMType.Model ) 
			end
			self:EmitSound("arcbank/atm/close.wav")
			net.Start("ARCATM_COMM_BEEP")
			net.WriteEntity(self)
			net.WriteBit(false)
			net.Broadcast()
			self.DoingSomething = false
		end)
	else
	
		----MsgN("HACK ERORR:"..tostring(accounts))
		--self:StopHack()
		self.args = {}
		self.UsePlayer = ply
		
		self:SetARCBankUsePlayer(ply)
		local nextper = 0
		ARCBank.StealMoney(ply,rand,amount,function(err,progress,amount)
			if err == ARCBANK_ERROR_DOWNLOADING then
				if progress > nextper then
					ARCBank.MsgCL(ply,ARCBank.Msgs.Items.Hacker..": (%"..math.floor(progress*100)..")")
					nextper = nextper + 0.01
				end
			elseif err == 0 then
				ARCBank.MsgCL(ply,ARCBank.Msgs.Items.Hacker..": (%100)")
				self.args.money = amount
				self:WithdrawAnimation()
				timer.Simple(self.ATMType.PauseBeforeWithdrawAnimation + self.ATMType.PauseAfterWithdrawAnimation + self.ATMType.WithdrawAnimationLength,function()
					if !IsValid(self) then return end
					self.PlayerNeedsToDoSomething = true
					self.Beep = true
				end)
			else
				ARCLib.NotifyPlayer(ply,ARCBank.Msgs.Items.Hacker..": "..ARCBANK_ERRORSTRINGS[err],NOTIFY_ERROR,6,true)
				self.DoingSomething = false
				-- SHIT HAPPENED, BRAH
			end
		end)
	end
	

end

function ENT:Reboot(t)
	if self.InUse and IsValid(self.UsePlayer) then
		self:ATM_USE(self.UsePlayer)
	end
	self.RebootTime = CurTime() + 8 + (t||0)
	self.Broken = false
	net.Start("arcbank_atm_reboot")
	net.WriteUInt(self:EntIndex(),16)
	net.WriteBool(false)
	net.WriteDouble(self.RebootTime)
	net.Broadcast()
	self:EmitSound("ambient/levels/citadel/stalk_poweroff_on_17_10.wav")
end

function ENT:Initialize()
	self.MonehDelay = CurTime()
	self.DoingSomething = false
	if (self:SetATMType(self.ARCBank_InitSpawnType)) then
		self.RebootTime = CurTime() + 6
	else
		ARCLib.NotifyBroadcast("Failed to spawn ATM because the custom ATM type is invalid!\n(Note: I didn't translate this because this should never happen)",NOTIFY_ERROR,10,true)
		timer.Simple(0.01,function() 
			self:Remove() 
		end)
	end
end
function ENT:SpawnFunction( ply, tr )
	ply:ConCommand("arcbank atm_spawn")
end
function ENT:Think()
	if self.PermaProps then
		ARCLib.NotifyBroadcast("Do not use PermaProps with the ATMs! Please go to aritzcracker.ca/faq/arcbank",NOTIFY_ERROR,10,true)
		if self.ID then
			sql.Query("DELETE FROM permaprops WHERE id = ".. self.ID ..";")
		end
		self:Remove()
		self.PermaProps = false
	end

	if self.UsePlayer && !IsValid(self.UsePlayer) && !self.Hacked then
		self.InUse = false
		self.UsePlayer = nil
		self:SetARCBankUsePlayer(NULL)
		if self.PlayerNeedsToDoSomething then
			if self.TakingMoney then
				self.errorc = ARCBANK_ERROR_ABORTED
				if IsValid(self.moneyprop) then
					self.moneyprop:Remove()
				end
			else
				self.errorc = ARCBANK_ERROR_ABORTED
				self:EmitSound("^arcbank/atm/eat-duh-cash-stop.wav",65,100)
				timer.Simple(2,function() self.TakingMoney = true end)
				self.whirsound:Stop()
			end
			self.PlayerNeedsToDoSomething = false
			self.DoingSomething = false
		end
		return
	end
	
	if self.PlayerNeedsToDoSomething then
		self.Beep = true
	elseif self.Beep && self.TakingMoney then
		--timer.Simple(0.1, function() self:SetSkin( 2 ) end)
		if self.Hacked then
			self:EmitSoundTable(self.ATMType.CloseSound,65,math.random(95,110))
		else
			self:EmitSoundTable(self.ATMType.CloseSound,65,100)
		end
		if self.ATMType.ModelOpen != "" then
			self:SetModel( self.ATMType.Model )
		end
		self:SetSkin(self.ATMType.CloseSkin)
		if self.ATMType.CloseAnimation != "" then
			self:ARCLib_SetAnimationTime(atm.ATMType.CloseAnimation,atm.ATMType.CloseAnimationLength)
		end
		if IsValid(self.UsePlayer) then
			net.Start( "ARCATM_COMM_CASH" )
			net.WriteEntity( self.Entity )
			net.WriteInt(self.errorc,ARCBANK_ERRORBITRATE)
			net.Send(self.UsePlayer)
		end
		self.Beep = false
		self.DoingSomething = false
		self:NextThink( CurTime() + 2 )
		return true
	end
	
	if self.Beep then
		if self.Hacked then
			self.UsePlayer = ARCLib.GetNearestPlayer(self:GetPos())
			self:SetARCBankUsePlayer(self.UsePlayer)
			--MsgN("UserPlayer is "..self.UsePlayer:Nick())
			self:EmitSoundTable(self.ATMType.WaitSound,65,math.random(95,110))
		else
			self:EmitSound(table.Random(self.ATMType.WaitSound),65,100)
			if !self.Hacked && self.PlayerNeedsToDoSomething && IsValid(self.UsePlayer) && self:GetPos():DistToSqr( self.UsePlayer:GetPos() ) > 25000 then
				
				if self.TakingMoney then
					self.errorc = ARCBANK_ERROR_ABORTED
					if IsValid(self.moneyprop) then
						self.moneyprop:Remove()
					end
				else
					self.errorc = ARCBANK_ERROR_ABORTED
					self:EmitSoundTable(self.ATMType.DepositFailSound,65,100)
					timer.Simple(2,function() self.TakingMoney = true end)
					self.whirsound:Stop()
				end
				if IsValid(self.UsePlayer) then
					net.Start( "ARCATM_COMM_WAITMSG" )
					net.WriteEntity( self.Entity )
					net.WriteUInt(0,2)
					net.Send(self.UsePlayer)
				end
				self.PlayerNeedsToDoSomething = false
			end
		end
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
	
	
	
	if !self.Hacked && self.InUse && IsValid(self.UsePlayer) &&self.UsePlayer:Alive() && self.MonehDelay < CurTime() && self:GetPos():DistToSqr( self.UsePlayer:GetPos() ) > 25000 then
		ARCLib.NotifyPlayer(self.UsePlayer,ARCBank.Msgs.ATMMsgs.PlayerTooFar,NOTIFY_ERROR,2,false)
		self:ATM_USE(self.UsePlayer)
	end
end
net.Receive( "ARCATM_USE", function(length,ply)
	local atm = net.ReadEntity() 
	if IsValid(ply) && ply:IsPlayer() && atm.InUse && atm.UsePlayer == ply then
		atm:ATM_USE(atm.UsePlayer)
	end
end)
function ENT:CPPICanTool(ply,tool)
	if !ply:IsPlayer() || self.ARCBank_MapEntity then
		return false
	else
		return true
	end
end
function ENT:Use( ply, caller )
	if self.InUse && ply == self.UsePlayer && self.PlayerNeedsToDoSomething then
		local hit,dir,frac = util.IntersectRayWithOBB(ply:GetShootPos(),ply:GetAimVector()*100, self:LocalToWorld(self.ATMType.MoneyHitBoxPos), self:LocalToWorldAngles(self.ATMType.MoneyHitBoxAng), vector_origin, self.ATMType.MoneyHitBoxSize)  
		if hit && self.MonehDelay <= CurTime() then
			self.MonehDelay = CurTime() + 5
			if self.TakingMoney then
				if self.Hacked then
					ARCBank.PlayerAddMoney(self.UsePlayer,self.args.money)
					self.errorc = 0
					self.UsePlayer = nil
					self:SetARCBankUsePlayer(NULL)
					if self.ATMType.UseMoneyModel and IsValid(self.moneyprop) then
						self.moneyprop:Remove()
					end
					self:EmitSound("foley/alyx_hug_eli.wav",65,math.random(225,255))
					self.PlayerNeedsToDoSomething = false
				else
					ARCBank.AddFromWallet(self.UsePlayer,self.args.name,-self.args.money,"ATM",function(errc)
						self.errorc = errc
						if self.ATMType.UseMoneyModel and IsValid(self.moneyprop) then
							self.moneyprop:Remove()
						end
						if errc == ARCBANK_ERROR_NONE then
							self:EmitSound("foley/alyx_hug_eli.wav",65,math.random(225,255))
						end
						self.PlayerNeedsToDoSomething = false
					end)
				end
			else
			
				ARCBank.AddFromWallet(self.UsePlayer,self.args.name,self.args.money,"ATM",function(errc)
					self.errorc = errc
					if self.errorc == 0 then
						self:EmitSoundTable(self.ATMType.DepositDoneSound,65,100)
						if self.ATMType.DepositAnimation != "" then
							self:ARCLib_SetAnimationTime(self.ATMType.DepositAnimation,self.ATMType.DepositAnimationLength)
						end
						if self.ATMType.UseMoneyModel then

							self.moneyprop = ents.Create( "prop_physics" )
							if IsValid(self.moneyprop) then
								self.moneyprop.ARCBank_MapEntity = true
								self.moneyprop:SetModel( self.ATMType.MoneyModel )
								self.moneyprop:SetKeyValue("spawnflags","516")
								self.moneyprop:SetPos( self:LocalToWorld(self.ATMType.DepositAnimationPos))
								self.moneyprop:SetAngles( self:LocalToWorldAngles(self.ATMType.DepositAnimationAng) )
								self.moneyprop:Spawn()
								self.moneyprop:GetPhysicsObject():EnableCollisions(false)
								self.moneyprop:GetPhysicsObject():EnableGravity(false)
								self.moneyprop:GetPhysicsObject():SetVelocity(self.moneyprop:GetForward()*self.ATMType.DepositAnimationSpeed.x + self.moneyprop:GetRight()*self.ATMType.DepositAnimationSpeed.y + self.moneyprop:GetUp()*self.ATMType.DepositAnimationSpeed.z)
							end
							--MsgN(tostring(self.moneyprop:GetAngles():Up()).." + "..tostring(self.ATMType.DepositAnimationSpeed).." = ".. tostring(self.moneyprop:GetAngles():Up() * self.ATMType.DepositAnimationSpeed))
							timer.Simple(self.ATMType.DepositAnimationLength,function() if IsValid(self.moneyprop) then self.moneyprop:Remove() end end)
						end
						timer.Simple(self.ATMType.PauseAfterDepositAnimation,function() self.TakingMoney = true end)
					else
						self:EmitSoundTable(self.ATMType.DepositFailSound,65,100)
						timer.Simple(self.ATMType.PauseAfterDepositAnimationFail,function() self.TakingMoney = true end)
					end
					self.whirsound:Stop()
					self.PlayerNeedsToDoSomething = false
				end)
			end
			if IsValid(self.UsePlayer) then
				net.Start( "ARCATM_COMM_WAITMSG" )
				net.WriteEntity( self.Entity )
				net.WriteUInt(0,2)
				net.Send(self.UsePlayer)
			end
			
		end
	end
end
function ENT:OnRemove()
	if self.ARCBank_MapEntity then
		timer.Simple(1,function()
			ARCBank.SpawnATMs()
		end)
	end
	if self.InUse then

		self:ATM_USE(self.UsePlayer)
	end
	if IsValid(self.moneyprop) then
		self.moneyprop:Remove()
	end
	if self.whirsound then
		self.whirsound:Stop()
	end
end
function ENT:ATM_USE(activator)
	if IsValid(activator) && activator:IsPlayer() then
		if self.Hacked then return end
		if self.InUse then
			if activator == self.UsePlayer then
				
				if self.ATMType.CardRemoveAnimation != "" then
					self:ARCLib_SetAnimationTime(self.ATMType.CardRemoveAnimation,self.ATMType.CardRemoveAnimationLength)
				end
				self:EmitSoundTable(self.ATMType.WithdrawCardSound,65,math.random(95,105))
				
				local selfcard = ents.Create( "prop_physics" )
				if IsValid(selfcard) then
					selfcard.ARCBank_MapEntity = true
					selfcard:SetModel( self.ATMType.CardModel )
					selfcard:SetKeyValue("spawnflags","516")
					selfcard:SetPos( self:LocalToWorld(self.ATMType.CardRemoveAnimationPos))
					selfcard:SetAngles( self:LocalToWorldAngles(self.ATMType.CardRemoveAnimationAng) )
					selfcard:Spawn()
					if self.ATMType.CardModel == "models/arc/card.mdl" then
						selfcard:SetSubMaterial(2,ARCBank.Settings.card_texture_world)
					end
					selfcard:GetPhysicsObject():EnableCollisions(false)
					selfcard:GetPhysicsObject():EnableGravity(false)
					selfcard:GetPhysicsObject():SetVelocity(selfcard:GetForward()*self.ATMType.CardRemoveAnimationSpeed.x + selfcard:GetRight()*self.ATMType.CardRemoveAnimationSpeed.y + selfcard:GetUp()*self.ATMType.CardRemoveAnimationSpeed.z)
					timer.Simple(self.ATMType.CardRemoveAnimationLength-0.3,function() selfcard:GetPhysicsObject():SetVelocity(Vector(0,0,0)) end)
					timer.Simple(self.ATMType.CardRemoveAnimationLength,function() 
						--MsgN(self:WorldToLocal(selfcard:GetPos()))
						if IsValid(selfcard) then
							selfcard:Remove() 
						end
					end)
				end
				local ply = self.UsePlayer
				timer.Simple(0.5,function()
					ply:Give(ARCBank.Settings["card_weapon"])
					ply:SelectWeapon(ARCBank.Settings["card_weapon"])
				end)
				
				self.InUse = false
				table.RemoveByValue(ARCBank.Disk.NommedCards,activator:SteamID())
				self.UsePlayer = nil
				self:SetARCBankUsePlayer(NULL)
				net.Start( "ARCATM_USE" )
				net.WriteEntity( self )
				net.WriteBit(false)
				net.Send(activator)
				

			else
				--ARCBank.Msgs.UserMsgs.ATMUsed
				
				ARCLib.NotifyPlayer(activator,string.Replace(ARCBank.Msgs.UserMsgs.ATMUsed, "%PLAYER%", self.UsePlayer:Nick()) ,NOTIFY_GENERIC,5,true)
			end
		elseif ARCBank.Loaded && self.RebootTime < CurTime() && !self.Broken then

			if self.ATMType.CardInsertAnimation != "" then
				self:ARCLib_SetAnimationTime(self.ATMType.CardInsertAnimation,self.ATMType.CardInsertAnimationLength)
			end
			self:EmitSoundTable(self.ATMType.InsertCardSound,65,math.random(95,105))
			
			local selfcard = ents.Create( "prop_physics" )
			if IsValid(selfcard) then
				selfcard.ARCBank_MapEntity = true
				selfcard:SetModel( self.ATMType.CardModel )
				selfcard:SetKeyValue("spawnflags","516")
				selfcard:SetPos( self:LocalToWorld(self.ATMType.CardInsertAnimationPos))
				selfcard:SetAngles( self:LocalToWorldAngles(self.ATMType.CardInsertAnimationAng) )
				selfcard:Spawn()
				if self.ATMType.CardModel == "models/arc/card.mdl" then
					selfcard:SetSubMaterial(2,ARCBank.Settings.card_texture_world)
				end
				selfcard:GetPhysicsObject():EnableCollisions(false)
				selfcard:GetPhysicsObject():EnableGravity(false)
				selfcard:GetPhysicsObject():SetVelocity(selfcard:GetForward()*self.ATMType.CardInsertAnimationSpeed.x + selfcard:GetRight()*self.ATMType.CardInsertAnimationSpeed.y + selfcard:GetUp()*self.ATMType.CardInsertAnimationSpeed.z)
				timer.Simple(self.ATMType.CardInsertAnimationLength,function() 
					--MsgN(self:WorldToLocal(selfcard:GetPos()))
					selfcard:Remove() 
				end)
			end
			self.InUse = true
			table.insert(ARCBank.Disk.NommedCards,activator:SteamID())
			self.UsePlayer = activator
			self:SetARCBankUsePlayer(activator)
			activator:SwitchToDefaultWeapon() 
			activator:StripWeapon( ARCBank.Settings["card_weapon"] ) 
			if IsValid(activator) then
				net.Start( "ARCATM_USE" )
				net.WriteEntity( self )
				net.WriteBit(true)
				net.Send(activator)
			end
			
		end
	end
	return true
end

function ENT:WithdrawAnimation()
	local atm = self
	timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation,function() 
		if atm.ATMType.ModelOpen != "" then
			atm:SetModel( atm.ATMType.ModelOpen ) 
		end
		atm:SetSkin(atm.ATMType.OpenSkin)
		if atm.ATMType.OpenAnimation != "" then
			atm:ARCLib_SetAnimationTime(atm.ATMType.OpenAnimation,atm.ATMType.OpenAnimationLength)
		end
	end)
	timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.PauseAfterWithdrawAnimation,function() 
		if atm.ATMType.UseMoneyModel then
			atm.moneyprop = ents.Create( "prop_physics" )
			if IsValid(atm.moneyprop) then
				atm.moneyprop.ARCBank_MapEntity = true
				atm.moneyprop:SetModel( atm.ATMType.MoneyModel )
				atm.moneyprop:SetKeyValue("spawnflags","516")
				atm.moneyprop:SetPos( atm:LocalToWorld(atm.ATMType.WithdrawAnimationPos))
				atm.moneyprop:SetAngles( atm:LocalToWorldAngles(atm.ATMType.WithdrawAnimationAng) )
				atm.moneyprop:Spawn()
				atm.moneyprop:GetPhysicsObject():EnableCollisions(false)
				atm.moneyprop:GetPhysicsObject():EnableGravity(false)
				timer.Simple(atm.ATMType.WithdrawAnimationLength,function() 
					if IsValid(atm.moneyprop) then
						atm.moneyprop:GetPhysicsObject():SetVelocity(Vector(0,0,0)) 
						atm.moneyprop:GetPhysicsObject():EnableMotion( false) 
					end
				end)
				atm.moneyprop:GetPhysicsObject():SetVelocity(atm.moneyprop:GetForward()*atm.ATMType.WithdrawAnimationSpeed.x + atm.moneyprop:GetRight()*atm.ATMType.WithdrawAnimationSpeed.y + atm.moneyprop:GetUp()*atm.ATMType.WithdrawAnimationSpeed.z)
			end
		end
		if atm.ATMType.WithdrawAnimation != "" then
			atm:ARCLib_SetAnimationTime(atm.ATMType.WithdrawAnimation,atm.ATMType.WithdrawAnimationLength)
		end
	end)
	atm:EmitSoundTable(atm.ATMType.WithdrawSound,65,100)
	atm.MonehDelay = CurTime() + atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.PauseAfterWithdrawAnimation + atm.ATMType.WithdrawAnimationLength
end

util.AddNetworkString( "ARCATM_COMM_CASH" )

net.Receive( "ARCATM_COMM_CASH", function(length,ply)
	local atm = net.ReadEntity() 
	local acc = net.ReadString()
	local take = tobool(net.ReadBit())
	local amount = net.ReadUInt(32)
	if !IsValid(atm) || !atm.IsAFuckingATM || !atm.ARCBank_IsAValidDevice then
		ARCBank.FuckIdiotPlayer(ply,"Invalid ATM entity") 
		net.Start( "ARCATM_COMM_CASH" )
		net.WriteEntity( atm )
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)
		return
	end
	if ply != atm.UsePlayer then
		ARCBank.FuckIdiotPlayer(ply,"Withdrawing cash from ATM s/he's not using") 
		net.Start( "ARCATM_COMM_CASH" )
		net.WriteEntity( atm )
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(ply)	
		return
	end
	if amount < 0 then -- This should never happen, but apperently, unsigned ints turn into ints. Which kind makes the limit 2^31 - 1 instead of 2^32 - 1
		ARCBank.FuckIdiotPlayer(ply,"ATM Negative Withdraw/Deposit Request")
		net.Start( "ARCATM_COMM_CASH" )
		net.WriteEntity( atm )
		net.WriteInt(ARCBANK_ERROR_EXPLOIT,ARCBANK_ERRORBITRATE)
		net.Send(atm.UsePlayer)
		return
	end
	if (atm.DoingSomething) then
		ply:PrintMessage(HUD_PRINTTALK, "I'm not sure what you're trying to do... I won't ban you for it, but it can't be good.")
		return
	end
	
	atm.DoingSomething = true
	
	atm.TakingMoney = take
	atm.errorc = 0
	atm.args = {}
	atm.args.money = amount
	atm.args.name = acc
	if take then
		--atm.TakingMoney = true
		--ARCBank.CanAfford(atm.UsePlayer,amount,acc,function(errc)
		ARCBank.CanAfford(ply,acc,amount,function(errc)
			atm.errorc = errc
			
			if atm.errorc == ARCBANK_ERROR_NONE then
				atm:WithdrawAnimation()
				
				
				timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.PauseAfterWithdrawAnimation + atm.ATMType.WithdrawAnimationLength,function()
					if IsValid(atm.UsePlayer) then
						net.Start( "ARCATM_COMM_WAITMSG" )
						net.WriteEntity( atm )
						net.WriteUInt(2,2)
						net.Send(ply)
					end
					ARCLib.NotifyPlayer(ply,ARCBank.Msgs.UserMsgs.WithdrawATM,NOTIFY_HINT,5,false)
					atm.PlayerNeedsToDoSomething = true
					atm.Beep = true
				end)
			else
				if IsValid(atm.UsePlayer) then
					net.Start( "ARCATM_COMM_CASH" )
					net.WriteEntity( atm )
					net.WriteInt(atm.errorc,ARCBANK_ERRORBITRATE)
					net.Send(atm.UsePlayer)
				end
				atm.DoingSomething = false
			end
		end)
	else
		--atm.TakingMoney = false
		atm:EmitSoundTable(atm.ATMType.DepositStartSound,65,100)
		if #atm.ATMType.DepositLoopSound > 0 then
			atm.whirsound = CreateSound( atm, table.Random(atm.ATMType.DepositLoopSound)) 
		end			
		atm.MonehDelay = CurTime() + 5
		timer.Simple(atm.ATMType.PauseBeforeDepositAnimation, function() 
			if atm.ATMType.ModelOpen != "" then
				atm:SetModel( atm.ATMType.ModelOpen)
			end
			atm:SetSkin(atm.ATMType.OpenSkin)
			if atm.ATMType.OpenAnimation != "" then
				atm:ARCLib_SetAnimationTime(ply,atm.ATMType.OpenAnimation,atm.ATMType.OpenAnimationLength)
			end
		end)
		timer.Simple(atm.ATMType.PauseBeforeDepositAnimation + atm.ATMType.PauseBeforeDepositSoundLoop,function()
			ARCLib.NotifyPlayer(ply,ARCBank.Msgs.UserMsgs.DepositATM,NOTIFY_HINT,5,false)
			if IsValid(ply) then
				net.Start( "ARCATM_COMM_WAITMSG" )
				net.WriteEntity( atm )
				net.WriteUInt(1,2)
				net.Send(ply)
			end
			atm.PlayerNeedsToDoSomething = true
			if #atm.ATMType.DepositLoopSound > 0 then
				atm.whirsound:PlayEx(0.65, 100)
			end
		end)
	end
		
end)


