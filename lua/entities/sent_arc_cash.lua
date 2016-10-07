-- This file is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.

AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName		= "Cash"
ENT.Author			= "ARitz Cracker"
ENT.Category 		= "ARCBank"
ENT.Contact    		= "aritz@aritzcracker.ca"
ENT.Purpose 		= ""
ENT.Instructions 	= "Use"

ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "MoneyAmount" )
end

if CLIENT then 

	return  -- No more client
end

-- Server


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetModel( "models/props/cs_assault/money.mdl" )
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake() 
	end
end

function ENT:SetValue(val)
	self:SetMoneyAmount(val)
end

function ENT:Use( ply, caller )
	ARCBank.PlayerAddMoney(ply,1000)
	moneyprop:Remove()
end
