-- This file is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
if !WireLib then return end -- Don't do anything if wiremod isn't installed.
AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "ARCBank Card Machine Controller"
ENT.WireDebugName	= "Card Machine Controller"

if CLIENT then 

	return  -- No more client
end

-- Server


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self.Inputs = WireLib.CreateInputs( self, { "Amount","Enter","Cancel","GroupAccount [STRING]","Label [STRING]"} )
	self.Outputs = WireLib.CreateOutputs( self,{"Amount","RequestingCustomer","Success","Entity [ENTITY]"})
	self.WInputs = {}
	self.WInputs["Amount"] = 0
	self.WInputs["GroupAccount"] = ""
	self.WInputs["Label"] = "Card Machine"

	self:SetColor(Color(255,0,0,self:GetColor().a))
end

-- Accessor funcs for certain functions

function ENT:LinkEnt( CardM )
	--MsgN(CardM:GetClass())
	if !IsValid(CardM) || CardM:GetClass() != "sent_arc_pinmachine" then return false, "Must link to a ARCBank Card Machine" end
	self:SetMachine( CardM )
	WireLib.SendMarks(self, {CardM})
	return true
end
function ENT:UnlinkEnt()
	self.CardMachine = nil
	WireLib.SendMarks(self, {})
	WireLib.TriggerOutput( self, "Entity", NULL )
	return true
end

function ENT:HasMachine() return IsValid(self.CardMachine) end
function ENT:GetMachine() return self.CardMachine end
function ENT:SetMachine( CardM )
	if (!IsValid(CardM) || CardM:GetClass() != "sent_arc_pinmachine") then return false end
	self.CardMachine = CardM
	WireLib.TriggerOutput( self, "Entity", CardM )
	return true
end

function ENT:TriggerInput( name, value )
	if !self:HasMachine() then return end
	if name == "Enter" then
		if value > 0 && self.CardMachine.Status == 0 then
			self.CardMachine.ToAccount = self.WInputs["GroupAccount"]
			self.CardMachine.EnteredAmount = self.WInputs["Amount"]
			self.CardMachine.DemandingMoney = true
			self.CardMachine:SetScreenMsg("Cr "..tostring(self.WInputs["Amount"]),ARCBank.Msgs.CardMsgs.InsertCard)
			self.CardMachine.Reason = self.WInputs["Label"]
		end
	elseif name == "Cancel" then
		if self.CardMachine.DemandingMoney && value > 0 then
			self.CardMachine.EnteredAmount = 0
			self.CardMachine:EmitSound("buttons/button18.wav",75,255)
			self.CardMachine.DemandingMoney = false
			self.CardMachine:SetScreenMsg("*Operation*","*Cancelled*")
			timer.Simple(1.5,function()
				self.CardMachine:SetScreenMsg("**ARCBank**",string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", self.CardMachine._Owner:Nick() ))
			end)
		end
	else
		self.WInputs[name] = value
	end
end

function ENT:Think()
	if !self:HasMachine() then return end
	WireLib.TriggerOutput(self, "Amount", self.CardMachine.EnteredAmount)
	WireLib.TriggerOutput(self, "RequestingCustomer", ARCLib.BoolToNumber(self.CardMachine.DemandingMoney))
	WireLib.TriggerOutput(self, "Success", self.CardMachine.Status)
end

duplicator.RegisterEntityClass("sent_arc_pinmachine_wire", WireLib.MakeWireEnt, "Data")
