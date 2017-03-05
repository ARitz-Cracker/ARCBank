-- ATM Creator ARitz Cracker Bank (Clientside)
-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016-2017 Aritz Beobide-Cardinal All rights reserved.
if ARCBank then
	surface.CreateFont( "ARCBankATMCreator", {
		font = "Arial",
		size = 40,
		weight = 10,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = true
	} )
	surface.CreateFont( "ARCBankATMCreatorSmall", {
		font = "Arial",
		size = 20,
		weight = 10,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = true
	} )
	surface.CreateFont( "ARCBankATMCreatorSSmall", {
		font = "Arial",
		size = 16,
		weight = 10,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = true
	} )
	local ATMThing = NULL
	net.Receive("ARCBank ATM CreatorUse",function(length)
		ARCBank.OpenATMCreatorGUI(net.ReadEntity())
	end)
	net.Receive( "ARCBank ATM Creator", function(length)
		ATMThing = net.ReadEntity()
		ATMThing.ATMType = util.JSONToTable(net.ReadString())
	end)

	local MainPanel	
	local CurrentColour = 1
	function ARCBank.OpenATMCreatorGUI(ent)
		if ent == ATMThing then

			MainPanel = vgui.Create( "DFrame" )
			MainPanel:SetPos( 0, ScrH()-430 )
			MainPanel:SetSize( 390, 430 )
			MainPanel:SetTitle( ARCBank.Msgs.ATMCreator.Name.." - "..ATMThing.ATMType.Name )
			MainPanel:SetVisible( true )
			MainPanel:SetDraggable( true )
			MainPanel:ShowCloseButton( true )
			MainPanel:MakePopup()
			local PropertySheet = vgui.Create( "DPropertySheet", MainPanel )
			PropertySheet:SetPos( 5, 30 )
			PropertySheet:SetSize( 380, 370 )
			local SaveButton = vgui.Create( "DButton",MainPanel)
			SaveButton:SetPos( 5, 405 )
			SaveButton:SetText( ARCBank.Msgs.ATMCreator.SaveTitle )
			SaveButton:SetSize( 380, 20 )
			SaveButton.DoClick = function()
				Derma_StringRequest( ARCBank.Msgs.ATMCreator.Name, ARCBank.Msgs.ATMCreator.SaveAs, ATMThing.ATMType.Name, function(txt)
					ATMThing.ATMType.Name = txt
					net.Start("ARCBank ATM Creator")
					net.WriteString(util.TableToJSON(ATMThing.ATMType))
					net.SendToServer()
				end, nil, ARCBank.Msgs.ATMCreator.Save, ARCBank.Msgs.ATMCreator.NoSave ) 

			end
			
			local AddRemoveSounds = function(value)
				assert(isstring(value),"I needu string got "..type(value).."urru")

				local SettingsContainer = vgui.Create( "DFrame" )
				SettingsContainer:SetPos( ScrW()/2 - 265/2, ScrH()/2 - 20/2 )
				SettingsContainer:SetSize( 275, 155)
				SettingsContainer:SetTitle( value )
				SettingsContainer:SetVisible( true )
				SettingsContainer:SetDraggable( true )
				SettingsContainer:ShowCloseButton( true )
				SettingsContainer:MakePopup()
				local SettingDesc = vgui.Create( "DLabel", SettingsContainer )
				SettingDesc:SetPos( 12, 30 ) -- Set the position of the label
				if string.EndsWith(value,"Sound") then
					
					SettingDesc:SetText( ARCLib.PlaceholderReplace(ARCBank.Msgs.ATMCreator.SoundExplination,{SOUNDNAME=value}))
				else
					SettingDesc:SetText( ARCBank.Msgs.ATMCreator.HackedExplination )
				end
				SettingDesc:SetWrap(true)
				SettingDesc:SetSize( 255, 66 )
				local SettingsTabContainer = vgui.Create( "DPanel",SettingsContainer)
				SettingsTabContainer:SetPos(5,100)
				SettingsTabContainer:SetSize( 265, 50 )
				local SettingTab = vgui.Create( "DComboBox", SettingsTabContainer )
				SettingTab:SetPos( 0,0 )
				SettingTab:SetSize( 210, 20 )
				function SettingTab:OnSelect(index,val,data)
					SettingTab.Selection = val
				end
				
				SettingTab:Clear()
				SettingTab.Selection = ""
				for k,v in pairs(ATMThing.ATMType[value]) do
					SettingTab:AddChoice(v)
				end
				
				local SettingTaba = vgui.Create( "DTextEntry", SettingsTabContainer )
				SettingTaba:SetPos( 0,30 )
				SettingTaba:SetTall( 20 )
				SettingTaba:SetWide( 210 )
				--SettingTaba:SetVisible(false)
				SettingTaba:SetEnterAllowed( true )
				
				local SettingRemove = vgui.Create( "DButton", SettingsTabContainer )
				SettingRemove:SetText( ARCBank.Msgs.AdminMenu.Remove )
				SettingRemove:SetPos( 210, 0 )
				SettingRemove:SetSize( 55, 20 )
				local SettingAdd = vgui.Create( "DButton", SettingsTabContainer )
				SettingAdd:SetText( ARCBank.Msgs.AdminMenu.Add )
				SettingAdd:SetPos( 210, 30)
				SettingAdd:SetSize( 55, 20 )
				SettingAdd.DoClick = function()
					table.insert( ATMThing.ATMType[value], SettingTaba:GetValue() )
					SettingTab:AddChoice(SettingTaba:GetValue())
					SettingTaba:SetValue("")
				end	
				SettingRemove.DoClick = function()
					table.RemoveByValue( ATMThing.ATMType[value], SettingTab.Selection )
					SettingTab:Clear()
					for k,v in pairs(ATMThing.ATMType[value]) do
						SettingTab:AddChoice(v)
					end
				end
			end
			local ScreenPlacement = vgui.Create( "DPanel")
			local ScrSliderXD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderXD:SetText( ARCBank.Msgs.ATMCreator.PositionX )
			ScrSliderXD:SetPos( 10, 20 )
			ScrSliderXD:SizeToContents()
			ScrSliderXD:SetDark(true)
			local ScrSliderX = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderX:SetPos( 100, 10 )
			ScrSliderX:SetWide( 260 )
			ScrSliderX:SetMin(-100)
			ScrSliderX:SetMax(100)
			ScrSliderX:SetDecimals(3)
			ScrSliderX:SetValue(ATMThing.ATMType.Screen.x)
			function ScrSliderX:OnValueChanged( value )
				ATMThing.ATMType.Screen.x = value
			end
			local ScrSliderYD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderYD:SetText( ARCBank.Msgs.ATMCreator.PositionY )
			ScrSliderYD:SetPos( 10, 40 )
			ScrSliderYD:SizeToContents()
			ScrSliderYD:SetDark(true)
			local ScrSliderY = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderY:SetPos( 100, 30 )
			ScrSliderY:SetWide( 260 )
			ScrSliderY:SetMin(-100)
			ScrSliderY:SetMax(100)
			ScrSliderY:SetDecimals(3)
			ScrSliderY:SetValue(ATMThing.ATMType.Screen.y)
			function ScrSliderY:OnValueChanged( value )
				ATMThing.ATMType.Screen.y = value
			end
			local ScrSliderZD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderZD:SetText( ARCBank.Msgs.ATMCreator.PositionZ )
			ScrSliderZD:SetPos( 10, 60 )
			ScrSliderZD:SizeToContents()
			ScrSliderZD:SetDark(true)
			local ScrSliderZ = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderZ:SetPos( 100, 50 )
			ScrSliderZ:SetWide( 260 )
			ScrSliderZ:SetMin(-100)
			ScrSliderZ:SetMax(100)
			ScrSliderZ:SetDecimals(3)
			ScrSliderZ:SetValue(ATMThing.ATMType.Screen.z)
			function ScrSliderZ:OnValueChanged( value )
				ATMThing.ATMType.Screen.z = value
			end
			local ScrSliderSD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderSD:SetText( ARCBank.Msgs.ATMCreator.ScreenSize2 )
			ScrSliderSD:SetPos( 10, 80 )
			ScrSliderSD:SizeToContents()
			ScrSliderSD:SetDark(true)
			local ScrSliderS = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderS:SetPos( 100, 70 )
			ScrSliderS:SetWide( 260 )
			ScrSliderS:SetMin(0)
			ScrSliderS:SetMax(0.25)
			ScrSliderS:SetDecimals(5)
			ScrSliderS:SetValue(ATMThing.ATMType.ScreenSize)
			function ScrSliderS:OnValueChanged( value )
				ATMThing.ATMType.ScreenSize = value
			end
			
			local ScrSliderPD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderPD:SetText( ARCBank.Msgs.ATMCreator.AngleP )
			ScrSliderPD:SetPos( 10, 100 )
			ScrSliderPD:SizeToContents()
			ScrSliderPD:SetDark(true)
			local ScrSliderP = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderP:SetPos( 100, 90 )
			ScrSliderP:SetWide( 260 )
			ScrSliderP:SetMin(0)
			ScrSliderP:SetMax(360)
			ScrSliderP:SetDecimals(3)
			ScrSliderP:SetValue(ATMThing.ATMType.ScreenAng.p)
			function ScrSliderP:OnValueChanged( value )
				ATMThing.ATMType.ScreenAng.p = value
			end
			local ScrSliderYaD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderYaD:SetText( ARCBank.Msgs.ATMCreator.AngleY )
			ScrSliderYaD:SetPos( 10, 120)
			ScrSliderYaD:SizeToContents()
			ScrSliderYaD:SetDark(true)
			local ScrSliderYa = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderYa:SetPos( 100, 110 )
			ScrSliderYa:SetWide( 260 )
			ScrSliderYa:SetMin(0)
			ScrSliderYa:SetMax(360)
			ScrSliderYa:SetDecimals(3)
			ScrSliderYa:SetValue(ATMThing.ATMType.ScreenAng.y)
			function ScrSliderYa:OnValueChanged(value )
				ATMThing.ATMType.ScreenAng.y = value
			end
			local ScrSliderRD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderRD:SetText( ARCBank.Msgs.ATMCreator.AngleR )
			ScrSliderRD:SetPos( 10, 140 )
			ScrSliderRD:SizeToContents()
			ScrSliderRD:SetDark(true)
			local ScrSliderR = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderR:SetPos( 100, 130 )
			ScrSliderR:SetWide( 260 )
			ScrSliderR:SetMin(0)
			ScrSliderR:SetMax(360)
			ScrSliderR:SetDecimals(3)
			ScrSliderR:SetValue(ATMThing.ATMType.ScreenAng.z)
			function ScrSliderR:OnValueChanged(value )
				ATMThing.ATMType.ScreenAng.r = value
			end
			
			local ScrSliderWD = vgui.Create( "DLabel", ScreenPlacement )
			ScrSliderWD:SetText( ARCBank.Msgs.ATMCreator.ScreenWidth )
			ScrSliderWD:SetPos( 10, 160 )
			ScrSliderWD:SizeToContents()
			ScrSliderWD:SetDark(true)
			local ScrSliderW = vgui.Create( "Slider", ScreenPlacement )
			ScrSliderW:SetPos( 100, 150 )
			ScrSliderW:SetWide( 260 )
			ScrSliderW:SetMin(278)
			ScrSliderW:SetMax(1000)
			ScrSliderW:SetDecimals(0)
			ScrSliderW:SetValue(ATMThing.ATMType.Resolutionx)
			function ScrSliderW:OnValueChanged(value )
				ATMThing.ATMType.Resolutionx = value
			end
			
			local PlaceFull = vgui.Create( "DButton", ScreenPlacement )
			PlaceFull:SetText( ARCBank.Msgs.ATMCreator.Fullscreen )
			PlaceFull:SetPos( 20, 190 )
			PlaceFull:SetSize( 320, 20 )
			PlaceFull.DoClick = function()
				ATMThing.ATMType.FullScreen = ATMThing:WorldToLocal(LocalPlayer():EyePos())
				ATMThing.ATMType.FullScreenAng = ATMThing:WorldToLocalAngles(LocalPlayer():EyeAngles())
			end

			
			local ScreenColour = vgui.Create( "DPanel")
			
			local ScreenColourMixerContain = vgui.Create( "DPanel",ScreenColour)
			ScreenColourMixerContain:SetPos( 10, 40 )
			ScreenColourMixerContain:SetSize( 257, 160 )
			local Mixer = vgui.Create( "DColorMixer", ScreenColourMixerContain )
			Mixer:Dock( FILL )
			function Mixer:ValueChanged(value)
				if CurrentColour == 1 then
					ATMThing.ATMType.BackgroundColour = value
				elseif CurrentColour == 2 then
					ATMThing.ATMType.ForegroundColour = value
				end
			end
			
			local AList2 = vgui.Create( "DComboBox", ScreenColour)
			AList2:SetPos(10,10)
			AList2:SetSize( 257, 20 )
			if CurrentColour == 1 then
				AList2:SetText( ARCBank.Msgs.ATMCreator.BGColour )
				Mixer:SetColor( ATMThing.ATMType.BackgroundColour )
			elseif CurrentColour == 2 then
				AList2:SetText( ARCBank.Msgs.ATMCreator.FGColour )
				Mixer:SetColor( ATMThing.ATMType.ForegroundColour )
			end
			
			local DModeCheck = vgui.Create( "DCheckBoxLabel", ScreenColour )
			DModeCheck:SetPos( 270, 12 )
			DModeCheck:SetText( ARCBank.Msgs.ATMCreator.DarkMode )
			DModeCheck:SizeToContents()
			DModeCheck:SetDark( 1 )
			DModeCheck:SetValue( ARCLib.BoolToNumber(ATMThing.DarkMode) )
			function DModeCheck:OnChange( val )
				ATMThing.DarkMode = val
			end
			
			local MenuCheck = vgui.Create( "DCheckBoxLabel", ScreenColour )
			MenuCheck:SetPos( 270, 34 )
			MenuCheck:SetText( ARCBank.Msgs.ATMCreator.ShowMenu )
			MenuCheck:SizeToContents()
			MenuCheck:SetDark( 1 )
			MenuCheck:SetValue( ARCLib.BoolToNumber(ATMThing.Menu) )
			function MenuCheck:OnChange( val )
				ATMThing.Menu = val
			end
			
			local DModeCheck = vgui.Create( "DCheckBoxLabel", ScreenColour )
			DModeCheck:SetPos( 270, 56 )
			DModeCheck:SetText( ARCBank.Msgs.ATMCreator.MessageBox )
			DModeCheck:SizeToContents()
			DModeCheck:SetDark( 1 )
			DModeCheck:SetValue( ARCLib.BoolToNumber(ATMThing.MsgBox) )
			function DModeCheck:OnChange( val )
				ATMThing.MsgBox = val
			end
			local DModeCheck = vgui.Create( "DCheckBoxLabel", ScreenColour )
			DModeCheck:SetPos( 270, 78 )
			DModeCheck:SetText( ARCBank.Msgs.ATMCreator.Hacked )
			DModeCheck:SizeToContents()
			DModeCheck:SetDark( 1 )
			DModeCheck:SetValue( ARCLib.BoolToNumber(ATMThing.Hacked) )
			function DModeCheck:OnChange( val )
				ATMThing.Hacked = val
			end
			
			AList2:AddChoice(ARCBank.Msgs.ATMCreator.BGColour)
			AList2:AddChoice(ARCBank.Msgs.ATMCreator.FGColour)
			function AList2:OnSelect(index,value,data)
				CurrentColour = index
				if CurrentColour == 1 then
					Mixer:SetColor( ATMThing.ATMType.BackgroundColour )
				elseif CurrentColour == 2 then
					Mixer:SetColor( ATMThing.ATMType.ForegroundColour )
				end
			end
			local WelcomeTextureD = vgui.Create( "DLabel", ScreenColour )
			WelcomeTextureD:SetText( ARCBank.Msgs.ATMCreator.WelScrMat )
			WelcomeTextureD:SetPos( 10, 204 )
			WelcomeTextureD:SizeToContents()
			WelcomeTextureD:SetDark(true)
			local WelcomeTexture = vgui.Create( "DTextEntry", ScreenColour )	-- create the form as a child of frame
			WelcomeTexture:SetPos( 10, 220 )
			WelcomeTexture:SetSize( 257, 20 )
			WelcomeTexture:SetText( ATMThing.ATMType.WelcomeScreen )
			function WelcomeTexture:OnEnter()
				ATMThing.ATMType.WelcomeScreen = self:GetValue()
			end
			
			local DepositStartSound = vgui.Create( "DButton",ScreenColour)
			DepositStartSound:SetPos( 10, 250 )
			DepositStartSound:SetText( ARCBank.Msgs.ATMCreator.HckWelScr )
			DepositStartSound:SetSize( 257, 20 )
			DepositStartSound.DoClick = function()
				AddRemoveSounds("HackedWelcomeScreen")
			end
			
			local ButtonsPlacement = vgui.Create( "DPanel")
			
			local TouchScreenList= vgui.Create( "DComboBox", ButtonsPlacement)
			TouchScreenList:SetPos(10,10)
			TouchScreenList:SetSize( 230, 20 )
			if ATMThing.ATMType.UseTouchScreen then
				TouchScreenList:SetText( ARCBank.Msgs.ATMCreator.IntrTouch )
			else
				TouchScreenList:SetText( ARCBank.Msgs.ATMCreator.IntrButt )
			end
			TouchScreenList:AddChoice(ARCBank.Msgs.ATMCreator.IntrButt)
			TouchScreenList:AddChoice(ARCBank.Msgs.ATMCreator.IntrTouch)
			
			function TouchScreenList:OnSelect(index,value,data)
				ATMThing.ATMType.UseTouchScreen = index == 2
			end
			local ButtonList= vgui.Create( "DComboBox", ButtonsPlacement)
			ButtonList:SetPos(10,40)
			ButtonList:SetSize( 340, 20 )
			
			for i = 0,23 do
				ButtonList:AddChoice(ARCLib.PlaceholderReplace(ARCBank.Msgs.ATMCreator.Butt,{NUM=tostring(i)}))
			end
			ButtonList:AddChoice(ARCBank.Msgs.ATMCreator.MonHit)
			
			local HitBoxPD = vgui.Create( "DLabel", ButtonsPlacement )
			HitBoxPD:SetText( ARCBank.Msgs.ATMCreator.AngleP )
			HitBoxPD:SetPos( 10, 190 )
			HitBoxPD:SizeToContents()
			HitBoxPD:SetDark(true)
			local HitBoxP = vgui.Create( "Slider", ButtonsPlacement )
			HitBoxP:SetPos( 100, 180 )
			HitBoxP:SetWide( 260 )
			HitBoxP:SetMin(0)
			HitBoxP:SetMax(360)
			HitBoxP:SetDecimals(3)
			HitBoxP:SetValue(ATMThing.ATMType.MoneyHitBoxAng.p)
			function HitBoxP:OnValueChanged( value )
				ATMThing.ATMType.MoneyHitBoxAng.p = value
			end
			local HitBoxYaD = vgui.Create( "DLabel", ButtonsPlacement )
			HitBoxYaD:SetText( ARCBank.Msgs.ATMCreator.AngleY )
			HitBoxYaD:SetPos( 10, 210 )
			HitBoxYaD:SizeToContents()
			HitBoxYaD:SetDark(true)
			local HitBoxYa = vgui.Create( "Slider", ButtonsPlacement )
			HitBoxYa:SetPos( 100, 200 )
			HitBoxYa:SetWide( 260 )
			HitBoxYa:SetMin(0)
			HitBoxYa:SetMax(360)
			HitBoxYa:SetDecimals(3)
			HitBoxYa:SetValue(ATMThing.ATMType.MoneyHitBoxAng.y)
			function HitBoxYa:OnValueChanged( value )
				ATMThing.ATMType.MoneyHitBoxAng.y = value
			end
			local HitBoxRD = vgui.Create( "DLabel", ButtonsPlacement )
			HitBoxRD:SetText( ARCBank.Msgs.ATMCreator.AngleR )
			HitBoxRD:SetPos( 10, 230 )
			HitBoxRD:SizeToContents()
			HitBoxRD:SetDark(true)
			local HitBoxR = vgui.Create( "Slider", ButtonsPlacement )
			HitBoxR:SetPos( 100, 220 )
			HitBoxR:SetWide( 260 )
			HitBoxR:SetMin(0)
			HitBoxR:SetMax(360)
			HitBoxR:SetDecimals(3)
			HitBoxR:SetValue(ATMThing.ATMType.MoneyHitBoxAng.r)
			function HitBoxR:OnValueChanged( value )
				ATMThing.ATMType.MoneyHitBoxAng.r = value
			end
			
			local HitBoxXD = vgui.Create( "DLabel", ButtonsPlacement )
			HitBoxXD:SetText( ARCBank.Msgs.ATMCreator.MonL )
			HitBoxXD:SetPos( 10, 250 )
			HitBoxXD:SizeToContents()
			HitBoxXD:SetDark(true)
			local HitBoxX = vgui.Create( "Slider", ButtonsPlacement )
			HitBoxX:SetPos( 100, 240 )
			HitBoxX:SetWide( 260 )
			HitBoxX:SetMin(-20)
			HitBoxX:SetMax(20)
			HitBoxX:SetDecimals(3)
			HitBoxX:SetValue(ATMThing.ATMType.MoneyHitBoxSize.x)
			function HitBoxX:OnValueChanged( value )
				ATMThing.ATMType.MoneyHitBoxSize.x = value
			end
			local HitBoxYD = vgui.Create( "DLabel", ButtonsPlacement )
			HitBoxYD:SetText( ARCBank.Msgs.ATMCreator.MonW )
			HitBoxYD:SetPos( 10, 270 )
			HitBoxYD:SizeToContents()
			HitBoxYD:SetDark(true)
			local HitBoxY = vgui.Create( "Slider", ButtonsPlacement )
			HitBoxY:SetPos( 100, 260 )
			HitBoxY:SetWide( 260 )
			HitBoxY:SetMin(-20)
			HitBoxY:SetMax(20)
			HitBoxY:SetDecimals(3)
			HitBoxY:SetValue(ATMThing.ATMType.MoneyHitBoxSize.y)
			function HitBoxY:OnValueChanged( value )
				ATMThing.ATMType.MoneyHitBoxSize.y = value
			end
			local HitBoxZD = vgui.Create( "DLabel", ButtonsPlacement )
			HitBoxZD:SetText( ARCBank.Msgs.ATMCreator.MonH )
			HitBoxZD:SetPos( 10, 290 )
			HitBoxZD:SizeToContents()
			HitBoxZD:SetDark(true)
			local HitBoxZ = vgui.Create( "Slider", ButtonsPlacement )
			HitBoxZ:SetPos( 100, 280 )
			HitBoxZ:SetWide( 260 )
			HitBoxZ:SetMin(-20)
			HitBoxZ:SetMax(20)
			HitBoxZ:SetDecimals(3)
			HitBoxZ:SetValue(ATMThing.ATMType.MoneyHitBoxSize.z)
			function HitBoxZ:OnValueChanged( value )
				ATMThing.ATMType.MoneyHitBoxSize.z = value
			end
			
			local IgnrZCheck = vgui.Create( "DCheckBoxLabel", ButtonsPlacement )
			IgnrZCheck:SetPos( 250, 12 )
			IgnrZCheck:SetText( ARCBank.Msgs.ATMCreator.ATMPre )
			IgnrZCheck:SizeToContents()
			IgnrZCheck:SetDark( 1 )
			IgnrZCheck:SetValue( ARCLib.BoolToNumber(ATMThing.SpriteNoZ) )
			function IgnrZCheck:OnChange( val )
				ATMThing.SpriteNoZ = val
			end
			local ButtonSliderXD = vgui.Create( "DLabel", ButtonsPlacement )
			ButtonSliderXD:SetText( ARCBank.Msgs.ATMCreator.PositionX )
			ButtonSliderXD:SetPos( 10, 70 )
			ButtonSliderXD:SizeToContents()
			ButtonSliderXD:SetDark(true)
			local ButtonSliderX = vgui.Create( "Slider", ButtonsPlacement )
			ButtonSliderX:SetPos( 100, 60 )
			ButtonSliderX:SetWide( 260 )
			ButtonSliderX:SetMin(-100)
			ButtonSliderX:SetMax(100)
			ButtonSliderX:SetDecimals(3)

			function ButtonSliderX:OnValueChanged( value )
				if ATMThing.SelectedButton < 24 then
					ATMThing.ATMType.buttons[ATMThing.SelectedButton].x = value
				else
					ATMThing.ATMType.MoneyHitBoxPos.x = value
				end
			end
			local ButtonSliderYD = vgui.Create( "DLabel", ButtonsPlacement )
			ButtonSliderYD:SetText( ARCBank.Msgs.ATMCreator.PositionY )
			ButtonSliderYD:SetPos( 10, 90 )
			ButtonSliderYD:SizeToContents()
			ButtonSliderYD:SetDark(true)
			local ButtonSliderY = vgui.Create( "Slider", ButtonsPlacement )
			ButtonSliderY:SetPos( 100, 80 )
			ButtonSliderY:SetWide( 260 )
			ButtonSliderY:SetMin(-100)
			ButtonSliderY:SetMax(100)
			ButtonSliderY:SetDecimals(3)
			

			function ButtonSliderY:OnValueChanged( value )
				if ATMThing.SelectedButton < 24 then
					ATMThing.ATMType.buttons[ATMThing.SelectedButton].y = value
				else
					ATMThing.ATMType.MoneyHitBoxPos.y = value
				end
			end
			local ButtonSliderZD = vgui.Create( "DLabel", ButtonsPlacement )
			ButtonSliderZD:SetText( ARCBank.Msgs.ATMCreator.PositionZ )
			ButtonSliderZD:SetPos( 10, 110 )
			ButtonSliderZD:SizeToContents()
			ButtonSliderZD:SetDark(true)
			local ButtonSliderZ = vgui.Create( "Slider", ButtonsPlacement )
			ButtonSliderZ:SetPos( 100, 100 )
			ButtonSliderZ:SetWide( 260 )
			ButtonSliderZ:SetMin(-100)
			ButtonSliderZ:SetMax(100)
			ButtonSliderZ:SetDecimals(3)
			
			if ATMThing.SelectedButton < 24 then
				ButtonSliderX:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].x)
				ButtonSliderY:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].y)
				ButtonSliderZ:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].z)
				HitBoxPD:SetVisible(false)
				HitBoxP:SetVisible(false)
				HitBoxYaD:SetVisible(false)
				HitBoxYa:SetVisible(false)
				HitBoxRD:SetVisible(false)
				HitBoxR:SetVisible(false)
				HitBoxXD:SetVisible(false)
				HitBoxX:SetVisible(false)
				HitBoxYD:SetVisible(false)
				HitBoxY:SetVisible(false)
				HitBoxZD:SetVisible(false)
				HitBoxZ:SetVisible(false)
				ButtonList:SetText(ARCLib.PlaceholderReplace(ARCBank.Msgs.ATMCreator.Butt,{NUM=tostring(ATMThing.SelectedButton)}))
			else
				ButtonSliderX:SetValue(ATMThing.ATMType.MoneyHitBoxPos.x)
				ButtonSliderY:SetValue(ATMThing.ATMType.MoneyHitBoxPos.y)
				ButtonSliderZ:SetValue(ATMThing.ATMType.MoneyHitBoxPos.z)
				HitBoxPD:SetVisible(true)
				HitBoxP:SetVisible(true)
				HitBoxYaD:SetVisible(true)
				HitBoxYa:SetVisible(true)
				HitBoxRD:SetVisible(true)
				HitBoxR:SetVisible(true)
				HitBoxXD:SetVisible(true)
				HitBoxX:SetVisible(true)
				HitBoxYD:SetVisible(true)
				HitBoxY:SetVisible(true)
				HitBoxZD:SetVisible(true)
				HitBoxZ:SetVisible(true)
				ButtonList:SetText( ARCBank.Msgs.ATMCreator.MonHit )
			end
			function ButtonSliderZ:OnValueChanged( value )
				if ATMThing.SelectedButton < 24 then
					ATMThing.ATMType.buttons[ATMThing.SelectedButton].z = value
				else
					ATMThing.ATMType.MoneyHitBoxPos.z = value
				end
			end

			function ButtonList:OnSelect(index,value,data)
				ATMThing.SelectedButton = index - 1
				if ATMThing.SelectedButton < 24 then
					ButtonSliderX:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].x)
					ButtonSliderY:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].y)
					ButtonSliderZ:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].z)
					HitBoxPD:SetVisible(false)
					HitBoxP:SetVisible(false)
					HitBoxYaD:SetVisible(false)
					HitBoxYa:SetVisible(false)
					HitBoxRD:SetVisible(false)
					HitBoxR:SetVisible(false)
					HitBoxXD:SetVisible(false)
					HitBoxX:SetVisible(false)
					HitBoxYD:SetVisible(false)
					HitBoxY:SetVisible(false)
					HitBoxZD:SetVisible(false)
					HitBoxZ:SetVisible(false)
				else
					HitBoxPD:SetVisible(true)
					HitBoxP:SetVisible(true)
					HitBoxYaD:SetVisible(true)
					HitBoxYa:SetVisible(true)
					HitBoxRD:SetVisible(true)
					HitBoxR:SetVisible(true)
					HitBoxXD:SetVisible(true)
					HitBoxX:SetVisible(true)
					HitBoxYD:SetVisible(true)
					HitBoxY:SetVisible(true)
					HitBoxZD:SetVisible(true)
					HitBoxZ:SetVisible(true)
				end
			end
			
			local EZPutButton = vgui.Create( "DButton",ButtonsPlacement)
			EZPutButton:SetPos( 10, 130 )
			EZPutButton:SetText( ARCBank.Msgs.ATMCreator.ButtonAim )
			EZPutButton:SetSize( 340, 20 )
			EZPutButton.DoClick = function()
				if ATMThing.SelectedButton < 24 then
					ATMThing.ATMType.buttons[ATMThing.SelectedButton] = ATMThing:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos)
					ButtonSliderX:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].x)
					ButtonSliderY:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].y)
					ButtonSliderZ:SetValue(ATMThing.ATMType.buttons[ATMThing.SelectedButton].z)
				end
			end
			
			local ScrRef = vgui.Create( "DButton",ButtonsPlacement)
			ScrRef:SetPos( 10, 160 )
			ScrRef:SetText( ARCBank.Msgs.ATMCreator.ScreenRef )
			ScrRef:SetSize( 340, 20 )
			ScrRef.DoClick = function()
				local ButtonImgPanel = vgui.Create( "DFrame" )
				ButtonImgPanel:SetPos( ScrW()/2 - 266/2, ScrH()/2 - 547 / 2 )
				ButtonImgPanel:SetSize( 266, 547)
				ButtonImgPanel:SetTitle( ARCBank.Msgs.ATMCreator.ATMButtons )
				ButtonImgPanel:SetVisible( true )
				ButtonImgPanel:SetDraggable( true )
				ButtonImgPanel:ShowCloseButton( true )
				ButtonImgPanel:MakePopup()
				local postprocess = vgui.Create( "DImage", ButtonImgPanel )
				postprocess:SetSize( 256, 512 )
				postprocess:SetPos( 5,30)
				postprocess:SetImage( "materials/arc/atm_creator_reference.png" )
			end
			
			
			
			
			
			local MoneyAnimD = vgui.Create( "DPanel")
			
			
			local EditAnimation = function(value)
				assert(isstring(value),"I needu string got "..type(value).."u")
				if (value == "OpenAnimation" || value == "CloseAnimation") then
					local SettingsContainer = vgui.Create( "DFrame" )
					SettingsContainer:SetPos( ScrW()/2 - 275/2, ScrH()/2 - 155/2 )
					SettingsContainer:SetSize( 275, 155)
					SettingsContainer:SetTitle( value )
					SettingsContainer:SetVisible( true )
					SettingsContainer:SetDraggable( true )
					SettingsContainer:ShowCloseButton( true )
					SettingsContainer:MakePopup()
					local SkinL = vgui.Create( "DLabel", SettingsContainer )
					SkinL:SetPos( 10, 35 ) -- Set the position of the label
					SkinL:SetText( ARCBank.Msgs.ATMCreator.SkinSwitch )
					SkinL:SizeToContents()
					local SkinN = vgui.Create("DNumberWang",SettingsContainer)
					SkinN:SetPos(120, 30)
					SkinN:SetSize(150, 20)
					SkinN:SetMinMax(0, 10)
					if value == "OpenAnimation" then
						SkinN:SetValue(ATMThing.ATMType.OpenSkin)
						SkinN.OnValueChanged = function(self,val)
							ATMThing.ATMType.OpenSkin = val
						end
					else
						SkinN:SetValue(ATMThing.ATMType.CloseSkin)
						SkinN.OnValueChanged = function(self,val)
							ATMThing.ATMType.CloseSkin = val
						end
					end
					--SkinL:SetDark(true)
					local ModelL = vgui.Create( "DLabel", SettingsContainer )
					ModelL:SetPos( 10, 65 ) -- Set the position of the label
					ModelL:SetText( ARCBank.Msgs.ATMCreator.ModelSwitch )
					ModelL:SizeToContents()
				
					local ModelIn = vgui.Create( "DTextEntry", SettingsContainer )	-- create the form as a child of frame
					ModelIn:SetPos( 120, 60 )
					ModelIn:SetSize( 150, 20 )
					if value == "OpenAnimation" then
						ModelIn:SetValue(ATMThing.ATMType.ModelOpen)
						ModelIn.OnEnter = function(self)
							ATMThing.ATMType.ModelOpen = self:GetValue()
						end
					else
						ModelIn:SetValue(ATMThing.ATMType.Model)
						ModelIn.OnEnter = function(self)
							ATMThing.ATMType.Model = self:GetValue()
						end
					end

					--ModelL:SetDark(true)
					local AnimL = vgui.Create( "DLabel", SettingsContainer )
					AnimL:SetPos( 10, 95 ) -- Set the position of the label
					AnimL:SetText( ARCBank.Msgs.ATMCreator.AnimName )
					AnimL:SizeToContents()
					local AnimIn = vgui.Create( "DTextEntry", SettingsContainer )	-- create the form as a child of frame
					AnimIn:SetPos( 120, 90 )
					AnimIn:SetSize( 150, 20 )
					AnimIn:SetValue(ATMThing.ATMType[value])
					AnimIn.OnEnter = function(self)
						ATMThing.ATMType[value] = self:GetValue()
					end
					
					--AnimL:SetDark(true)
					local AnimationLength = vgui.Create( "DLabel", SettingsContainer )
					AnimationLength:SetPos( 10, 125 ) -- Set the position of the label
					AnimationLength:SetText( ARCBank.Msgs.ATMCreator.AnimLen )
					AnimationLength:SizeToContents()
					local AnimationLenIn = vgui.Create("DNumberWang",SettingsContainer)
					AnimationLenIn:SetPos(120, 120)
					AnimationLenIn:SetSize(150, 20)
					AnimationLenIn:SetMinMax(0, 10)
					AnimationLenIn:SetDecimals(3)
					AnimationLenIn:SetValue(ATMThing.ATMType[value.."Length"])
					AnimationLenIn.OnValueChanged = function(self,val)
						ATMThing.ATMType[value.."Length"] = val
					end
				else
					local SettingsContainer = vgui.Create( "DFrame" )
					SettingsContainer:SetPos( ScrW()/2 - 275/2, ScrH()/2 - 340/2 )
					SettingsContainer:SetSize( 275, 340)
					SettingsContainer:SetTitle( value )
					SettingsContainer:SetVisible( true )
					SettingsContainer:SetDraggable( true )
					SettingsContainer:ShowCloseButton( true )
					SettingsContainer:MakePopup()
					
					
					local AnimL = vgui.Create( "DLabel", SettingsContainer )
					AnimL:SetPos( 10, 35 ) -- Set the position of the label
					AnimL:SetText( ARCBank.Msgs.ATMCreator.AnimName )
					AnimL:SizeToContents()
					local AnimIn = vgui.Create( "DTextEntry", SettingsContainer )	-- create the form as a child of frame
					AnimIn:SetPos( 120, 30 )
					AnimIn:SetSize( 150, 20 )
					AnimIn:SetValue(ATMThing.ATMType[value])
					AnimIn.OnEnter = function(self)
						ATMThing.ATMType[value] = self:GetValue()
					end
					
					--AnimL:SetDark(true)
					local AnimationLength = vgui.Create( "DLabel", SettingsContainer )
					AnimationLength:SetPos( 10, 65 ) -- Set the position of the label
					AnimationLength:SetText( ARCBank.Msgs.ATMCreator.AnimLen )
					AnimationLength:SizeToContents()
					local AnimationLenIn = vgui.Create("DNumberWang",SettingsContainer)
					AnimationLenIn:SetPos(120, 60)
					AnimationLenIn:SetSize(150, 20)
					AnimationLenIn:SetMinMax(0, 10)
					AnimationLenIn:SetDecimals(3)
					AnimationLenIn:SetValue(ATMThing.ATMType[value.."Length"])
					AnimationLenIn.OnValueChanged = function(self,val)
						ATMThing.ATMType[value.."Length"] = val
					end
					
					
					local UseModelCheck = vgui.Create( "DCheckBoxLabel", SettingsContainer )
					UseModelCheck:SetPos( 10, 95 )
					UseModelCheck:SetText( ARCBank.Msgs.ATMCreator.UseModel )
					UseModelCheck:SizeToContents()
					--UseModelCheck:SetDark( 1 )
					


					local ModelL = vgui.Create( "DLabel", SettingsContainer )
					ModelL:SetPos( 10, 125 ) -- Set the position of the label
				
					local ModelIn = vgui.Create( "DTextEntry", SettingsContainer )	-- create the form as a child of frame
					ModelIn:SetPos( 120, 120 )
					ModelIn:SetSize( 150, 20 )
					
					
					if value == "DepositAnimation" || value == "WithdrawAnimation" then
						UseModelCheck:SetValue( ARCLib.BoolToNumber(ATMThing.ATMType.UseMoneyModel) )
						function UseModelCheck:OnChange( val )
							ATMThing.ATMType.UseMoneyModel = val
						end
						ModelIn:SetValue(ATMThing.ATMType.MoneyModel)
						ModelIn.OnEnter = function(self)
							ATMThing.ATMType.MoneyModel = self:GetValue()
						end
						ModelL:SetText( ARCBank.Msgs.ATMCreator.MoneyModel )
						ModelL:SizeToContents()
						
					else
						function UseModelCheck:OnChange( val )
							ATMThing.ATMType.UseCardModel = val
						end
						ModelIn:SetValue(ATMThing.ATMType.CardModel)
						ModelIn.OnEnter = function(self)
							ATMThing.ATMType.CardModel = self:GetValue()
						end
						ModelL:SetText( ARCBank.Msgs.ATMCreator.CardModel )
						ModelL:SizeToContents()
					end
					
					
					local ModelAnimXD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimXD:SetText( ARCBank.Msgs.ATMCreator.PositionX )
					ModelAnimXD:SetPos( 10, 150 )
					ModelAnimXD:SizeToContents()
					local ModelAnimX = vgui.Create( "Slider", SettingsContainer )
					ModelAnimX:SetPos( 75, 140 )
					ModelAnimX:SetWide( 200 )
					ModelAnimX:SetMin(-100)
					ModelAnimX:SetMax(100)
					ModelAnimX:SetDecimals(3)
					ModelAnimX:SetValue(ATMThing.ATMType[value.."Pos"].x)
					function ModelAnimX:OnValueChanged( val )
						ATMThing.ATMType[value.."Pos"].x = val
					end
					
					
					local ModelAnimYD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimYD:SetText( ARCBank.Msgs.ATMCreator.PositionY )
					ModelAnimYD:SetPos( 10, 170 )
					ModelAnimYD:SizeToContents()
					local ModelAnimY = vgui.Create( "Slider", SettingsContainer )
					ModelAnimY:SetPos( 75, 160 )
					ModelAnimY:SetWide( 200 )
					ModelAnimY:SetMin(-100)
					ModelAnimY:SetMax(100)
					ModelAnimY:SetDecimals(3)
					ModelAnimY:SetValue(ATMThing.ATMType[value.."Pos"].y)
					function ModelAnimY:OnValueChanged( val )
						ATMThing.ATMType[value.."Pos"].y = val
					end
					
					local ModelAnimZD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimZD:SetText( ARCBank.Msgs.ATMCreator.PositionZ )
					ModelAnimZD:SetPos( 10, 190 )
					ModelAnimZD:SizeToContents()
					local ModelAnimZ = vgui.Create( "Slider", SettingsContainer )
					ModelAnimZ:SetPos( 75, 180 )
					ModelAnimZ:SetWide( 200 )
					ModelAnimZ:SetMin(-100)
					ModelAnimZ:SetMax(100)
					ModelAnimZ:SetDecimals(3)
					ModelAnimZ:SetValue(ATMThing.ATMType[value.."Pos"].z)
					function ModelAnimZ:OnValueChanged( val )
						ATMThing.ATMType[value.."Pos"].z = val
					end
					
					
					

					local ModelAnimPD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimPD:SetText( ARCBank.Msgs.ATMCreator.AngleP )
					ModelAnimPD:SetPos( 10, 210 )
					ModelAnimPD:SizeToContents()
					local ModelAnimP = vgui.Create( "Slider", SettingsContainer )
					ModelAnimP:SetPos( 75, 200 )
					ModelAnimP:SetWide( 200 )
					ModelAnimP:SetMin(0)
					ModelAnimP:SetMax(360)
					ModelAnimP:SetDecimals(3)
					ModelAnimP:SetValue(ATMThing.ATMType[value.."Ang"].p)
					function ModelAnimP:OnValueChanged( val )
						ATMThing.ATMType[value.."Ang"].p = val
					end
					
					
					local ModelAnimYaD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimYaD:SetText( ARCBank.Msgs.ATMCreator.AngleY )
					ModelAnimYaD:SetPos( 10, 230 )
					ModelAnimYaD:SizeToContents()
					local ModelAnimYa = vgui.Create( "Slider", SettingsContainer )
					ModelAnimYa:SetPos( 75, 220 )
					ModelAnimYa:SetWide( 200 )
					ModelAnimYa:SetMin(0)
					ModelAnimYa:SetMax(360)
					ModelAnimYa:SetDecimals(3)
					ModelAnimYa:SetValue(ATMThing.ATMType[value.."Ang"].y)
					function ModelAnimYa:OnValueChanged( val )
						ATMThing.ATMType[value.."Ang"].y = val
					end
					
					local ModelAnimRD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimRD:SetText( ARCBank.Msgs.ATMCreator.AngleR )
					ModelAnimRD:SetPos( 10, 250 )
					ModelAnimRD:SizeToContents()
					local ModelAnimR = vgui.Create( "Slider", SettingsContainer )
					ModelAnimR:SetPos( 75, 240 )
					ModelAnimR:SetWide( 200 )
					ModelAnimR:SetMin(0)
					ModelAnimR:SetMax(360)
					ModelAnimR:SetDecimals(3)
					ModelAnimR:SetValue(ATMThing.ATMType[value.."Ang"].r)
					function ModelAnimR:OnValueChanged( val )
						ATMThing.ATMType[value.."Ang"].r = val
					end
					
					
					local ModelAnimVXD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimVXD:SetText( ARCBank.Msgs.ATMCreator.SpeedF )
					ModelAnimVXD:SetPos( 10, 270 )
					ModelAnimVXD:SizeToContents()
					local ModelAnimVX = vgui.Create( "Slider", SettingsContainer )
					ModelAnimVX:SetPos( 75, 260 )
					ModelAnimVX:SetWide( 200 )
					ModelAnimVX:SetMin(-50)
					ModelAnimVX:SetMax(50)
					ModelAnimVX:SetDecimals(3)
					ModelAnimVX:SetValue(ATMThing.ATMType[value.."Speed"].x)
					function ModelAnimVX:OnValueChanged( val )
						ATMThing.ATMType[value.."Speed"].x = val
					end
					
					
					local ModelAnimVYD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimVYD:SetText( ARCBank.Msgs.ATMCreator.SpeedR )
					ModelAnimVYD:SetPos( 10, 290 )
					ModelAnimVYD:SizeToContents()
					local ModelAnimVY = vgui.Create( "Slider", SettingsContainer )
					ModelAnimVY:SetPos( 75, 280 )
					ModelAnimVY:SetWide( 200 )
					ModelAnimVY:SetMin(-50)
					ModelAnimVY:SetMax(50)
					ModelAnimVY:SetDecimals(3)
					ModelAnimVY:SetValue(ATMThing.ATMType[value.."Speed"].y)
					function ModelAnimVY:OnValueChanged( val )
						ATMThing.ATMType[value.."Speed"].y = val
					end
					
					local ModelAnimVZD = vgui.Create( "DLabel", SettingsContainer )
					ModelAnimVZD:SetText( ARCBank.Msgs.ATMCreator.SpeedU )
					ModelAnimVZD:SetPos( 10, 310 )
					ModelAnimVZD:SizeToContents()
					local ModelAnimVZ = vgui.Create( "Slider", SettingsContainer )
					ModelAnimVZ:SetPos( 75, 300 )
					ModelAnimVZ:SetWide( 200 )
					ModelAnimVZ:SetMin(-50)
					ModelAnimVZ:SetMax(50)
					ModelAnimVZ:SetDecimals(3)
					ModelAnimVZ:SetValue(ATMThing.ATMType[value.."Speed"].z)
					function ModelAnimVZ:OnValueChanged( val )
						ATMThing.ATMType[value.."Speed"].z = val
					end
					
				end
			end
			
			local DepositStartSound = vgui.Create( "DButton",MoneyAnimD)
			DepositStartSound:SetPos( 10, 10 )
			DepositStartSound:SetText( ARCBank.Msgs.ATMCreator.DepostStartSound )
			DepositStartSound:SetSize( 340, 20 )
			DepositStartSound.DoClick = function()
				AddRemoveSounds("DepositStartSound")
			end
			
			local Pause1L = vgui.Create( "DLabel", MoneyAnimD )
			Pause1L:SetPos( 10, 44 ) -- Set the position of the label
			Pause1L:SetText( ARCBank.Msgs.ATMCreator.PauseSeconds )
			Pause1L:SizeToContents()
			Pause1L:SetDark(true)
			local Pause1 = vgui.Create("DNumberWang",MoneyAnimD)
			Pause1:SetPos(280, 40)
			Pause1:SetSize(70, 20)
			Pause1:SetMinMax(0, 10)
			Pause1:SetDecimals(2)
			Pause1:SetValue(ATMThing.ATMType.PauseBeforeDepositAnimation)
			Pause1.OnValueChanged = function(self,value)
				ATMThing.ATMType.PauseBeforeDepositAnimation = value
			end
			
			local DepositOpenAnimation = vgui.Create( "DButton",MoneyAnimD)
			DepositOpenAnimation:SetPos( 10, 70 )
			DepositOpenAnimation:SetText( ARCBank.Msgs.ATMCreator.ATMOpenAnim )
			DepositOpenAnimation:SetSize( 340, 20 )
			DepositOpenAnimation.DoClick = function()
				EditAnimation("OpenAnimation")
			end
			
			local Pause2L = vgui.Create( "DLabel", MoneyAnimD )
			Pause2L:SetPos( 10, 104 ) -- Set the position of the label
			Pause2L:SetText( ARCBank.Msgs.ATMCreator.PauseSeconds )
			Pause2L:SizeToContents()
			Pause2L:SetDark(true)
			local Pause2 = vgui.Create("DNumberWang",MoneyAnimD)
			Pause2:SetPos(280, 100)
			Pause2:SetSize(70, 20)
			Pause2:SetMinMax(0, 10)
			Pause2:SetDecimals(2)
			Pause2:SetValue(ATMThing.ATMType.PauseBeforeDepositSoundLoop)
			Pause2.OnValueChanged = function(self,value)
				ATMThing.ATMType.PauseBeforeDepositSoundLoop = value
			end
			
			local DepositStartSound = vgui.Create( "DButton",MoneyAnimD)
			DepositStartSound:SetPos( 10, 130 )
			DepositStartSound:SetText( ARCBank.Msgs.ATMCreator.DepositSoundLoop )
			DepositStartSound:SetSize( 340, 20 )
			DepositStartSound.DoClick = function()
				AddRemoveSounds("DepositLoopSound")
			end


			
			local FailL = vgui.Create( "DLabel", MoneyAnimD )
			FailL:SetPos( 185, 164 ) -- Set the position of the label
			FailL:SetText( ARCBank.Msgs.ATMCreator.IfDepostFail )
			FailL:SizeToContents()
			FailL:SetDark(true)
			local DepositSoundFail = vgui.Create( "DButton",MoneyAnimD)
			DepositSoundFail:SetPos( 185, 190 )
			DepositSoundFail:SetText( ARCBank.Msgs.ATMCreator.DepositFailedSound )
			DepositSoundFail:SetSize( 165, 20 )
			DepositSoundFail.DoClick = function()
				AddRemoveSounds("DepositFailSound")
			end
			local Pause3FL = vgui.Create( "DLabel", MoneyAnimD )
			Pause3FL:SetPos( 185, 224 ) -- Set the position of the label
			Pause3FL:SetText( ARCBank.Msgs.ATMCreator.PauseSecondsShort )
			Pause3FL:SizeToContents()
			Pause3FL:SetDark(true)
			local Pause3F = vgui.Create("DNumberWang",MoneyAnimD)
			Pause3F:SetPos(270, 220)
			Pause3F:SetSize(70, 20)
			Pause3F:SetMinMax(0, 10)
			Pause3F:SetDecimals(2)
			Pause3F:SetValue(ATMThing.ATMType.PauseAfterDepositAnimationFail)
			Pause3F.OnValueChanged = function(self,value)
				ATMThing.ATMType.PauseAfterDepositAnimationFail = value
			end
			
			
			local SuccL = vgui.Create( "DLabel", MoneyAnimD )
			SuccL:SetPos( 10, 164 ) -- Set the position of the label
			SuccL:SetText( ARCBank.Msgs.ATMCreator.IfDepostSucceeds )
			SuccL:SizeToContents()
			SuccL:SetDark(true)
			local DepositSound = vgui.Create( "DButton",MoneyAnimD)
			DepositSound:SetPos( 10, 190 )
			DepositSound:SetText( ARCBank.Msgs.ATMCreator.DepositSound )
			DepositSound:SetSize( 165, 20 )
			DepositSound.DoClick = function()
				AddRemoveSounds("DepositDoneSound")
			end
			
			local DepositSound = vgui.Create( "DButton",MoneyAnimD)
			DepositSound:SetPos( 10, 220 )
			DepositSound:SetText( ARCBank.Msgs.ATMCreator.DepostAnimaion )
			DepositSound:SetSize( 165, 20 )
			DepositSound.DoClick = function()
				EditAnimation("DepositAnimation")
			end
			local Pause3SL = vgui.Create( "DLabel", MoneyAnimD )
			Pause3SL:SetPos( 10, 254 ) -- Set the position of the label
			Pause3SL:SetText( ARCBank.Msgs.ATMCreator.PauseSecondsShort )
			Pause3SL:SizeToContents()
			Pause3SL:SetDark(true)
			local Pause3S = vgui.Create("DNumberWang",MoneyAnimD)
			Pause3S:SetPos(105, 250)
			Pause3S:SetSize(70, 20)
			Pause3S:SetMinMax(0, 10)
			Pause3S:SetDecimals(2)
			Pause3S:SetValue(ATMThing.ATMType.PauseAfterDepositAnimation)
			Pause3S.OnValueChanged = function(self,value)
				ATMThing.ATMType.PauseAfterDepositAnimation = value
			end
			local DepositAnimation = vgui.Create( "DButton",MoneyAnimD)
			DepositAnimation:SetPos( 10, 280 )
			DepositAnimation:SetText( ARCBank.Msgs.ATMCreator.CloseAnimation )
			DepositAnimation:SetSize( 340, 20 )
			DepositAnimation.DoClick = function()
				EditAnimation("CloseAnimation")
			end
			
			
			local TestDeposit = vgui.Create( "DButton",MoneyAnimD)
			TestDeposit:SetPos( 10, 310 )
			TestDeposit:SetText( ARCBank.Msgs.ATMCreator.AnimTest )
			TestDeposit:SetSize( 340, 20 )
			TestDeposit.DoClick = function()
				Derma_Query( ARCBank.Msgs.ATMCreator.DepositFailQuestion, ARCBank.Msgs.ATMCreator.AnimTest, ARCBank.Msgs.ATMMsgs.Yes, function()
					net.Start("ARCBank ATMCreate Test")
					--net.WriteEntity(ATMThing) I almost trusted the client, lel
					net.WriteBit(false)
					net.WriteBit(true)
					net.SendToServer()
				end, ARCBank.Msgs.ATMMsgs.No, function() 
					net.Start("ARCBank ATMCreate Test")
					--net.WriteEntity(ATMThing) I almost trusted the client, lel
					net.WriteBit(false)
					net.WriteBit(false)
					net.SendToServer()
				end)
			end
			
			local MoneyAnimW = vgui.Create( "DPanel")
			
			local WithdrawStartSound = vgui.Create( "DButton",MoneyAnimW)
			WithdrawStartSound:SetPos( 10, 10 )
			WithdrawStartSound:SetText( ARCBank.Msgs.ATMCreator.WithdrawStartSound )
			WithdrawStartSound:SetSize( 340, 20 )
			WithdrawStartSound.DoClick = function()
				AddRemoveSounds("WithdrawSound")
			end
			
			local WPause1L = vgui.Create( "DLabel", MoneyAnimW )
			WPause1L:SetPos( 10, 44 ) -- Set the position of the label
			WPause1L:SetText( ARCBank.Msgs.ATMCreator.PauseSeconds )
			WPause1L:SizeToContents()
			WPause1L:SetDark(true)
			local WPause1 = vgui.Create("DNumberWang",MoneyAnimW)
			WPause1:SetPos(280, 40)
			WPause1:SetSize(70, 20)
			WPause1:SetMinMax(0, 10)
			WPause1:SetDecimals(2)
			WPause1:SetValue(ATMThing.ATMType.PauseBeforeWithdrawAnimation)
			WPause1.OnValueChanged = function(self,value)
				ATMThing.ATMType.PauseBeforeWithdrawAnimation = value
			end
			
			local WithdrawOpenAnimation = vgui.Create( "DButton",MoneyAnimW)
			WithdrawOpenAnimation:SetPos( 10, 70 )
			WithdrawOpenAnimation:SetText( ARCBank.Msgs.ATMCreator.ATMOpenAnim )
			WithdrawOpenAnimation:SetSize( 340, 20 )
			WithdrawOpenAnimation.DoClick = function()
				EditAnimation("OpenAnimation")
			end
			
			local WPause2L = vgui.Create( "DLabel", MoneyAnimW )
			WPause2L:SetPos( 10, 104 ) -- Set the position of the label
			WPause2L:SetText( ARCBank.Msgs.ATMCreator.PauseSeconds )
			WPause2L:SizeToContents()
			WPause2L:SetDark(true)
			local WPause2L = vgui.Create("DNumberWang",MoneyAnimW)
			WPause2L:SetPos(280, 100)
			WPause2L:SetSize(70, 20)
			WPause2L:SetMinMax(0, 10)
			WPause2L:SetDecimals(2)
			WPause2L:SetValue(ATMThing.ATMType.PauseAfterWithdrawAnimation)
			WPause2L.OnValueChanged = function(self,value)
				ATMThing.ATMType.PauseAfterWithdrawAnimation = value
			end
			
			local WithdrawAnim = vgui.Create( "DButton",MoneyAnimW)
			WithdrawAnim:SetPos( 10, 130 )
			WithdrawAnim:SetText( ARCBank.Msgs.ATMCreator.WithdrawAnimation )
			WithdrawAnim:SetSize( 340, 20 )
			WithdrawAnim.DoClick = function()
				EditAnimation("WithdrawAnimation")
			end
			
			local WaitL = vgui.Create( "DLabel", MoneyAnimW )
			WaitL:SetPos( 10, 164 ) -- Set the position of the label
			WaitL:SetText( ARCBank.Msgs.ATMCreator.WaitUser )
			WaitL:SizeToContents()
			WaitL:SetDark(true)
			
			local WithCloseAnimation = vgui.Create( "DButton",MoneyAnimW)
			WithCloseAnimation:SetPos( 10, 190 )
			WithCloseAnimation:SetText( ARCBank.Msgs.ATMCreator.CloseAnimation )
			WithCloseAnimation:SetSize( 340, 20 )
			WithCloseAnimation.DoClick = function()
				EditAnimation("CloseAnimation")
			end
			
			local TestWithdraw = vgui.Create( "DButton",MoneyAnimW)
			TestWithdraw:SetPos( 10, 310 )
			TestWithdraw:SetText( ARCBank.Msgs.ATMCreator.AnimTest )
			TestWithdraw:SetSize( 340, 20 )
			TestWithdraw.DoClick = function()
				net.Start("ARCBank ATMCreate Test")
				net.WriteBit(true)
				net.WriteBit(false)
				net.SendToServer()
			end
			
			
			local MoneyLight = vgui.Create( "DPanel")
			
			
			local MLSliderXD = vgui.Create( "DLabel", MoneyLight )
			MLSliderXD:SetText( ARCBank.Msgs.ATMCreator.PositionX )
			MLSliderXD:SetPos( 10, 20 )
			MLSliderXD:SizeToContents()
			MLSliderXD:SetDark(true)
			local MLSliderX = vgui.Create( "Slider", MoneyLight )
			MLSliderX:SetPos( 100, 10 )
			MLSliderX:SetWide( 260 )
			MLSliderX:SetMin(-100)
			MLSliderX:SetMax(100)
			MLSliderX:SetDecimals(3)
			MLSliderX:SetValue(ATMThing.ATMType.Moneylight.x)
			function MLSliderX:OnValueChanged( value )
				ATMThing.ATMType.Moneylight.x = value
			end
			local MLSliderYD = vgui.Create( "DLabel", MoneyLight )
			MLSliderYD:SetText( ARCBank.Msgs.ATMCreator.PositionY )
			MLSliderYD:SetPos( 10, 40 )
			MLSliderYD:SizeToContents()
			MLSliderYD:SetDark(true)
			local MLSliderY = vgui.Create( "Slider", MoneyLight )
			MLSliderY:SetPos( 100, 30 )
			MLSliderY:SetWide( 260 )
			MLSliderY:SetMin(-100)
			MLSliderY:SetMax(100)
			MLSliderY:SetDecimals(3)
			MLSliderY:SetValue(ATMThing.ATMType.Moneylight.y)
			function MLSliderY:OnValueChanged( value )
				ATMThing.ATMType.Moneylight.y = value
			end
			local MLSliderZD = vgui.Create( "DLabel", MoneyLight )
			MLSliderZD:SetText( ARCBank.Msgs.ATMCreator.PositionZ )
			MLSliderZD:SetPos( 10, 60 )
			MLSliderZD:SizeToContents()
			MLSliderZD:SetDark(true)
			local MLSliderZ = vgui.Create( "Slider", MoneyLight )
			MLSliderZ:SetPos( 100, 50 )
			MLSliderZ:SetWide( 260 )
			MLSliderZ:SetMin(-100)
			MLSliderZ:SetMax(100)
			MLSliderZ:SetDecimals(3)
			MLSliderZ:SetValue(ATMThing.ATMType.Moneylight.z)
			function MLSliderZ:OnValueChanged( value )
				ATMThing.ATMType.Moneylight.z = value
			end
			local MLSliderSD = vgui.Create( "DLabel", MoneyLight )
			MLSliderSD:SetText( ARCBank.Msgs.ATMCreator.ScreenSize )
			MLSliderSD:SetPos( 10, 80 )
			MLSliderSD:SizeToContents()
			MLSliderSD:SetDark(true)
			local MLSliderS = vgui.Create( "Slider", MoneyLight )
			MLSliderS:SetPos( 100, 70 )
			MLSliderS:SetWide( 260 )
			MLSliderS:SetMin(0)
			MLSliderS:SetMax(1)
			MLSliderS:SetDecimals(5)
			MLSliderS:SetValue(ATMThing.ATMType.MoneylightSize)
			function MLSliderS:OnValueChanged( value )
				ATMThing.ATMType.MoneylightSize = value
			end
			
			local MLSliderPD = vgui.Create( "DLabel", MoneyLight )
			MLSliderPD:SetText( ARCBank.Msgs.ATMCreator.AngleP )
			MLSliderPD:SetPos( 10, 100 )
			MLSliderPD:SizeToContents()
			MLSliderPD:SetDark(true)
			local MLSliderP = vgui.Create( "Slider", MoneyLight )
			MLSliderP:SetPos( 100, 90 )
			MLSliderP:SetWide( 260 )
			MLSliderP:SetMin(0)
			MLSliderP:SetMax(360)
			MLSliderP:SetDecimals(3)
			MLSliderP:SetValue(ATMThing.ATMType.MoneylightAng.p)
			function MLSliderP:OnValueChanged( value )
				ATMThing.ATMType.MoneylightAng.p = value
			end
			local MLSliderYaD = vgui.Create( "DLabel", MoneyLight )
			MLSliderYaD:SetText( ARCBank.Msgs.ATMCreator.AngleY )
			MLSliderYaD:SetPos( 10, 120)
			MLSliderYaD:SizeToContents()
			MLSliderYaD:SetDark(true)
			local MLSliderYa = vgui.Create( "Slider", MoneyLight )
			MLSliderYa:SetPos( 100, 110 )
			MLSliderYa:SetWide( 260 )
			MLSliderYa:SetMin(0)
			MLSliderYa:SetMax(360)
			MLSliderYa:SetDecimals(3)
			MLSliderYa:SetValue(ATMThing.ATMType.MoneylightAng.y)
			function MLSliderYa:OnValueChanged(value )
				ATMThing.ATMType.MoneylightAng.y = value
			end
			local MLSliderRD = vgui.Create( "DLabel", MoneyLight )
			MLSliderRD:SetText( ARCBank.Msgs.ATMCreator.AngleR )
			MLSliderRD:SetPos( 10, 140 )
			MLSliderRD:SizeToContents()
			MLSliderRD:SetDark(true)
			local MLSliderR = vgui.Create( "Slider", MoneyLight )
			MLSliderR:SetPos( 100, 130 )
			MLSliderR:SetWide( 260 )
			MLSliderR:SetMin(0)
			MLSliderR:SetMax(360)
			MLSliderR:SetDecimals(3)
			MLSliderR:SetValue(ATMThing.ATMType.MoneylightAng.z)
			function MLSliderR:OnValueChanged(value )
				ATMThing.ATMType.MoneylightAng.r = value
			end
			
			local MLSliderWD = vgui.Create( "DLabel", MoneyLight )
			MLSliderWD:SetText( ARCBank.Msgs.ATMCreator.ScreenWide )
			MLSliderWD:SetPos( 10, 160 )
			MLSliderWD:SizeToContents()
			MLSliderWD:SetDark(true)
			local MLSliderW = vgui.Create( "Slider", MoneyLight )
			MLSliderW:SetPos( 100, 150 )
			MLSliderW:SetWide( 260 )
			MLSliderW:SetMin(0)
			MLSliderW:SetMax(100)
			MLSliderW:SetDecimals(0)
			MLSliderW:SetValue(ATMThing.ATMType.MoneylightWidth)
			function MLSliderW:OnValueChanged(value )
				ATMThing.ATMType.MoneylightWidth = value
			end
			
			local MLSliderHD = vgui.Create( "DLabel", MoneyLight )
			MLSliderHD:SetText( ARCBank.Msgs.ATMCreator.ScreenHeight )
			MLSliderHD:SetPos( 10, 180 )
			MLSliderHD:SizeToContents()
			MLSliderHD:SetDark(true)
			local MLSliderH = vgui.Create( "Slider", MoneyLight )
			MLSliderH:SetPos( 100, 170 )
			MLSliderH:SetWide( 260 )
			MLSliderH:SetMin(0)
			MLSliderH:SetMax(100)
			MLSliderH:SetDecimals(0)
			MLSliderH:SetValue(ATMThing.ATMType.MoneylightHeight)
			function MLSliderH:OnValueChanged(value )
				ATMThing.ATMType.MoneylightHeight = value
			end
			
			local MLFill = vgui.Create( "DCheckBoxLabel", MoneyLight )
			MLFill:SetPos( 10, 205 )
			MLFill:SetText( ARCBank.Msgs.ATMCreator.Fill )
			MLFill:SizeToContents()
			MLFill:SetDark( 1 )
			MLFill:SetValue( ARCLib.BoolToNumber(ATMThing.ATMType.MoneylightFill) )
			function MLFill:OnChange( val )
				ATMThing.ATMType.MoneylightFill = val
			end
			
			local MLUse = vgui.Create( "DCheckBoxLabel", MoneyLight )
			MLUse:SetPos( 100, 205 )
			MLUse:SetText( ARCBank.Msgs.ATMCreator.UseLight )
			MLUse:SizeToContents()
			MLUse:SetDark( 1 )
			MLUse:SetValue( ARCLib.BoolToNumber(ATMThing.ATMType.UseMoneylight) )
			function MLUse:OnChange( val )
				ATMThing.ATMType.UseMoneylight = val
			end
			
			local MLSkinL = vgui.Create( "DLabel", MoneyLight )
			MLSkinL:SetPos( 210, 205 ) -- Set the position of the label
			MLSkinL:SetText( ARCBank.Msgs.ATMCreator.SkinSwitch )
			MLSkinL:SizeToContents()
			MLSkinL:SetDark( 1 )
			local MLSkin = vgui.Create("DNumberWang",MoneyLight)
			MLSkin:SetPos(300, 202)
			MLSkin:SetSize(20, 20)
			MLSkin:SetMinMax(0, 10)
			MLSkin:SetValue(ATMThing.ATMType.OpenSkin)
			MLSkin.OnValueChanged = function(self,val)
				ATMThing.ATMType.LightSkin = val
			end
		
			local MLColourMixerContain = vgui.Create( "DPanel",MoneyLight)
			MLColourMixerContain:SetPos( 10, 230 )
			MLColourMixerContain:SetSize( 340, 160 )
			local MLMixer = vgui.Create( "DColorMixer", MLColourMixerContain )
			MLMixer:Dock( FILL )
			MLMixer:SetColor( ATMThing.ATMType.MoneylightColour )
			function MLMixer:ValueChanged(value)
				ATMThing.ATMType.MoneylightColour = value
			end
			
			local CardAnim = vgui.Create( "DPanel")
			
			local CardInsertAnimB = vgui.Create( "DButton",CardAnim)
			CardInsertAnimB:SetPos( 10, 10 )
			CardInsertAnimB:SetText( ARCBank.Msgs.ATMCreator.EditCardInAnim )
			CardInsertAnimB:SetSize( 340, 20 )
			CardInsertAnimB.DoClick = function()
				EditAnimation("CardInsertAnimation")
			end
			
			local CardInsertSnd = vgui.Create( "DButton",CardAnim)
			CardInsertSnd:SetPos( 10, 40 )
			CardInsertSnd:SetText( ARCBank.Msgs.ATMCreator.EditCardInAnim )
			CardInsertSnd:SetSize( 340, 20 )
			CardInsertSnd.DoClick = function()
				AddRemoveSounds("InsertCardSound")
			end
			
			
			local CardInsertAnimBT = vgui.Create( "DButton",CardAnim)
			CardInsertAnimBT:SetPos( 10, 70 )
			CardInsertAnimBT:SetText( ARCBank.Msgs.ATMCreator.TestCardInAnim  )
			CardInsertAnimBT:SetSize( 340, 20 )
			CardInsertAnimBT.DoClick = function()
				--EditAnimation("CardInsertAnimation")
				net.Start("ARCBank ATMCreate Test Card")
				net.WriteBit(false)
				net.SendToServer()
			end
			local CardRemoveAnimB = vgui.Create( "DButton",CardAnim)
			CardRemoveAnimB:SetPos( 10, 100 )
			CardRemoveAnimB:SetText( ARCBank.Msgs.ATMCreator.EditCardOutAnim)
			CardRemoveAnimB:SetSize( 340, 20 )
			CardRemoveAnimB.DoClick = function()
				EditAnimation("CardRemoveAnimation")
			end
			local CardRemoveSnd = vgui.Create( "DButton",CardAnim)
			CardRemoveSnd:SetPos( 10, 130 )
			CardRemoveSnd:SetText( ARCBank.Msgs.ATMCreator.EditCardOutSound )
			CardRemoveSnd:SetSize( 340, 20 )
			CardRemoveSnd.DoClick = function()
				AddRemoveSounds("WithdrawCardSound")
			end
			local CardRemoveAnimBT = vgui.Create( "DButton",CardAnim)
			CardRemoveAnimBT:SetPos( 10, 160 )
			CardRemoveAnimBT:SetText( ARCBank.Msgs.ATMCreator.TestCardOutAnim )
			CardRemoveAnimBT:SetSize( 340, 20 )
			CardRemoveAnimBT.DoClick = function()
				net.Start("ARCBank ATMCreate Test Card")
				net.WriteBit(true)
				net.SendToServer()
			end
			
			
			
			local CardLightPanel = vgui.Create( "DPanel")
			local ScrLSliderXD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderXD:SetParent(CardLightPanel)
			ScrLSliderXD:SetText( ARCBank.Msgs.ATMCreator.PositionX )
			ScrLSliderXD:SetPos( 10, 20 )
			ScrLSliderXD:SizeToContents()
			ScrLSliderXD:SetDark(true)
			local ScrLSliderX = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderX:SetPos( 100, 10 )
			ScrLSliderX:SetWide( 260 )
			ScrLSliderX:SetMin(-100)
			ScrLSliderX:SetMax(100)
			ScrLSliderX:SetDecimals(3)
			ScrLSliderX:SetValue(ATMThing.ATMType.Cardlight.x)
			function ScrLSliderX:OnValueChanged( value )
				ATMThing.ATMType.Cardlight.x = value
			end
			local ScrLSliderYD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderYD:SetText( ARCBank.Msgs.ATMCreator.PositionY )
			ScrLSliderYD:SetPos( 10, 40 )
			ScrLSliderYD:SizeToContents()
			ScrLSliderYD:SetDark(true)
			local ScrLSliderY = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderY:SetPos( 100, 30 )
			ScrLSliderY:SetWide( 260 )
			ScrLSliderY:SetMin(-100)
			ScrLSliderY:SetMax(100)
			ScrLSliderY:SetDecimals(3)
			ScrLSliderY:SetValue(ATMThing.ATMType.Cardlight.y)
			function ScrLSliderY:OnValueChanged( value )
				ATMThing.ATMType.Cardlight.y = value
			end
			local ScrLSliderZD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderZD:SetText( ARCBank.Msgs.ATMCreator.PositionZ )
			ScrLSliderZD:SetPos( 10, 60 )
			ScrLSliderZD:SizeToContents()
			ScrLSliderZD:SetDark(true)
			local ScrLSliderZ = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderZ:SetPos( 100, 50 )
			ScrLSliderZ:SetWide( 260 )
			ScrLSliderZ:SetMin(-100)
			ScrLSliderZ:SetMax(100)
			ScrLSliderZ:SetDecimals(3)
			ScrLSliderZ:SetValue(ATMThing.ATMType.Cardlight.z)
			function ScrLSliderZ:OnValueChanged( value )
				ATMThing.ATMType.Cardlight.z = value
			end
			local ScrLSliderSD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderSD:SetText( ARCBank.Msgs.ATMCreator.ScreenSize )
			ScrLSliderSD:SetPos( 10, 80 )
			ScrLSliderSD:SizeToContents()
			ScrLSliderSD:SetDark(true)
			local ScrLSliderS = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderS:SetPos( 100, 70 )
			ScrLSliderS:SetWide( 260 )
			ScrLSliderS:SetMin(0)
			ScrLSliderS:SetMax(1)
			ScrLSliderS:SetDecimals(5)
			ScrLSliderS:SetValue(ATMThing.ATMType.CardlightSize)
			function ScrLSliderS:OnValueChanged( value )
				ATMThing.ATMType.CardlightSize = value
			end
			
			local ScrLSliderPD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderPD:SetText( ARCBank.Msgs.ATMCreator.AngleP )
			ScrLSliderPD:SetPos( 10, 100 )
			ScrLSliderPD:SizeToContents()
			ScrLSliderPD:SetDark(true)
			local ScrLSliderP = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderP:SetPos( 100, 90 )
			ScrLSliderP:SetWide( 260 )
			ScrLSliderP:SetMin(0)
			ScrLSliderP:SetMax(360)
			ScrLSliderP:SetDecimals(3)
			ScrLSliderP:SetValue(ATMThing.ATMType.CardlightAng.p)
			function ScrLSliderP:OnValueChanged( value )
				ATMThing.ATMType.CardlightAng.p = value
			end
			local ScrLSliderYaD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderYaD:SetText( ARCBank.Msgs.ATMCreator.AngleY )
			ScrLSliderYaD:SetPos( 10, 120)
			ScrLSliderYaD:SizeToContents()
			ScrLSliderYaD:SetDark(true)
			local ScrLSliderYa = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderYa:SetPos( 100, 110 )
			ScrLSliderYa:SetWide( 260 )
			ScrLSliderYa:SetMin(0)
			ScrLSliderYa:SetMax(360)
			ScrLSliderYa:SetDecimals(3)
			ScrLSliderYa:SetValue(ATMThing.ATMType.CardlightAng.y)
			function ScrLSliderYa:OnValueChanged(value )
				ATMThing.ATMType.CardlightAng.y = value
			end
			local ScrLSliderRD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderRD:SetText( ARCBank.Msgs.ATMCreator.AngleR )
			ScrLSliderRD:SetPos( 10, 140 )
			ScrLSliderRD:SizeToContents()
			ScrLSliderRD:SetDark(true)
			local ScrLSliderR = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderR:SetPos( 100, 130 )
			ScrLSliderR:SetWide( 260 )
			ScrLSliderR:SetMin(0)
			ScrLSliderR:SetMax(360)
			ScrLSliderR:SetDecimals(3)
			ScrLSliderR:SetValue(ATMThing.ATMType.CardlightAng.z)
			function ScrLSliderR:OnValueChanged(value )
				ATMThing.ATMType.CardlightAng.r = value
			end
			
			local ScrLSliderWD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderWD:SetText( ARCBank.Msgs.ATMCreator.ScreenWide )
			ScrLSliderWD:SetPos( 10, 160 )
			ScrLSliderWD:SizeToContents()
			ScrLSliderWD:SetDark(true)
			local ScrLSliderW = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderW:SetPos( 100, 150 )
			ScrLSliderW:SetWide( 260 )
			ScrLSliderW:SetMin(0)
			ScrLSliderW:SetMax(100)
			ScrLSliderW:SetDecimals(0)
			ScrLSliderW:SetValue(ATMThing.ATMType.CardlightWidth)
			function ScrLSliderW:OnValueChanged(value )
				ATMThing.ATMType.CardlightWidth = value
			end
			
			local ScrLSliderHD = vgui.Create( "DLabel", CardLightPanel )
			ScrLSliderHD:SetText( ARCBank.Msgs.ATMCreator.ScreenHeight )
			ScrLSliderHD:SetPos( 10, 180 )
			ScrLSliderHD:SizeToContents()
			ScrLSliderHD:SetDark(true)
			local ScrLSliderH = vgui.Create( "Slider", CardLightPanel )
			ScrLSliderH:SetPos( 100, 170 )
			ScrLSliderH:SetWide( 260 )
			ScrLSliderH:SetMin(0)
			ScrLSliderH:SetMax(100)
			ScrLSliderH:SetDecimals(0)
			ScrLSliderH:SetValue(ATMThing.ATMType.CardlightHeight)
			function ScrLSliderH:OnValueChanged(value )
				ATMThing.ATMType.CardlightHeight = value
			end
			local ScrLFill = vgui.Create( "DCheckBoxLabel", CardLightPanel )
			ScrLFill:SetPos( 10, 200 )
			ScrLFill:SetText( ARCBank.Msgs.ATMCreator.Fill )
			ScrLFill:SizeToContents()
			ScrLFill:SetDark( 1 )
			ScrLFill:SetValue( ARCLib.BoolToNumber(ATMThing.ATMType.CardlightFill) )
			function ScrLFill:OnChange( val )
				ATMThing.ATMType.CardlightFill = val
			end
			local ScrLUse = vgui.Create( "DCheckBoxLabel", CardLightPanel )
			ScrLUse:SetPos( 185, 200 )
			ScrLUse:SetText( ARCBank.Msgs.ATMCreator.UseLight )
			ScrLUse:SizeToContents()
			ScrLUse:SetDark( 1 )
			ScrLUse:SetValue( ARCLib.BoolToNumber(ATMThing.ATMType.UseCardlight) )
			function ScrLUse:OnChange( val )
				ATMThing.ATMType.UseCardlight = val
			end
			
			local ScrLColourMixerContain = vgui.Create( "DPanel",CardLightPanel)
			ScrLColourMixerContain:SetPos( 10, 230 )
			ScrLColourMixerContain:SetSize( 340, 160 )
			local ScrLMixer = vgui.Create( "DColorMixer", ScrLColourMixerContain )
			ScrLMixer:Dock( FILL )
			ScrLMixer:SetColor( ATMThing.ATMType.CardlightColour )
			function ScrLMixer:ValueChanged(value)
				--MsgN("aa")
				ATMThing.ATMType.CardlightColour = value
			end
			--dsadsad
			local Sounds = vgui.Create( "DPanel")

			local Snd1 = vgui.Create( "DButton",Sounds)
			Snd1:SetPos( 10, 10 )
			Snd1:SetText( ARCBank.Msgs.ATMCreator.ATMCloseSound )
			Snd1:SetSize( 340, 20 )
			Snd1.DoClick = function()
				AddRemoveSounds("CloseSound")
			end
			local Snd2 = vgui.Create( "DButton",Sounds)
			Snd2:SetPos( 10, 40 )
			Snd2:SetText( ARCBank.Msgs.ATMCreator.BtnPrsClnt )
			Snd2:SetSize( 340, 20 )
			Snd2.DoClick = function()
				AddRemoveSounds("ClientPressSound")
			end
			local Snd3 = vgui.Create( "DButton",Sounds)
			Snd3:SetPos( 10, 70 )
			Snd3:SetText( ARCBank.Msgs.ATMCreator.BtnPrsServ )
			Snd3:SetSize( 340, 20 )
			Snd3.DoClick = function()
				AddRemoveSounds("PressSound")
			end
			
			local Snd4 = vgui.Create( "DButton",Sounds)
			Snd4:SetPos( 10, 100 )
			Snd4:SetText( ARCBank.Msgs.ATMCreator.BeepSound )
			Snd4:SetSize( 340, 20 )
			Snd4.DoClick = function()
				AddRemoveSounds("WaitSound")
			end
			
			local Snd5 = vgui.Create( "DButton",Sounds)
			Snd5:SetPos( 10, 130 )
			Snd5:SetText( ARCBank.Msgs.ATMCreator.ErrSound )
			Snd5:SetSize( 340, 20 )
			Snd5.DoClick = function()
				AddRemoveSounds("ErrorSound")
			end
			
			local Snd6 = vgui.Create( "DButton",Sounds)
			Snd6:SetPos( 10, 160 )
			Snd6:SetText( ARCBank.Msgs.ATMCreator.BeepNoSound )
			Snd6:SetSize( 340, 20 )
			Snd6.DoClick = function()
				AddRemoveSounds("PressNoSound")
			end
			
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.ScreenPlacement, ScreenPlacement, "icon16/monitor_go.png", false, false, ARCBank.Msgs.ATMCreator.TooltipScreenPos )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.ScreenDisplay, ScreenColour, "icon16/palette.png", false, false, ARCBank.Msgs.ATMCreator.TooltipScreenCol )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.ButtonsPlacement, ButtonsPlacement, "icon16/cog_edit.png", false, false, ARCBank.Msgs.ATMCreator.TooltipButtPos )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.DepositAnim, MoneyAnimD, "icon16/money_add.png", false, false, ARCBank.Msgs.ATMCreator.TooltipMoneyIn )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.WithdrawAnim, MoneyAnimW, "icon16/money_delete.png", false, false, ARCBank.Msgs.ATMCreator.TooltipMoneyOut )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.MoneyLight, MoneyLight, "icon16/lightbulb.png", false, false, ARCBank.Msgs.ATMCreator.TooltipMoneyLight )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.CardAnim, CardAnim, "icon16/creditcards.png", false, false, ARCBank.Msgs.ATMCreator.TooltipCardAnim )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.CardLight, CardLightPanel, "icon16/lightbulb.png", false, false, ARCBank.Msgs.ATMCreator.TooltipCardLight )
			PropertySheet:AddSheet( ARCBank.Msgs.ATMCreator.SoundsOther, Sounds, "icon16/sound.png", false, false, ARCBank.Msgs.ATMCreator.TooltipSound )
			
			--gui.EnableScreenClicker( true ) 
		end
	
	end
	--[[
	hook.Add("KeyRelease", "ARCBank ATM CreatorStuffs", function(ply, key)
		if ply == LocalPlayer() && key == IN_USE then
			MainPanel:Remove()
			gui.EnableScreenClicker( false ) 
		end
	end)
	]]


	hook.Add("HUDPaint", "ARCBank ATM CreatorHud", function()
		if IsValid(ATMThing) then 
			local minslocal = {}
			local minsscr = {}
			local maxsscr = {}
			local screencord = ATMThing:LocalToWorld(ATMThing:OBBCenter()):ToScreen( )
			local maxslocal = ATMThing:OBBMaxs()

			minslocal[1] = ATMThing:OBBMins()
			minslocal[2] = Vector(maxslocal.x,minslocal[1].y,minslocal[1].z)
			minslocal[3] = Vector(maxslocal.x,maxslocal.y,minslocal[1].z)
			minslocal[4] = Vector(minslocal[1].x,maxslocal.y,minslocal[1].z)
			minslocal[5] = minslocal[1]
			for i = 1,5 do
				maxsscr[i] = ATMThing:LocalToWorld(Vector(minslocal[i].x,minslocal[i].y,maxslocal.z)):ToScreen( )
				minsscr[i] = ATMThing:LocalToWorld(minslocal[i]):ToScreen( )
			end
			draw.SimpleText("ATM Creator Entity", "ARCBankATMCreatorSSmall", screencord.x,screencord.y, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
			surface.SetDrawColor( 255,255,255,255 ) 
			for i = 1,4 do
				if maxsscr[i].visible && maxsscr[i+1].visible then
					surface.DrawLine( maxsscr[i].x, maxsscr[i].y,maxsscr[i+1].x, maxsscr[i+1].y ) 
				end
				if minsscr[i].visible && minsscr[i+1].visible then
					surface.DrawLine( minsscr[i].x, minsscr[i].y,minsscr[i+1].x, minsscr[i+1].y ) 
				end
				if maxsscr[i].visible && minsscr[i].visible then
					surface.DrawLine( minsscr[i].x, minsscr[i].y,maxsscr[i].x, maxsscr[i].y ) 
				end
			end
		end
	end)
	
end


