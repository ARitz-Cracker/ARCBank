-- hack_device.lua - Non-entity functions for the ATM hacking device.

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016-2017 Aritz Beobide-Cardinal All rights reserved.

ARCBank.HackableDevices = {}
net.Receive( "arcbank_add_hacking_device", function(length)
	local tab = net.ReadTable()
	ARCBank.HackableDevices[tab._i] = tab
end)
net.Receive( "arcatmhack_gui", function(length)
	local weapon = LocalPlayer():GetActiveWeapon()
	
	if (!weapon.ARCBank_IsHacker) then return end
	local setting = net.ReadTable()
	
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetPos( surface.ScreenWidth()/2-130,surface.ScreenHeight()/2-115 )
	DermaPanel:SetSize( 260, 230 )
	DermaPanel:SetTitle( ARCBank.Msgs.Hack.Menu )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( false )
	DermaPanel:MakePopup()
	
	local HackLabel = vgui.Create( "DLabel", DermaPanel )
	HackLabel:SetPos( 10, 34 )
	if istable(weapon.HackEnt) then
		HackLabel:SetText( weapon.HackEnt.Name )
	else
		HackLabel:SetText( ARCBank.Msgs.Hack.EntSelect )
	end
	HackLabel:SizeToContents()
	
	local HackSelector = vgui.Create( "DComboBox", DermaPanel)
	HackSelector:SetText( ARCBank.Msgs.Hack.NoEnt )
	HackSelector:SetPos( 100, 30 )
	HackSelector:SetSize( 140, 20 )
	for i=1,#ARCBank.HackableDevices do
		HackSelector:AddChoice( ARCBank.HackableDevices[i].Name, i )
	end

	
	local NumLabel2 = vgui.Create( "DLabel", DermaPanel )
	NumLabel2:SetPos( 10, 60 )
	NumLabel2:SetText( ARCBank.Msgs.Hack.Money )
	NumLabel2:SizeToContents()
	local HackTimeL = vgui.Create( "DLabel", DermaPanel )
	HackTimeL:SetPos( 10, 168 )
	HackTimeL:SetText( ARCBank.Msgs.Hack.ETA..ARCLib.TimeString(weapon.HackTime,ARCBank.Msgs.Time).."\n"..ARCBank.Msgs.Hack.GiveOrTake..ARCLib.TimeString(weapon.HackTimeOff,ARCBank.Msgs.Time) )
	HackTimeL:SizeToContents()

	local StealthCheckbox = vgui.Create( "DCheckBoxLabel", DermaPanel ) // Create the checkbox
	StealthCheckbox:SetPos( 10, 105 )                        // Set the position
	StealthCheckbox:SetText( ARCBank.Msgs.Hack.StealthMode )                   // Set the text next to the box
	StealthCheckbox:SetValue( ARCLib.BoolToNumber(setting[2]) )             // Initial value ( will determine whether the box is ticked too )
	StealthCheckbox:SizeToContents()                      // Make its size the same as the contents

	local About = vgui.Create( "DLabel", DermaPanel )
	About:SetText( ARCBank.Msgs.Hack.Descript )
	About:SetPos( 10, 126 )
	About:SetSize( 240, 40 )
	About:SetWrap(true)
	--About:SizeToContents()   
	local NumSlider2 = vgui.Create( "Slider", DermaPanel )
	NumSlider2:SetPos( 10, 70 )
	NumSlider2:SetWide( 260 )
	NumSlider2:SetMin(ARCBank.Settings["atm_hack_min"])
	NumSlider2:SetMax(ARCBank.Settings["atm_hack_max"])
	NumSlider2:SetDecimals(0)
	NumSlider2:SetValue( setting[1] )
	
	
	local UpdateValues = function()
		if !IsValid(weapon) then return end
		if !weapon.HackEnt then return end
		weapon.HackTime = ARCBank.HackTimeCalculate(weapon.HackEnt,NumSlider2:GetValue(),StealthCheckbox:GetChecked())
		weapon.HackTimeOff = ARCBank.HackTimeOffset(weapon.HackEnt,weapon.HackTime)
		weapon.ScreenScroll = 1
		weapon.ScreenScrollDelay = CurTime() + 0.1
		weapon.SScreenScroll = 1
		weapon.SScreenScrollDelay = CurTime() + 0.1
		weapon.SSScreenScroll = 1
		weapon.SSScreenScrollDelay = CurTime() + 0.1
		weapon.HackRandom = StealthCheckbox:GetChecked()
		HackTimeL:SetText( ARCBank.Msgs.Hack.ETA..ARCLib.TimeString(weapon.HackTime,ARCBank.Msgs.Time).."\n"..ARCBank.Msgs.Hack.GiveOrTake..ARCLib.TimeString(weapon.HackTimeOff,ARCBank.Msgs.Time) )
		HackTimeL:SizeToContents()
	end
	
	NumSlider2.OnValueChanged = function( panel, value )
		if !weapon.HackEnt then return end
		if value%25 != 0 then
			NumSlider2:SetValue( math.Clamp(math.Round(value/25)*25,ARCBank.HackTimeGetSetting(weapon.HackEnt,"MoneyMin"),ARCBank.HackTimeGetSetting(weapon.HackEnt,"MoneyMax")) )
			return
		end
		--math.Clamp(NumSlider2:GetValue(),0,setting[3])
		UpdateValues()
	end
	StealthCheckbox.OnChange = function( panel, value )
		UpdateValues()
	end
	
	HackSelector.OnSelect = function( panel, index, value )
		weapon.HackEnt = ARCBank.HackableDevices[index]
		--PrintTable(weapon.HackEnt)
		NumSlider2:SetValue(Lerp(0.5,ARCBank.HackTimeGetSetting(weapon.HackEnt,"MoneyMin"),ARCBank.HackTimeGetSetting(weapon.HackEnt,"MoneyMax")))
	end
	
	local OkButton = vgui.Create( "DButton", DermaPanel )
	OkButton:SetText( "OK" )
	OkButton:SetPos( 10, 200 )
	OkButton:SetSize( 240, 20 )
	OkButton.DoClick = function()
		DermaPanel:Remove()
		if (!weapon.HackEnt) then return end
		net.Start("arcatmhack_gui")
		net.WriteEntity(weapon)
		net.WriteUInt(weapon.HackEnt._i,8)
		net.WriteTable({math.Clamp(NumSlider2:GetValue(),ARCBank.HackTimeGetSetting(weapon.HackEnt,"MoneyMin"),ARCBank.HackTimeGetSetting(weapon.HackEnt,"MoneyMax")),StealthCheckbox:GetChecked()})
		net.SendToServer()
	end
end)