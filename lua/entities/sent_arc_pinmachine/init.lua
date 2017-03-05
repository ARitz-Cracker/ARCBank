-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
util.AddNetworkString( "ARCCHIPMACHINE_STRINGS" )
util.AddNetworkString( "ARCCHIPMACHINE_MENU_OWNER" )
util.AddNetworkString( "ARCCHIPMACHINE_MENU_CUSTOMER" )
function ENT:Initialize()
	self:SetModel( "models/arc/atm_cardmachine.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS  )
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake() 
		phys:SetMaterial( "metal" )
	end
	self:SetUseType( SIMPLE_USE )
	self.Status = 0
	self.EnteredAmount = 0
	self.TopScreenText = ARCBank.Settings["name"]
	self.BottomScreenText = ARCBank.Msgs.CardMsgs.NoOwner
	self.FromAccount = ""
	self.ToAccount = ""
	self.Reason = "Card Machine"
	self._Owner = NULL
end
function ENT:SpawnFunction( ply, tr )
 	if ( !tr.Hit ) then return end
	local blarg = ents.Create ("sent_arc_pinmachine")
	blarg:SetPos(tr.HitPos + tr.HitNormal * 4)
	blarg:Spawn()
	blarg:Activate()
	timer.Simple(0.1,function()
		if blarg != NULL then
			blarg._Owner = ply
			blarg:SetScreenMsg(ARCBank.Settings["name"],string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ))
			if CPPI then -- Prop protection addons
				blarg:CPPISetOwner(ply)
			end
		end
	end)
	return blarg
end

function ENT:Think()

end

function ENT:OnRemove()

end
--dasdadadsadsa é
function ENT:Use(ply,caller)
	if !self._Owner || self._Owner == NULL || !self._Owner:IsPlayer() then 
		if ply:IsPlayer() then
			self:EmitSound("buttons/button18.wav",75,255)
			self._Owner = ply
			self:SetScreenMsg(ARCBank.Settings["name"],string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ))
			if CPPI then -- Prop protection addons
				timer.Simple(0.1,function()
					if IsValid(self) && IsValid(ply) && ply:IsPlayer() then
						if self:CPPISetOwner(ply) then
							ARCLib.NotifyPlayer(ply,string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ),NOTIFY_GENERIC,5,true)
						else
							ARCLib.NotifyPlayer(ply,"CPPI ERROR!",NOTIFY_ERROR,5,true)
						end
					end
				end)
				
			end
		end
		return 
	end
	if ply:IsPlayer() then
		if ply == self._Owner then
			if self.DemandingMoney then
				self:EmitSound("buttons/button18.wav",75,255)
				self.DemandingMoney = false
				self:SetScreenMsg("*Operation*","*Cancelled*")
				self.EnteredAmount = 0
				timer.Simple(1.5,function()
					self:SetScreenMsg(ARCBank.Settings["name"],string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ))
				end)
			else
				if self.Status == 0 then
				
					ARCBank.CanAccessAccount(ply,"",function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.GetGroupAccounts(ply,function(err,accounts)
								if err == ARCBANK_ERROR_NONE then
									for i=1,#accounts do
										accounts[i] = ARCLib.basexx.from_base32(string.upper(string.sub(accounts[i],1,#accounts[i]-1)))
									end
									table.insert( accounts, 1, ARCBank.Msgs.ATMMsgs.PersonalAccount )
									net.Start( "ARCCHIPMACHINE_MENU_OWNER" )
									net.WriteEntity(self.Entity)
									net.WriteTable(accounts)
									net.Send(ply)
								else
									ARCLib.NotifyPlayer(ply,ARCBANK_ERRORSTRINGS[err],NOTIFY_ERROR,5,true)
								end
							end)
						elseif err == ARCBANK_ERROR_NIL_ACCOUNT then
							ARCLib.NotifyPlayer(ply,ARCBank.Msgs.CardMsgs.NoAccount,NOTIFY_ERROR,5,true)
						else
							ARCLib.NotifyPlayer(ply,ARCBANK_ERRORSTRINGS[err],NOTIFY_ERROR,5,true)
						end
					end)
				end
			end
		else
			ARCLib.NotifyPlayer(ply,ARCBank.Msgs.CardMsgs.InvalidOwner,NOTIFY_GENERIC,5,true)
		end
	end
end
function ENT:ATM_USE(ply)
	if self.DemandingMoney then
		ARCBank.GetGroupAccounts(ply,function(errcode,accounts)
			if errcode == 0 then
				for i=1,#accounts do
					accounts[i] = ARCLib.basexx.from_base32(string.upper(string.sub(accounts[i],1,#accounts[i]-1)))
				end
				table.insert( accounts, 1, ARCBank.Msgs.ATMMsgs.PersonalAccount )
				net.Start( "ARCCHIPMACHINE_MENU_CUSTOMER" )
				net.WriteEntity(self.Entity)
				net.WriteTable(accounts)
				net.WriteFloat(self.EnteredAmount)
				net.Send(ply)
			else
				ARCLib.NotifyPlayer(ply,ARCBANK_ERRORSTRINGS[errcode],NOTIFY_ERROR,5,true)
			end
		end)
		return true
	else
		return false
	end
end
function ENT:SetScreenMsg(strtop,strbottom)
	net.Start( "ARCCHIPMACHINE_STRINGS" )
	net.WriteEntity(self.Entity)
	net.WriteString(strtop or "")
	net.WriteString(strbottom or "")
	net.WriteEntity(self._Owner)
	net.Broadcast()
	self.TopScreenText = strtop
	self.BottomScreenText = strbottom
end
net.Receive( "ARCCHIPMACHINE_STRINGS", function(length,ply)
	local ent = net.ReadEntity()
	net.Start( "ARCCHIPMACHINE_STRINGS" )
	net.WriteEntity(ent)
	net.WriteString(ent.TopScreenText or "")
	net.WriteString(ent.BottomScreenText or "")
	net.Send(ply)
end)
net.Receive( "ARCCHIPMACHINE_MENU_OWNER", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	local amount = net.ReadInt(32) 
	local re = net.ReadString()
	ent.ToAccount = account
	ent.EnteredAmount = amount
	ent.DemandingMoney = true
	ent:SetScreenMsg(string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(amount)),ARCBank.Msgs.CardMsgs.InsertCard)
	ent.Reason = re
end)
net.Receive( "ARCCHIPMACHINE_MENU_CUSTOMER", function(length,ply)
	local ent = net.ReadEntity()
	local account = net.ReadString()
	ent.FromAccount = account
	ent.DemandingMoney = false
	ARCBank.Transfer(ply,ent._Owner,ent.FromAccount,ent.ToAccount,ent.EnteredAmount,ent.Reason,function(errorcode)
		local errormsg = ARCBANK_ERRORSTRINGS[errorcode]
		ent:SetScreenMsg(tostring(errorcode),errormsg)
		local dollah = string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(ent.EnteredAmount))
		ARCLib.NotifyPlayer(ply,dollah.." - "..errormsg,math.Clamp(errorcode,0,1),5,true)
		ARCLib.NotifyPlayer(ent._Owner,dollah.." - "..errormsg.." ("..ply:Nick()..")",math.Clamp(errorcode,0,1),5,true)
		ent.EnteredAmount = 0
		if errorcode == 0 then
			ent.Status = 1
		else
			ent.Status = -1
		end
	end)
	timer.Simple(10,function()
		if ent == NULL then return end
		ent:SetScreenMsg(ARCBank.Settings["name"],string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ent._Owner:Nick() ))
		ent.Status = 0
	end)
end)


