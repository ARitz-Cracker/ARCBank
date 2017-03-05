ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName		= "ARCBank ATM"
ENT.Author			= "ARitz Cracker"
ENT.Category 		= "ARCBank"
ENT.Contact    		= "aritz-rocks@hotmail.com"
ENT.Purpose 		= "The most amazing ATM you'll see in GMod"
ENT.Instructions 	= "Use a keycard"

ENT.Spawnable = true;
ENT.AdminOnly = false

ENT.IsAFuckingATM = true
ENT.ARCBank_IsAValidDevice = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "ARCBankUsePlayer" )
end
ENT.ARCBank_Permissions = 65535