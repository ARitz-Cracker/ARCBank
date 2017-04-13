-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
include('shared.lua')

function ENT:Initialize()
	self.FailTime = CurTime() + 30
	self.ATMType = {}
	self.ATMType.Name = ""
	self.ATMType.Model = ""
	self.ATMType.ModelOpen = ""
	
	self.ATMType.ModelSkinClosed = -1
	self.ATMType.ModelSkinOpen = -1
	self.ATMType.ModelSkinLight = -1
	
	self.ATMType.buttons = {}
	for i=0,23 do
		self.ATMType.buttons[i] = vector_origin
	end
	self.ATMType.Screen = vector_origin
	self.ATMType.ScreenAng = angle_zero
	self.ATMType.ScreenSize = 0.043
	
	self.ATMType.FullScreen = vector_origin
	self.ATMType.FullScreenAng = angle_zero
	
	self.ATMType.CardInsertPos = vector_origin
	self.ATMType.CardInsertVec = vector_origin
	self.ATMType.CardRemovePos = vector_origin
	self.ATMType.CardRemoveVec = vector_origin
	
	self.ATMType.MoneyInsertPos = vector_origin
	self.ATMType.MoneyInsertVec = vector_origin
	self.ATMType.MoneyRemovePos = vector_origin
	self.ATMType.MoneyRemoveVec = vector_origin
	
	self.ATMType.UseMoneylight = true
	self.ATMType.Moneylight = vector_origin
	self.ATMType.MoneylightAng = angle_zero
	self.ATMType.MoneylightSize = 0.099
	self.ATMType.MoneylightFill = false
	self.ATMType.MoneylightHeight = 10
	self.ATMType.MoneylightWidth = 42
	self.ATMType.MoneylightColour = Color(218,255,255,255)
	
	self.ATMType.UseCardlight = true
	self.ATMType.Cardlight = vector_origin
	self.ATMType.CardlightAng = angle_zero
	self.ATMType.CardlightSize = 0.3
	self.ATMType.CardlightFill = false
	self.ATMType.CardlightHeight = 8
	self.ATMType.CardlightWidth = 39
	self.ATMType.CardlightColour = Color(218,255,255,255)
	
	self.ATMType.BackgroundColour = Color(64,64,64,255) -- 25, 100, 255, 255 
	self.ATMType.ForegroundColour = Color(128,128,128,255) -- 0, 0, 255, 255 
	self.ATMType.WelcomeScreen = "arc/atm_base/screen/welcome_new"
	self.ATMType.Resolutionx = 278
	self.ATMType.Resolutiony = 315
	
	self.ATMType.ClientPressSounds = {}
	self.ATMType.PressSounds = {}
	self.ATMType.PressSoundsFail = {}

	self.SelectedButton = 1
	self.DarkMode = false
	self.Menu = false
	self.MsgBox = false
	self.SpriteNoZ = false
	local selectsprite = { sprite = "sprites/blueflare1", nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = true}
	local name = selectsprite.sprite.."-"
	local params = { ["$basetexture"] = selectsprite.sprite }
	local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
	for i, j in pairs( tocheck ) do
		if (selectsprite[j]) then
			params["$"..j] = 1
			name = name.."1"
		else
			name = name.."0"
		end
	end
	self.spriteMaterialNoZ = CreateMaterial(name,"UnlitGeneric",params)
	
	selectsprite = { sprite = "sprites/blueflare1", nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
	name = selectsprite.sprite.."-"
	params = { ["$basetexture"] = selectsprite.sprite }
	tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
	for i, j in pairs( tocheck ) do
		if (selectsprite[j]) then
			params["$"..j] = 1
			name = name.."1"
		else
			name = name.."0"
		end
	end
	self.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
	self.TourchScreenPos = {}
	self.TouchScreenY = 0
	self.TouchScreenX = 0
end


function ENT:Use()
	ARCBank.OpenATMCreatorGUI(self)
end

function ENT:OnRestore()
end

function ENT:Screen_Options()
	local halfres = math.Round(self.ATMType.Resolutionx*0.5)
	ARCBank_Draw:Window_MsgBox((halfres*-1)+2,-150,self.ATMType.Resolutionx-24,"ATM Menu Preview","I see you're customizing the ATM! Good for you!",self.DarkMode,0,ARCLib.GetWebIcon32("atm"),nil,self.ATMType.ForegroundColour)
	local light = 255*ARCLib.BoolToNumber(self.DarkMode)
	local darkk = 255*ARCLib.BoolToNumber(!self.DarkMode)
	
	for i = 1,8 do
		local xpos = 0
		if i%2 == 0 then
			xpos = (halfres*-1)+2
		else
			xpos = halfres - 136
		end
		local ypos = -80+((math.floor((i-1)/2))*61)
		local fitstr = ARCLib.FitText("This is option #"..i.." (Button #"..(i+12)..")","ARCBankATMNormal",98)
		surface.SetDrawColor( darkk, darkk, darkk, 255 )
		surface.DrawRect( xpos, ypos, 134, 40)
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( xpos, ypos, 134, 40)
		for ii = 1,#fitstr do
			draw.SimpleText( fitstr[ii], "ARCBankATMNormal",xpos+37+((i%2)*63), ypos+((ii-1)*12), Color(light,light,light,255), (i%2)*2 , TEXT_ALIGN_TOP  )
		end
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial(ARCLib.GetWebIcon32("information"))
		surface.DrawTexturedRect( xpos+2+((i%2)*98), ypos+4, 32, 32)
	end
	--[[
	surface.SetDrawColor( 0, 0, 0, 255 )
	for i = 0,7 do
		surface.DrawOutlinedRect( -137+(ARCLib.BoolToNumber(i>3)*140), -80+((i%4)*61), 134, 40)
	end
	]]
end
function ENT:Screen_Welcome()
	ARCBank_Draw:Window(-129, -142, 238, 257,ARCBank.Msgs.ATMMsgs.Welcome,self.DarkMode,nil,self.ATMType.ForegroundColour)
	surface.SetDrawColor( 255, 255, 255, 255 )
	if self.Hacked then
		if (!tobool(math.random(0,16)) || !self.hackdtx) then
			self.hackdtx = table.Random(self.ATMType.HackedWelcomeScreen)
		end
		surface.SetTexture(surface.GetTextureID(self.hackdtx))
		surface.DrawTexturedRect( -128, -122, 256, 256)
		ARCBank_Draw:Window_MsgBox(-125,-40,230,"Criticao EräÞr",ARCBank.Msgs.ATMMsgs.HackingError,self.DarkMode,0,ARCLib.GetIcon(2,"emotion_dead"))
	else
		surface.SetTexture(surface.GetTextureID(self.ATMType.WelcomeScreen))
		surface.DrawTexturedRect( -128, -122, 256, 256)
	end
	
--draw.SimpleText( "ARitz Cracker Bank", "ARCBankATMBigger", 0, 140, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
end
function ENT:Draw()--Good
	if self.ATMType.Name == "" then return end
	self:DrawModel()
	self:DrawShadow(true)
	
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 1000000 then return end
	
	--self.screenpos = self:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos)

	cam.Start3D2D(self:LocalToWorld(self.ATMType.Screen), self:LocalToWorldAngles(self.ATMType.ScreenAng), self.ATMType.ScreenSize)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawOutlinedRect( (self.ATMType.Resolutionx+2)/-2, (self.ATMType.Resolutiony+2)/-2, self.ATMType.Resolutionx+2, self.ATMType.Resolutiony+2 ) 
		surface.SetDrawColor(ARCLib.ConvertColor(self.ATMType.BackgroundColour))
		surface.DrawRect( self.ATMType.Resolutionx/-2, self.ATMType.Resolutiony/-2, self.ATMType.Resolutionx, self.ATMType.Resolutiony ) 
		if self.Menu then
			self:Screen_Options()
		else
			self:Screen_Welcome()
		end
		if self.MsgBox then
			ARCBank_Draw:Window_MsgBox(-125,-40,230,"ATM Popup box preview","Error. Your custom ATM is too awesome.",self.DarkMode,6,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
		end
		if self.SpriteNoZ then
			surface.SetDrawColor( 255, 0, 0, 255 )
			surface.DrawRect(self.TouchScreenX,self.TouchScreenY,1,1) 
		else
			surface.SetDrawColor( 255, 0, 0, 255 )
			surface.DrawLine(self.TouchScreenX,self.ATMType.Resolutiony/-2,self.TouchScreenX,self.ATMType.Resolutiony/2)
			surface.DrawLine(self.ATMType.Resolutionx/-2,self.TouchScreenY,self.ATMType.Resolutionx/2,self.TouchScreenY)
		end
		--surface.DrawRect( self.TouchScreenX, self.TouchScreenY, 5, 5) 
		
	cam.End3D2D()

	if self.SpriteNoZ then
		if self.ATMType.UseCardlight && math.sin((CurTime()+(self:EntIndex()/50))*math.pi*2) > 0 then
			cam.Start3D2D(self:LocalToWorld(self.ATMType.Cardlight), self:LocalToWorldAngles(self.ATMType.CardlightAng), self.ATMType.CardlightSize)
				surface.SetDrawColor(ARCLib.ConvertColor(self.ATMType.CardlightColour))
				--MsgN(self.ATMType.CardlightFill)
				if self.ATMType.CardlightFill then
					surface.DrawRect(0,0,self.ATMType.CardlightHeight,self.ATMType.CardlightWidth)
				else
					surface.DrawOutlinedRect(0,0,self.ATMType.CardlightHeight,self.ATMType.CardlightWidth)
				end
			cam.End3D2D()
		end
		
		if self.BEEP then
			cam.Start3D2D(self:LocalToWorld(self.ATMType.Moneylight), self:LocalToWorldAngles(self.ATMType.MoneylightAng), self.ATMType.MoneylightSize)
				surface.SetDrawColor(ARCLib.ConvertColor(self.ATMType.MoneylightColour))
				if self.ATMType.MoneylightFill then
					surface.DrawRect(0,0,self.ATMType.MoneylightHeight,self.ATMType.MoneylightWidth)
				else
					surface.DrawOutlinedRect(0,0,self.ATMType.MoneylightHeight,self.ATMType.MoneylightWidth)
				end
			cam.End3D2D()
		end
	else
		cam.Start3D2D(self:LocalToWorld(self.ATMType.Moneylight), self:LocalToWorldAngles(self.ATMType.MoneylightAng), self.ATMType.MoneylightSize)
			surface.SetDrawColor(ARCLib.ConvertColor(self.ATMType.MoneylightColour))
			if self.ATMType.MoneylightFill then
				surface.DrawRect(0,0,self.ATMType.MoneylightHeight,self.ATMType.MoneylightWidth)
			else
				surface.DrawOutlinedRect(0,0,self.ATMType.MoneylightHeight,self.ATMType.MoneylightWidth)
			end
		cam.End3D2D()
		cam.Start3D2D(self:LocalToWorld(self.ATMType.Cardlight), self:LocalToWorldAngles(self.ATMType.CardlightAng), self.ATMType.CardlightSize)
			surface.SetDrawColor(ARCLib.ConvertColor(self.ATMType.CardlightColour))
			--MsgN(self.ATMType.CardlightFill)
			if self.ATMType.CardlightFill then
				surface.DrawRect(0,0,self.ATMType.CardlightHeight,self.ATMType.CardlightWidth)
			else
				surface.DrawOutlinedRect(0,0,self.ATMType.CardlightHeight,self.ATMType.CardlightWidth)
			end
		cam.End3D2D()
	end
	--if self.BEEP then
	--end
	--render.DrawSprite( self:NearestPoint( LocalPlayer():GetPos() ), 100, 100, Color( 255, 255, 255, 255 ) )
	------KEYPAD------
	--1  2  3   10(ENTER)
	--4  5  6   11(BACKSPACE)
	--7  8  9   12(CANCEL)
	--21 0  22  23(BLANK)
	
	--SCREEN--
	--14  13--
	--16  15--
	--18  17--
	--20  19--
	
	
	if self.ATMType.UseTouchScreen then
		render.SetMaterial(self.spriteMaterialNoZ)
		self.TourchScreenPos[1] = self.ATMType.Screen+Vector(0,(self.ATMType.Resolutionx/2)*self.ATMType.ScreenSize,(self.ATMType.Resolutiony/2)*-self.ATMType.ScreenSize)
		self.TourchScreenPos[2] = self.ATMType.Screen+Vector(0,(self.ATMType.Resolutionx/2)*-self.ATMType.ScreenSize,(self.ATMType.Resolutiony/2)*self.ATMType.ScreenSize)
		local hit,dir,frac = util.IntersectRayWithOBB(LocalPlayer():GetShootPos(),LocalPlayer():GetAimVector()*100, self:LocalToWorld(self.ATMType.Screen), self:LocalToWorldAngles(self.ATMType.ScreenAng), Vector((self.ATMType.Resolutionx/2)*-self.ATMType.ScreenSize,(self.ATMType.Resolutiony/2)*-self.ATMType.ScreenSize,-0.00001),Vector((self.ATMType.Resolutionx/2)*self.ATMType.ScreenSize,(self.ATMType.Resolutiony/2)*self.ATMType.ScreenSize,0.00001)) 
		if hit then
			local adjhit = self:WorldToLocal(hit)-self.ATMType.Screen
			self.TouchScreenX =  adjhit.y/self.ATMType.ScreenSize
			self.TouchScreenY = adjhit.z/-self.ATMType.ScreenSize
			--LocalPlayer():ChatPrint()
		end
		render.DrawSprite(self.TourchScreenPos[1], 2, 2, Color(255,255,0,255))
		render.DrawSprite(self.TourchScreenPos[2], 2, 2, Color(255,255,0,255))
		

		if !self.SpriteNoZ then
			render.DrawWireframeBox(self:LocalToWorld(self.ATMType.MoneyHitBoxPos), self:LocalToWorldAngles(self.ATMType.MoneyHitBoxAng), vector_origin, self.ATMType.MoneyHitBoxSize, Color(0,0,255,255), true ) 
		end
	else
		self.buttonpos={}
		
		self.buttonpos[1] = self:LocalToWorld(self.ATMType.buttons[1])
		self.buttonpos[2] = self:LocalToWorld(self.ATMType.buttons[2])
		self.buttonpos[3] = self:LocalToWorld(self.ATMType.buttons[3])
		self.buttonpos[12] = self:LocalToWorld(self.ATMType.buttons[12])
		self.buttonpos[4] = self:LocalToWorld(self.ATMType.buttons[4])
		self.buttonpos[5] = self:LocalToWorld(self.ATMType.buttons[5])
		self.buttonpos[6] = self:LocalToWorld(self.ATMType.buttons[6])
		self.buttonpos[11] = self:LocalToWorld(self.ATMType.buttons[11])
		self.buttonpos[7] = self:LocalToWorld(self.ATMType.buttons[7])
		self.buttonpos[8] = self:LocalToWorld(self.ATMType.buttons[8])
		self.buttonpos[9] = self:LocalToWorld(self.ATMType.buttons[9])
		self.buttonpos[23] = self:LocalToWorld(self.ATMType.buttons[23])
		
		self.buttonpos[21] = self:LocalToWorld(self.ATMType.buttons[21])
		self.buttonpos[0] = self:LocalToWorld(self.ATMType.buttons[0])
		self.buttonpos[22] = self:LocalToWorld(self.ATMType.buttons[22])
		self.buttonpos[10] = self:LocalToWorld(self.ATMType.buttons[10])
		
		self.buttonpos[13] = self:LocalToWorld(self.ATMType.buttons[13])
		self.buttonpos[14] = self:LocalToWorld(self.ATMType.buttons[14])
		self.buttonpos[15] = self:LocalToWorld(self.ATMType.buttons[15])
		self.buttonpos[16] = self:LocalToWorld(self.ATMType.buttons[16])
		self.buttonpos[17] = self:LocalToWorld(self.ATMType.buttons[17])
		self.buttonpos[18] = self:LocalToWorld(self.ATMType.buttons[18])
		self.buttonpos[19] = self:LocalToWorld(self.ATMType.buttons[19])
		self.buttonpos[20] = self:LocalToWorld(self.ATMType.buttons[20])

		self.Dist = math.huge
		self.Highlightbutton = -1
		self.CurPos = LocalPlayer():GetEyeTrace().HitPos
		if self.SpriteNoZ then
			render.SetMaterial(self.spriteMaterialNoZ)
		else
			render.DrawWireframeBox(self:LocalToWorld(self.ATMType.MoneyHitBoxPos), self:LocalToWorldAngles(self.ATMType.MoneyHitBoxAng), vector_origin, self.ATMType.MoneyHitBoxSize, Color(0,0,255,255), true ) 
			render.SetMaterial(self.spriteMaterialNoZ)
			render.DrawSprite(self.CurPos, 6.5, 6.5, Color(255,255,255,200))
			render.SetMaterial(self.spriteMaterial)
		end

		for i=0,23 do
			if self.buttonpos[i] then
					if self.buttonpos[i]:IsEqualTol(self.CurPos,1.6) then
						if self.buttonpos[i]:DistToSqr(self.CurPos) < self.Dist then
							self.Dist = self.buttonpos[i]:DistToSqr(self.CurPos)
							self.Highlightbutton = i
						end
					else
						if !self.SpriteNoZ then
							if self.SelectedButton == i then
								render.DrawSprite(self.buttonpos[i], 6.5, 6.5, Color(255,255,0,255))
							else
								render.DrawSprite(self.buttonpos[i], 6.5, 6.5, Color(255,0,0,255))
							end
						end
					end
			end
		end
		if self.Highlightbutton >= 0 then
			if self.SpriteNoZ then
				render.DrawSprite(self.buttonpos[self.Highlightbutton], 6.5, 6.5, Color(255,255,255,200))
			else
				render.DrawSprite(self.buttonpos[self.Highlightbutton], 6.5, 6.5, Color(0,255,0,255))
				
			end
		end
	end
end
