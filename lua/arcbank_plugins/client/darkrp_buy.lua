-- darkrp_buy.lua - Allows you to pay for shipments and stuff using your ARCBank account

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2017-2018 Aritz Beobide-Cardinal All rights reserved.

net.Receive("arcbank_buyshit",function(len,ply)
	local typ = net.ReadUInt(2)
	local itemcmd = net.ReadString()
	
	Derma_Query( string.Replace(ARCBank.Msgs.UserMsgs.F4MenuAsk,"ARCBank",ARCBank.Settings.name), ARCBank.Settings.name_long, ARCBank.Msgs.ATMMsgs.Yes, function()
		--Copy/pasted from my ARCLib.Derma_ChoiceRequest function
		
		local Window = vgui.Create( "DFrame" )
			Window:SetTitle( ARCBank.Settings.name_long )
			Window:SetDraggable( false )
			Window:ShowCloseButton( false )
			Window:SetBackgroundBlur( true )
			Window:SetDrawOnTop( true )
			
		local InnerPanel = vgui.Create( "DPanel", Window )
			InnerPanel:SetDrawBackground( false )
		
		local Text = vgui.Create( "DLabel", InnerPanel )
			Text:SetText( ARCBank.Msgs.CardMsgs.AccountPay )
			Text:SizeToContents()
			Text:SetContentAlignment( 5 )
			Text:SetTextColor( color_white )
			
		local TextEntry = vgui.Create( "DComboBox", InnerPanel )
		local TextEntryProgress = vgui.Create( "DProgressFake", InnerPanel )
			
		local ButtonPanel = vgui.Create( "DPanel", Window )
			ButtonPanel:SetTall( 30 )
			ButtonPanel:SetDrawBackground( false )
			
		local Button = vgui.Create( "DButton", ButtonPanel )
			Button:SetText( ARCBank.Msgs.ATMMsgs.OK )
			Button:SizeToContents()
			Button:SetTall( 20 )
			Button:SetWide( Button:GetWide() + 20 )
			Button:SetPos( 5, 5 )
			Button:SetEnabled(false)
			
		local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
			ButtonCancel:SetText( ARCBank.Msgs.ATMMsgs.Cancel )
			ButtonCancel:SizeToContents()
			ButtonCancel:SetTall( 20 )
			ButtonCancel:SetWide( Button:GetWide() + 20 )
			ButtonCancel:SetPos( 5, 5 )
			ButtonCancel:MoveRightOf( Button, 5 )
			ButtonCancel:SetEnabled(false)
			
		ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
		
		local w, h = Text:GetSize()
		w = math.max( w, 400 ) 
		
		Window:SetSize( w + 50, h + 25 + 75 + 10 )
		Window:Center()
		
		InnerPanel:StretchToParent( 5, 25, 5, 45 )
		
		Text:StretchToParent( 5, 5, 5, 35 )	

		TextEntry:StretchToParent( 5, nil, 5, nil )
		TextEntry:AlignBottom( 5 )
		TextEntry:SetVisible(false)
		
		--TextEntry:RequestFocus()
		--TextEntry:SelectAllText( true )
		
		TextEntryProgress:SetPos(TextEntry:GetPos())
		TextEntryProgress:SetSize(TextEntry:GetSize())
		TextEntryProgress:SetVisible(true)
		TextEntryProgress:StartProgress()
		
		
		ButtonPanel:CenterHorizontal()
		ButtonPanel:AlignBottom( 8 )
		
		Window:MakePopup()
		
		
		
		ARCBank.GetAccessableAccounts(LocalPlayer(), function(errorcode, account_list)
			if errorcode ~= ARCBANK_ERROR_NONE then
				Window:Close() 
				Derma_Message( ARCBANK_ERRORSTRINGS[errorcode], ARCBank.Settings.name_long, ARCBank.Msgs.ATMMsgs.OK )
				return
			end
			local choiceNames = {}
			local choiceValues = {}
			local i = 1
			choiceNames[i] = ARCBank.Msgs.ATMMsgs.PersonalAccount
			choiceValues[i] = ""
			for _,account1 in ipairs(account_list) do
				if string.sub(account1,1,1) ~= "_" then
					i = i + 1
					choiceNames[i] = ARCLib.basexx.from_base32(string.upper(string.sub(account1,1,#account1-1)))
					choiceValues[i] = account1
				end
			end
			
			local account = choiceValues[1]

			TextEntryProgress:StopProgress(t,function()
				TextEntryProgress:SetVisible(false)
				TextEntry:SetVisible(true)
				ButtonCancel:SetEnabled(true)
				Button:SetEnabled(true)
			end)

			
			for i=1,#choiceNames do
				TextEntry:AddChoice(choiceNames[i])
			end
			TextEntry.OnSelect = function( panel, index, value )
				account = choiceValues[index]
			end
			TextEntry:SetValue(choiceNames[1])
			
			ButtonCancel.DoClick = function() Window:Close()  end
			
			Button.DoClick = function()
				Window:Close() 
				net.Start("arcbank_buyshit")
				net.WriteUInt(typ,2)
				net.WriteString(account)
				net.WriteString(itemcmd)
				net.SendToServer()
			end
			--Window:DoModal()	
		end)
	
	end, ARCBank.Msgs.ATMMsgs.No,function()
		net.Start("arcbank_buyshit")
		net.WriteUInt(typ,2)
		net.WriteString("_")
		net.WriteString(itemcmd)
		net.SendToServer()
	end) 
end)