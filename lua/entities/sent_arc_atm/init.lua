-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
--Stuff
util.AddNetworkString( "ARCBank CustomATM" )
net.Receive( "ARCBank CustomATM", function(length,ply)
	if !ply.ARCLoad_Loaded then return end -- This data will be sent to the player when s/he loads anyway.
	local atm = net.ReadEntity()
	if atm:GetClass() == "sent_arc_atm" then
		net.Start("ARCBank CustomATM")
		net.WriteEntity(atm)
		net.WriteString(util.TableToJSON(atm.ATMType))
		net.Send(ply)
	end
end)

util.AddNetworkString( "ARCATM_USE" )
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
function ENT:Initialize()
	self.MonehDelay = CurTime()
	self.DoingSomething = false
	if (self:SetATMType(self.ARCBank_InitSpawnType)) then
		self.HackRecover = CurTime() + 6
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
		ARCLib.NotifyBroadcast("Do not use PermaProps with the ATMs! Please go to aritzcracker.ca/arcbank_faq.php",NOTIFY_ERROR,10,true)
		if self.ID then
			sql.Query("DELETE FROM permaprops WHERE id = ".. self.ID ..";")
		end
		self:Remove()
		self.PermaProps = false
	end

	if self.UsePlayer && !IsValid(self.UsePlayer) && !self.Hacked then
		self.InUse = false
		self.UsePlayer = nil
		if self.PlayerNeedsToDoSomething then
			if self.TakingMoney then
				self.errorc = ARCBANK_ERROR_ABORTED
				self.moneyprop:Remove()
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
		self:SetModel( self.ATMType.Model ) 
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
	end
	
	if self.Beep then
		if self.Hacked then
			self.UsePlayer = ARCLib.GetNearestPlayer(self:GetPos())
			--MsgN("UserPlayer is "..self.UsePlayer:Nick())
			self:EmitSoundTable(self.ATMType.WaitSound,65,math.random(95,110))
		else
			self:EmitSound(table.Random(self.ATMType.WaitSound),65,100)
			if !self.Hacked && self.PlayerNeedsToDoSomething && IsValid(self.UsePlayer) && self:GetPos():DistToSqr( self.UsePlayer:GetPos() ) > 25000 then
				
				if self.TakingMoney then
					self.errorc = ARCBANK_ERROR_ABORTED
					self.moneyprop:Remove()
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
			self.MonehDelay = CurTime() + 1
			if self.TakingMoney then
				if self.Hacked then
					ARCBank.PlayerAddMoney(self.UsePlayer,self.args.money)
					self.errorc = 0
					self.UsePlayer = nil
					timer.Simple(math.Rand(2,10),function()
						if IsValid(self.HackUnit) then
							self.HackUnit:StopHack()
						end
					end)
						if self.ATMType.UseMoneyModel then
							self.moneyprop:Remove()
						end
					self:EmitSound("foley/alyx_hug_eli.wav",65,math.random(225,255))
					self.PlayerNeedsToDoSomething = false
				else
					ARCBank.AtmFunc(self.UsePlayer,-self.args.money,self.args.name,function(errc)
						self.errorc = errc
						if self.ATMType.UseMoneyModel then
							self.moneyprop:Remove()
						end
						self:EmitSound("foley/alyx_hug_eli.wav",65,math.random(225,255))
						self.PlayerNeedsToDoSomething = false
					end)
				end
			else
				ARCBank.AtmFunc(self.UsePlayer,self.args.money,self.args.name,function(errc)
					self.errorc = errc
					if self.errorc == 0 then
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
				selfcard:SetModel( self.ATMType.CardModel )
				selfcard:SetKeyValue("spawnflags","516")
				selfcard:SetPos( self:LocalToWorld(self.ATMType.CardRemoveAnimationPos))
				selfcard:SetAngles( self:LocalToWorldAngles(self.ATMType.CardRemoveAnimationAng) )
				selfcard:Spawn()
				selfcard:GetPhysicsObject():EnableCollisions(false)
				selfcard:GetPhysicsObject():EnableGravity(false)
				selfcard:GetPhysicsObject():SetVelocity(selfcard:GetForward()*self.ATMType.CardRemoveAnimationSpeed.x + selfcard:GetRight()*self.ATMType.CardRemoveAnimationSpeed.y + selfcard:GetUp()*self.ATMType.CardRemoveAnimationSpeed.z)
				timer.Simple(self.ATMType.CardRemoveAnimationLength-0.3,function() selfcard:GetPhysicsObject():SetVelocity(Vector(0,0,0)) end)
				timer.Simple(self.ATMType.CardRemoveAnimationLength,function() 
				--MsgN(self:WorldToLocal(selfcard:GetPos()))
				selfcard:Remove() 
				end)
				
				local ply = self.UsePlayer
				timer.Simple(0.5,function()
					ply:Give("weapon_arc_atmcard")
					ply:SelectWeapon("weapon_arc_atmcard")
				end)
				
				self.InUse = false
				table.RemoveByValue(ARCBank.Disk.NommedCards,activator:SteamID())
				self.UsePlayer = nil
				net.Start( "ARCATM_USE" )
				net.WriteEntity( self )
				net.WriteBit(false)
				net.Send(activator)
				

			else
				--ARCBank.Msgs.UserMsgs.ATMUsed
				
				ARCLib.NotifyPlayer(activator,string.Replace(ARCBank.Msgs.UserMsgs.ATMUsed, "%PLAYER%", self.UsePlayer:Nick()) ,NOTIFY_GENERIC,5,true)
			end
		elseif ARCBank.Loaded && self.HackRecover < CurTime() then

			if self.ATMType.CardInsertAnimation != "" then
				self:ARCLib_SetAnimationTime(self.ATMType.CardInsertAnimation,self.ATMType.CardInsertAnimationLength)
			end
			self:EmitSoundTable(self.ATMType.InsertCardSound,65,math.random(95,105))
			
			local selfcard = ents.Create( "prop_physics" )
			selfcard:SetModel( self.ATMType.CardModel )
			selfcard:SetKeyValue("spawnflags","516")
			selfcard:SetPos( self:LocalToWorld(self.ATMType.CardInsertAnimationPos))
			selfcard:SetAngles( self:LocalToWorldAngles(self.ATMType.CardInsertAnimationAng) )
			selfcard:Spawn()
			selfcard:GetPhysicsObject():EnableCollisions(false)
			selfcard:GetPhysicsObject():EnableGravity(false)
			selfcard:GetPhysicsObject():SetVelocity(selfcard:GetForward()*self.ATMType.CardInsertAnimationSpeed.x + selfcard:GetRight()*self.ATMType.CardInsertAnimationSpeed.y + selfcard:GetUp()*self.ATMType.CardInsertAnimationSpeed.z)
			timer.Simple(self.ATMType.CardInsertAnimationLength,function() 
			--MsgN(self:WorldToLocal(selfcard:GetPos()))
			selfcard:Remove() 
			end)
		
			self.InUse = true
			table.insert(ARCBank.Disk.NommedCards,activator:SteamID())
			self.UsePlayer = activator
			activator:SwitchToDefaultWeapon() 
			activator:StripWeapon( "weapon_arc_atmcard" ) 
			--activator:SendLua( "achievements.EatBall()" );
			if IsValid(activator) then
				net.Start( "ARCATM_USE" )
				net.WriteEntity( self )
				net.WriteBit(true)
				net.Send(activator)
			end
			
		end
	end
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
		net.Send(atm.UsePlayer)	
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
		ARCBank.CanAfford(atm.UsePlayer,amount,acc,function(errc)
			atm.errorc = errc
			if atm.errorc == ARCBANK_ERROR_NONE then
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
					if IsValid(atm.UsePlayer) then
						net.Start( "ARCATM_COMM_WAITMSG" )
						net.WriteEntity( atm )
						net.WriteUInt(2,2)
						net.Send(ply)
					end
					ARCLib.NotifyPlayer(ply,ARCBank.Msgs.UserMsgs.WithdrawATM,NOTIFY_HINT,5,false)
					atm.PlayerNeedsToDoSomething = true
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


