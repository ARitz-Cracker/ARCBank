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

ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "MoneyAmount" )
end

if CLIENT then 
local vector_up = Vector(0,0,1)
function ENT:Draw()
    self:DrawModel()
    local offset = (self:OBBMaxs() - self:OBBCenter())*vector_up
	
	local Pos = self:OBBCenter() 
    local Ang = self:GetAngles()

    surface.SetFont("ChatFont")
	
	
    local text = string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(self:GetMoneyAmount()))
    local TextWidth = surface.GetTextSize(text)

    cam.Start3D2D(self:LocalToWorld(Pos+offset), Ang, 0.1)
        draw.WordBox(2, -TextWidth * 0.5, -10, text, "ChatFont", Color(0, 140, 0, 100), Color(255, 255, 255, 255))
    cam.End3D2D()

    Ang:RotateAroundAxis(Ang:Right(), 180)

    cam.Start3D2D(self:LocalToWorld(Pos-offset), Ang, 0.1)
        draw.WordBox(2, -TextWidth * 0.5, -10, text, "ChatFont", Color(0, 140, 0, 100), Color(255, 255, 255, 255))
    cam.End3D2D()

end
	return  -- No more client
end

-- Server

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	ent:SetValue(1000)
	return ent

end

function ENT:Initialize()
	self:SetModel( ARCBank.Settings["death_money_drop_model"] )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake() 
	end
end

function ENT:SetValue(val)
	self:SetMoneyAmount(val)
end

function ENT:Use( ply, caller )
	ARCBank.PlayerAddMoney(ply,self:GetMoneyAmount() || 0)
	self:Remove()
end
