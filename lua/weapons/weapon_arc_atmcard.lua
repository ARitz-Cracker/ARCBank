
AddCSLuaFile("weapon_arc_atmcard.lua")

SWEP.Author = "ARitz Cracker"
SWEP.Contact = "aritz@aritzcracker.ca"
SWEP.Purpose = nil
SWEP.Category = "ARitz Cracker Bank"
SWEP.Instructions = nil
SWEP.Spawnable = true;
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/v_hands.mdl";
SWEP.WorldModel = "models/arc/card.mdl";
SWEP.ViewModelFOV = 1
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.PrintName = "ARitz Cracker Bank Keycard"
SWEP.Slot = 1
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
if CLIENT then
	SWEP.WElements = {
		["card"] = { type = "Model", model = "models/arc/card.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4, 1.0, -0.425), angle = Angle(98.75, 92.75, -10.114), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
	}
	SWEP.WElements.card.submaterial = {}
	SWEP.WElements.card.submaterial[2] = "arc/card/cardex"
	
	SWEP.WepSelectIcon = surface.GetTextureID( "arc/atm_base/screen/cardex" )
	SWEP.HUDIcon = surface.GetTextureID( "arc/atm_base/screen/card" )
	function SWEP:DrawHUD() 
		--if ARCLoad.Loaded then
		if ARCBank.Settings["card_draw_vehicle"] or not self.Owner:InVehicle() then
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetTexture( self.HUDIcon ) 
			--surface.DrawOutlinedRect( surface.ScreenWidth() - 512, surface.ScreenHeight() - 256, 512, 256 )
			surface.DrawTexturedRect( surface.ScreenWidth() - 512 - ARCBank.Settings["card_weapon_position_left"], surface.ScreenHeight() - 256 - ARCBank.Settings["card_weapon_position_up"], 512, 256 )
			draw.SimpleText(ARCBank.GetPlayerID(self.Owner), "ARCBankCard", surface.ScreenWidth() - 430 - ARCBank.Settings["card_weapon_position_left"], surface.ScreenHeight() - 92 - ARCBank.Settings["card_weapon_position_up"], Color(255,255,255,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(self.Owner:Nick(), "ARCBankCard", surface.ScreenWidth() - 430 - ARCBank.Settings["card_weapon_position_left"], surface.ScreenHeight() - 55 - ARCBank.Settings["card_weapon_position_up"], Color(255,255,255,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		--end
	end
		
	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		if (!IsValid(self.Owner)) then
			self:DrawModel()
			return
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			-- when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				if v.submaterial then
					for kk,vv in pairs(v.submaterial) do
						model:SetSubMaterial(kk,vv)
					end
				end
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
			end
			
		end
		
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		-- Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
			end
		end
	end
	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			-- Technically, if there exists an element with the same name as a bone
			-- you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r -- Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end
end


function SWEP:DrawViewModel()
end
function SWEP:Initialize()
	self:SetNextPrimaryFire(CurTime() + 5)
	if ARCBank && ARCBank.Settings then
		if CLIENT && ARCBank.Settings.card_texture && ARCBank.Settings.card_texture != "arc/atm_base/screen/card" then
			self.WepSelectIcon = surface.GetTextureID( ARCBank.Settings.card_texture )
			self.HUDIcon = self.WepSelectIcon
		end
		if ARCBank.Settings.name_long then
			self.PrintName = ARCBank.Settings.name_long.." "..ARCBank.Msgs.Items.Card
		end
		self.Slot = ARCBank.Settings.card_weapon_slot or 1
		self.SlotPos = ARCBank.Settings.card_weapon_slotpos or 4
	end
	self:SetHoldType( "normal" )
	if CLIENT then
		self.WElements = table.FullCopy( self.WElements )
		self:CreateModels(self.WElements) -- create worldmodels
		self.WElements.card.submaterial[2] = ARCBank.Settings.card_texture_world or "arc/card/cardex"
	end
end
function SWEP:Deploy()
	if ARCBank && ARCBank.Settings then
		if CLIENT && ARCBank.Settings.card_texture && ARCBank.Settings.card_texture != "arc/atm_base/screen/card" then
			self.WepSelectIcon = surface.GetTextureID( ARCBank.Settings.card_texture )
			self.HUDIcon = self.WepSelectIcon
		end
		if ARCBank.Settings.name_long then
			self.PrintName = ARCBank.Settings.name_long.." "..ARCBank.Msgs.Items.Card
		end
		self.Slot = ARCBank.Settings.card_weapon_slot or 1
		self.SlotPos = ARCBank.Settings.card_weapon_slotpos or 4
		if CLIENT then
			self.WElements.card.submaterial[2] = ARCBank.Settings.card_texture_world or "arc/card/cardex"
		end
	end
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 1)
	if !SERVER then return end
	local trace = self.Owner:GetEyeTrace()
	if trace.HitPos:Distance(self:GetPos()) < 75 then
		if isfunction(trace.Entity.ATM_USE) then
			if (!trace.Entity:ATM_USE(self.Owner)) then
				ARCLib.NotifyPlayer(self.Owner,ARCBank.Msgs.CardMsgs.NoCard,NOTIFY_GENERIC,5,true)
			end
		else
			ARCLib.NotifyPlayer(self.Owner,ARCBank.Msgs.UserMsgs.CardNo,NOTIFY_GENERIC,5,true)
		end
	else
		ARCLib.NotifyPlayer(self.Owner,ARCBank.Msgs.UserMsgs.CardAir,NOTIFY_GENERIC,5,true)
	end
end
function SWEP:SecondaryAttack() return end
function SWEP:Think()
end
function SWEP:Reload() return end
