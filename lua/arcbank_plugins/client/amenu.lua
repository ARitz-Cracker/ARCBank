-- GUI for ARitz Cracker Bank (Clientside)
-- This shit is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
-- However, you must credit me.
if ARCBank then
	local ARCBankGUI = ARCBankGUI or {}
	ARCBankGUI.SelectedAccountRank = 0
	ARCBankGUI.SelectedAccount = ""
	ARCBankGUI.Log = ""
	ARCBankGUI.LogDownloaded = false
	ARCBankGUI.AccountListTab = {}
	function ARCBankGUI:Open(settings,descriptions,logs)
		ARCBankGUI.DermaPanel = vgui.Create( "DFrame" )
		ARCBankGUI.DermaPanel:SetPos( 50, 50 )
		ARCBankGUI.DermaPanel:SetSize( 310, 373 )
		ARCBankGUI.DermaPanel:SetTitle( ARCBank.Settings.name_long" - Admin menu" )
		ARCBankGUI.DermaPanel:SetVisible( true )
		ARCBankGUI.DermaPanel:SetDraggable( true )
		ARCBankGUI.DermaPanel:ShowCloseButton( true )
		ARCBankGUI.DermaPanel:MakePopup()
 
		local PropertySheet = vgui.Create( "DPropertySheet", ARCBankGUI.DermaPanel )
		PropertySheet:SetPos( 5, 30 )
		PropertySheet:SetSize( 300, 278 )
	
		local SettingsContainer = vgui.Create( "DPanel")
		local AList1= vgui.Create( "DComboBox",SettingsContainer)
		AList1:SetPos(10,10)
		AList1:SetSize( 265, 20 )
		AList1:SetText( "Choose a setting:" )
		for k,v in SortedPairs(settings) do
			AList1:AddChoice(k)
		end
	
		local SettingSave = vgui.Create( "DButton", SettingsContainer )
		SettingSave:SetText( "Save settings" )
		SettingSave:SetPos( 10, 152 )
		SettingSave:SetSize( 265, 20 )
		SettingSave.DoClick = function()
			RunConsoleCommand( "arcbank","settings_save")
		end
		local AtmSave = vgui.Create( "DButton", SettingsContainer )
		AtmSave:SetText( "Save all active ATMs onto map" )
		AtmSave:SetPos( 10, 182 )
		AtmSave:SetSize( 265, 20 )
		AtmSave.DoClick = function()
			RunConsoleCommand( "arcbank","atm_save")
		end
		local AtmRespawn = vgui.Create( "DButton", SettingsContainer )
		AtmRespawn:SetText( "Respawn map-based ATMs" )
		AtmRespawn:SetPos( 10, 212 )
		AtmRespawn:SetSize( 265, 20 )
		AtmRespawn.DoClick = function()
			RunConsoleCommand( "arcbank","atm_respawn")
		end
		local SettingDesc = vgui.Create( "DLabel", SettingsContainer )
		SettingDesc:SetPos( 12, 35 ) -- Set the position of the label
		SettingDesc:SetText( "Choose a setting" ) --  Set the text of the label
		SettingDesc:SetWrap(true)
		SettingDesc:SetSize( 265, 50 )
--		SettingDesc:SizeToContents() -- Size the label to fit the text in it
		SettingDesc:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
		local SettingBool = vgui.Create( "DCheckBoxLabel", SettingsContainer )
		SettingBool:SetPos( 12, 92 )
		SettingBool:SetText( "Enable" )
		SettingBool:SetValue( 1 )
		SettingBool:SizeToContents()
		SettingBool:SetVisible(false)
		SettingBool:SetDark( 1 )
		local SettingNum = vgui.Create( "DNumberWang", SettingsContainer )
		SettingNum:SetPos( 10, 92 )
		SettingNum:SetSize( 265, 20 )
		SettingNum:SetValue( 1 )
		SettingNum:SetVisible(false)
		SettingNum:SetMinMax( 0 , 1000000 )
		SettingNum:SetDecimals(4)
		local SettingStr = vgui.Create( "DTextEntry", SettingsContainer )
		SettingStr:SetPos( 12,92 )
		SettingStr:SetTall( 20 )
		SettingStr:SetWide( 265 )
		SettingStr:SetVisible(false)
		SettingStr:SetEnterAllowed( true )
		local SettingsTabContainer = vgui.Create( "DPanel",SettingsContainer)
		SettingsTabContainer:SetPos(10,92)
		SettingsTabContainer:SetSize( 265, 50 )
		SettingsTabContainer:SetVisible(false)
		local SettingTab = vgui.Create( "DComboBox", SettingsTabContainer )
		SettingTab:SetPos( 0,0 )
		SettingTab:SetSize( 210, 20 )
		function SettingTab:OnSelect(index,value,data)
			SettingTab.Selection = value
		end
		local SettingTaba = vgui.Create( "DTextEntry", SettingsTabContainer )
		SettingTaba:SetPos( 0,30 )
		SettingTaba:SetTall( 20 )
		SettingTaba:SetWide( 210 )
		--SettingTaba:SetVisible(false)
		SettingTaba:SetEnterAllowed( true )
	
		local SettingRemove = vgui.Create( "DButton", SettingsTabContainer )
		SettingRemove:SetText( "Remove" )
		SettingRemove:SetPos( 210, 0 )
		SettingRemove:SetSize( 55, 20 )
		local SettingAdd = vgui.Create( "DButton", SettingsTabContainer )
		SettingAdd:SetText( "Add" )
		SettingAdd:SetPos( 210, 30)
		SettingAdd:SetSize( 55, 20 )
	
		function AList1:OnSelect(index,value,data)
			SettingDesc:SetText("Description:\n"..tostring(descriptions[value]));
			--SettingDesc:SizeToContents();
				SettingBool.OnChange = function( pan, val ) end
				SettingStr.OnValueChanged = function( pan, val ) end
				SettingStr.OnEnter = function() end
				SettingNum.OnValueChanged = function( pan, val ) end
			if isnumber(settings[value]) then
				SettingBool:SetVisible(false)
				SettingNum:SetVisible(true)
				SettingStr:SetVisible(false)
				SettingsTabContainer:SetVisible(false)
				SettingNum:SetValue( settings[value] )
				SettingNum.OnValueChanged = function( pan, val )
					RunConsoleCommand( "arcbank","settings",value,tostring(val))
				end
			elseif istable(settings[value]) then
				SettingNum:SetVisible(false)
				SettingBool:SetVisible(false)
				SettingStr:SetVisible(false)
				SettingsTabContainer:SetVisible(true)
				SettingTab:Clear()
				SettingTab.Selection = ""
				for k,v in pairs(settings[value]) do
					SettingTab:AddChoice(v)
				end
				SettingAdd.DoClick = function()
					
					table.insert( settings[value], SettingTaba:GetValue() )
					string.Replace(SettingTaba:GetValue(), ",", "_")
					local s = ""
					for o,p in pairs(settings[value]) do
						if o > 1 then
							s = s..","..p
						else
							s = p
						end
					end
					RunConsoleCommand( "arcbank","settings",value,s)
					SettingTab:AddChoice(SettingTaba:GetValue())
					SettingTaba:SetValue("")
				end	
				SettingRemove.DoClick = function()
					table.RemoveByValue( settings[value], SettingTab.Selection )
					local s = ""
					for o,p in pairs(settings[value]) do
						if o > 1 then
							s = s..","..p
						else
							s = p
						end
					end
					SettingTab:Clear()
					for k,v in pairs(settings[value]) do
						SettingTab:AddChoice(v)
					end
					RunConsoleCommand( "arcbank","settings",value,s)
				end
			elseif isstring(settings[value]) then
				SettingNum:SetVisible(false)
				SettingBool:SetVisible(false)
				SettingStr:SetVisible(true)
				SettingsTabContainer:SetVisible(false)
				SettingStr:SetValue( settings[value] )
				SettingStr.OnValueChanged = function( pan, val )
					SettingStr:SetValue(tostring(val))
					RunConsoleCommand( "arcbank","settings",value,tostring(val))
				end
				SettingStr.OnEnter = function()
					SettingStr:SetValue(SettingStr:GetValue())
					RunConsoleCommand( "arcbank","settings",value,SettingStr:GetValue())
				end
			elseif isbool(settings[value]) then
				SettingNum:SetVisible(false)
				SettingBool:SetVisible(true)
				SettingStr:SetVisible(false)
				SettingsTabContainer:SetVisible(false)
				SettingBool:SetValue( booltonumber(settings[value]) )
				SettingBool.OnChange = function( pan, val )
					RunConsoleCommand( "arcbank","settings",value,tostring(val))
				end
			end
		end
		
		local LogContainer = vgui.Create( "DPanel")
		local DummyLogList= vgui.Create( "DComboBox",LogContainer)
		DummyLogList:SetPos(10,10)
		DummyLogList:SetSize( 265, 20 )
		DummyLogList:SetText( "Loading..." )
		
		
		ARCBankGUI.LogList= vgui.Create( "DComboBox",LogContainer)
		ARCBankGUI.LogList:SetPos(10,10)
		ARCBankGUI.LogList:SetSize( 265, 20 )
		ARCBankGUI.LogList:SetText( "Choose a log:" )
		for k,v in SortedPairs(logs) do
			ARCBankGUI.LogList:AddChoice(v)
		end
		function ARCBankGUI.LogList:OnSelect(index,value,data)
			ARCBankGUI.Ignore = false
			ARCBankGUI.CurrentChunk = 1
			ARCBankGUI.LogDownloaded = false
			ARCBankGUI.LogList:SetVisible(false)
			ARCBankGUI.Log = ""
			DummyLogList:SetText(value)
			net.Start( "ARCBank_Admin_Send" )
			net.WriteInt(0,ARCBANK_ACCOUNTBITRATE)
			net.WriteString(tostring(value))
			net.SendToServer()
			ARCBankGUI.LogOpen:SetText("Loading... (0%)")
		end
		ARCBankGUI.LogProgress = vgui.Create( "DProgress",ARCBankGUI.DermaPanel )
		ARCBankGUI.LogProgress:SetPos( 5, 312 )
		ARCBankGUI.LogProgress:SetSize( 300, 25 )
		ARCBankGUI.LogProgress:SetFraction( 1 )
		
		ARCBankGUI.LogOpen = vgui.Create( "DButton", ARCBankGUI.DermaPanel )
		ARCBankGUI.LogOpen:SetText( "" )
		ARCBankGUI.LogOpen:SetPos( 5, 342 )
		ARCBankGUI.LogOpen:SetSize( 300, 25 )
		ARCBankGUI.LogOpen.DoClick = function()
			if !ARCBankGUI.LogDownloaded then return end
			--RunConsoleCommand( "arcbank","atm_save")
			local DermaPanel = vgui.Create( "DFrame" )
			DermaPanel:SetSize( 600,550 )
			DermaPanel:Center()
			DermaPanel:SetTitle( "Text File" )
			DermaPanel:MakePopup()
			
			
			Text = vgui.Create("DTextEntry", DermaPanel) // The info text.
			Text:SetPos( 5, 30 ) -- Set the position of the label
			Text:SetSize( 590, 515 )
			Text:SetText( ARCBankGUI.Log ) --  Set the text of the label
			Text:SetMultiline(true)
			Text:SetEnterAllowed(false)
			Text:SetVerticalScrollbarEnabled(true)
		end
		
		local AccountsContainer = vgui.Create( "DPanel")

		RankList= vgui.Create( "DComboBox",AccountsContainer)
		RankList:SetPos(10,10)
		RankList:SetSize( 265, 20 )
		RankList:SetText( "Choose a rank" )
		RankList:AddChoice("Personal - Basic")
		RankList:AddChoice("Personal - Bronze")
		RankList:AddChoice("Personal - Silver")
		RankList:AddChoice("Personal - Gold")
		RankList:AddChoice("Group - Standard")
		RankList:AddChoice("Group - Premium")
		local accountinfomation = vgui.Create( "DLabel", AccountsContainer )
		accountinfomation:SetPos( 12, 100 ) -- Set the position of the label
		accountinfomation:SetText("")
		accountinfomation:SizeToContents() -- Size the label to fit the text in it
		accountinfomation:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
		function RankList:OnSelect(index,value,data)
			if index > 4 then 
				index = index + 1
			end
			ARCBankGUI.AccountListDummy:SetText( "No Accounts!" )
			ARCBankGUI.AccountList:SetVisible(false)
			ARCBankGUI.AccountList:Clear()
			ARCBankGUI.AccountListTab = {}
			ARCBankGUI.CurrentChunk = 1
			ARCBankGUI.Ignore = false
			--MsgN("Rank "..tostring(index))
			net.Start( "ARCBank_Admin_SendAccounts" )
			net.WriteInt(index,ARCBANK_ACCOUNTBITRATE)
			net.SendToServer()
			accountinfomation:SetText("")
			ARCBankGUI.SelectedAccountRank = index
		end
		ARCBankGUI.AccountListDummy = vgui.Create( "DComboBox",AccountsContainer)
		ARCBankGUI.AccountListDummy:SetPos(10,40)
		ARCBankGUI.AccountListDummy:SetSize( 265, 20 )
		ARCBankGUI.AccountListDummy:SetText( "No Accounts!" )
		ARCBankGUI.AccountList= vgui.Create( "DComboBox",AccountsContainer)
		ARCBankGUI.AccountList:SetPos(10,40)
		ARCBankGUI.AccountList:SetSize( 265, 20 )
		ARCBankGUI.AccountList:SetText( "" )
		function ARCBankGUI.AccountList:OnSelect(index,value,data)
			ARCBankGUI.Ignore = false
			ARCBankGUI.CurrentChunk = 1
			ARCBankGUI.LogDownloaded = false
			ARCBankGUI.LogList:SetVisible(false)
			ARCBankGUI.Log = ""
			ARCBankGUI.LogOpen:SetText("Loading... (0%)")
			ARCBankGUI.SelectedAccount = ARCBankGUI.AccountListTab[index][ARCBANK_ID]
			accountinfomation:SetText("Filename: "..tostring(ARCBankGUI.AccountListTab[index][ARCBANK_ID]).."\nName: "..tostring(ARCBankGUI.AccountListTab[index][ARCBANK_NAME]).."\nBalance: "..tostring(ARCBankGUI.AccountListTab[index][ARCBANK_BALANCE]))
			accountinfomation:SizeToContents() -- Size the label to fit the text in it
			net.Start( "ARCBank_Admin_Send" )
			net.WriteInt(ARCBankGUI.SelectedAccountRank,ARCBANK_ACCOUNTBITRATE)
			net.WriteString(tostring(ARCBankGUI.AccountListTab[index][ARCBANK_ID]))
			net.SendToServer()
		end
		ARCBankGUI.AccountProgress = vgui.Create( "DProgress",AccountsContainer )
		ARCBankGUI.AccountProgress:SetPos( 10, 70 )
		ARCBankGUI.AccountProgress:SetSize( 265, 20 )
		ARCBankGUI.AccountProgress:SetFraction( 1 )
		
		local AccountAddMoney = vgui.Create( "DNumberWang", AccountsContainer )
		AccountAddMoney:SetPos( 10, 150 )
		AccountAddMoney:SetSize( 160, 20 )
		AccountAddMoney:SetValue( 0 )
		AccountAddMoney:SetMinMax( -1000000 , 1000000 )
		AccountAddMoney:SetDecimals(0)
		
		GiveTakeMoney = vgui.Create( "DButton", AccountsContainer )
		GiveTakeMoney:SetText( "Give/Take Money" )
		GiveTakeMoney:SetPos( 180, 150 )
		GiveTakeMoney:SetSize( 95, 20 )
		GiveTakeMoney.DoClick = function()
			RunConsoleCommand("arcbank","give_money",tostring(ARCBankGUI.SelectedAccountRank),tostring(ARCBankGUI.SelectedAccount),tostring(AccountAddMoney:GetValue()))
		end
		PropertySheet:AddSheet( "Server Log", LogContainer, "icon16/page_gear.png", false, false, "View the server log" )
		PropertySheet:AddSheet( "User Accounts", AccountsContainer, "icon16/folder_user.png", false, false, "Manage user accounts" )
		PropertySheet:AddSheet( "System Settings", SettingsContainer, "icon16/cog.png", false, false, "Change system settings" )
	end
	net.Receive( "ARCBank_Admin_SendAccounts", function(length)

	end)
	net.Receive( "ARCBank_Admin_Send", function(length)

	end)
	net.Receive( "ARCBank_Admin_GUI", function(length)
		local thing = net.ReadString()
		local tab = net.ReadTable()
		if thing == "settings" then
			local SettingsWindow = vgui.Create( "DFrame" )
			SettingsWindow:SetSize( 295,215 )
			SettingsWindow:Center()
			SettingsWindow:SetTitle( ARCBank.Msgs.AdminMenu.Settings )
			SettingsWindow:SetVisible( true )
			SettingsWindow:SetDraggable( true )
			SettingsWindow:ShowCloseButton( true )
			SettingsWindow:MakePopup()
		
		
		
		
			
			settings = tab
			local SettingsContainer = vgui.Create( "DPanel",SettingsWindow)
			SettingsContainer:SetPos( 5, 30 )
			SettingsContainer:SetSize( 285, 180 )
			local AList1= vgui.Create( "DComboBox",SettingsContainer)
			AList1:SetPos(10,10)
			AList1:SetSize( 265, 20 )
			AList1:SetText( ARCBank.Msgs.AdminMenu.ChooseSetting..":" )
			for k,v in SortedPairs(settings) do
				AList1:AddChoice(k)
			end
		
			local SettingSave = vgui.Create( "DButton", SettingsContainer )
			SettingSave:SetText( "Save settings" )
			SettingSave:SetPos( 10, 152 )
			SettingSave:SetSize( 265, 20 )
			SettingSave.DoClick = function()
				RunConsoleCommand( "arcbank","settings_save")
			end
			local SettingDesc = vgui.Create( "DLabel", SettingsContainer )
			SettingDesc:SetPos( 12, 35 ) -- Set the position of the label
			SettingDesc:SetText( ARCBank.Msgs.AdminMenu.ChooseSetting ) --  Set the text of the label
			SettingDesc:SetWrap(true)
			SettingDesc:SetSize( 265, 50 )
	--		SettingDesc:SizeToContents() -- Size the label to fit the text in it
			SettingDesc:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
			local SettingBool = vgui.Create( "DCheckBoxLabel", SettingsContainer )
			SettingBool:SetPos( 12, 92 )
			SettingBool:SetText( "Enable" )
			SettingBool:SetValue( 1 )
			SettingBool:SizeToContents()
			SettingBool:SetVisible(false)
			SettingBool:SetDark( 1 )
			local SettingNum = vgui.Create( "DNumberWang", SettingsContainer )
			SettingNum:SetPos( 10, 92 )
			SettingNum:SetSize( 265, 20 )
			SettingNum:SetValue( 1 )
			SettingNum:SetVisible(false)
			SettingNum:SetMinMax( 0 , 1000000 )
			SettingNum:SetDecimals(4)
			local SettingStr = vgui.Create( "DTextEntry", SettingsContainer )
			SettingStr:SetPos( 12,92 )
			SettingStr:SetTall( 20 )
			SettingStr:SetWide( 265 )
			SettingStr:SetVisible(false)
			SettingStr:SetEnterAllowed( true )
			local SettingsTabContainer = vgui.Create( "DPanel",SettingsContainer)
			SettingsTabContainer:SetPos(10,92)
			SettingsTabContainer:SetSize( 265, 50 )
			SettingsTabContainer:SetVisible(false)
			local SettingTab = vgui.Create( "DComboBox", SettingsTabContainer )
			SettingTab:SetPos( 0,0 )
			SettingTab:SetSize( 210, 20 )
			function SettingTab:OnSelect(index,value,data)
				SettingTab.Selection = value
			end
			local SettingTaba = vgui.Create( "DTextEntry", SettingsTabContainer )
			SettingTaba:SetPos( 0,30 )
			SettingTaba:SetTall( 20 )
			SettingTaba:SetWide( 210 )
			--SettingTaba:SetVisible(false)
			SettingTaba:SetEnterAllowed( true )
		
			local SettingRemove = vgui.Create( "DButton", SettingsTabContainer )
			SettingRemove:SetText( "Remove" )
			SettingRemove:SetPos( 210, 0 )
			SettingRemove:SetSize( 55, 20 )
			local SettingAdd = vgui.Create( "DButton", SettingsTabContainer )
			SettingAdd:SetText( "Add" )
			SettingAdd:SetPos( 210, 30)
			SettingAdd:SetSize( 55, 20 )
		
			function AList1:OnSelect(index,value,data)
				SettingDesc:SetText("Description:\n"..tostring(ARCBank.SettingsDesc[value]));
				--SettingDesc:SizeToContents();
					SettingBool.OnChange = function( pan, val ) end
					SettingStr.OnValueChanged = function( pan, val ) end
					SettingStr.OnEnter = function() end
					SettingNum.OnValueChanged = function( pan, val ) end
				if isnumber(settings[value]) then
					SettingBool:SetVisible(false)
					SettingNum:SetVisible(true)
					SettingStr:SetVisible(false)
					SettingsTabContainer:SetVisible(false)
					SettingNum:SetValue( settings[value] )
					SettingNum.OnValueChanged = function( pan, val )
						RunConsoleCommand( "arcbank","settings",value,tostring(val))
					end
				elseif istable(settings[value]) then
					SettingNum:SetVisible(false)
					SettingBool:SetVisible(false)
					SettingStr:SetVisible(false)
					SettingsTabContainer:SetVisible(true)
					SettingTab:Clear()
					SettingTab.Selection = ""
					for k,v in pairs(settings[value]) do
						SettingTab:AddChoice(v)
					end
					SettingAdd.DoClick = function()
						
						table.insert( settings[value], SettingTaba:GetValue() )
						string.Replace(SettingTaba:GetValue(), ",", "_")
						local s = ""
						for o,p in pairs(settings[value]) do
							if o > 1 then
								s = s..","..p
							else
								s = p
							end
						end
						RunConsoleCommand( "arcbank","settings",value,s)
						SettingTab:AddChoice(SettingTaba:GetValue())
						SettingTaba:SetValue("")
					end	
					SettingRemove.DoClick = function()
						table.RemoveByValue( settings[value], SettingTab.Selection )
						local s = ""
						for o,p in pairs(settings[value]) do
							if o > 1 then
								s = s..","..p
							else
								s = p
							end
						end
						SettingTab:Clear()
						for k,v in pairs(settings[value]) do
							SettingTab:AddChoice(v)
						end
						RunConsoleCommand( "arcbank","settings",value,s)
					end
				elseif isstring(settings[value]) then
					SettingNum:SetVisible(false)
					SettingBool:SetVisible(false)
					SettingStr:SetVisible(true)
					SettingsTabContainer:SetVisible(false)
					SettingStr:SetValue( settings[value] )
					SettingStr.OnValueChanged = function( pan, val )
						SettingStr:SetValue(tostring(val))
						RunConsoleCommand( "arcbank","settings",value,tostring(val))
					end
					SettingStr.OnEnter = function()
						SettingStr:SetValue(SettingStr:GetValue())
						RunConsoleCommand( "arcbank","settings",value,SettingStr:GetValue())
					end
				elseif isbool(settings[value]) then
					SettingNum:SetVisible(false)
					SettingBool:SetVisible(true)
					SettingStr:SetVisible(false)
					SettingsTabContainer:SetVisible(false)
					SettingBool:SetValue( ARCLib.BoolToNumber(settings[value]) )
					SettingBool.OnChange = function( pan, val )
						RunConsoleCommand( "arcbank","settings",value,tostring(val))
					end
				end
			end
			
			
			
			
			
			
			
		elseif thing == "logs" then
			local MainPanel = vgui.Create( "DFrame" )
			MainPanel:SetSize( 600,575 )
			MainPanel:Center()
			MainPanel:SetTitle( ARCBank.Msgs.AdminMenu.ServerLogs )
			MainPanel:SetVisible( true )
			MainPanel:SetDraggable( true )
			MainPanel:ShowCloseButton( true )
			MainPanel:MakePopup()
			
			Text = vgui.Create("DTextEntry", MainPanel) // The info text.
			Text:SetPos( 5, 30 ) -- Set the position of the label
			Text:SetSize( 590, 515 )
			Text:SetText("") --  Set the text of the label
			Text:SetMultiline(true)
			Text:SetEnterAllowed(false)
			Text:SetVerticalScrollbarEnabled(true)
			
			LogList= vgui.Create( "DComboBox",MainPanel)
			LogList:SetPos(5,550)
			LogList:SetSize( 590, 20 )
			LogList:SetText( ARCBank.Msgs.AdminMenu.NoLog )
			for i=1,#tab do 
				LogList:AddChoice(tab[i])
			end
			function LogList:OnSelect(index,value,data)
				ARCBank.AdminLog(value,false,function(data,per)
					if isnumber(data) then
						if data == ARCBANK_ERROR_DOWNLOADING then
							Text:SetText(ARCBank.Msgs.ATMMsgs.Loading.."(%"..math.Round(per*100)..")")
						else
							Text:SetText(ARCBANK_ERRORSTRINGS[data])
						end
					else
						Text:SetText(data)
					end
				end)
			end
		else
			local MainMenu = vgui.Create( "DFrame" )
			MainMenu:SetSize( 200, 150 )
			MainMenu:Center()
			MainMenu:SetTitle( ARCBank.Settings.name_long )
			MainMenu:SetVisible( true )
			MainMenu:SetDraggable( true )
			MainMenu:ShowCloseButton( true )
			MainMenu:MakePopup()
			local LogButton = vgui.Create( "DButton", MainMenu )
			LogButton:SetText( ARCBank.Msgs.AdminMenu.ServerLogs )
			LogButton:SetPos( 10, 30 )
			LogButton:SetSize( 180, 20 )
			LogButton.DoClick = function()
				RunConsoleCommand( "arcbank","admin_gui","logs")
			end
			local AccountsButton = vgui.Create( "DButton", MainMenu )
			AccountsButton:SetText( ARCBank.Msgs.AdminMenu.Accounts )
			AccountsButton:SetPos( 10, 60 )
			AccountsButton:SetSize( 180, 20 )
			AccountsButton.DoClick = function()	
				local AccountTable = {}
				local SelectedAccountIndex = 1
				local AccountMenu = vgui.Create( "DFrame" )
				AccountMenu:SetSize( 340, 210 )
				AccountMenu:Center()
				AccountMenu:SetTitle( ARCBank.Msgs.AdminMenu.Accounts )
				AccountMenu:SetVisible( true )
				AccountMenu:SetDraggable( true )
				AccountMenu:ShowCloseButton( true )
				AccountMenu:MakePopup()
				
				local SIDBox = vgui.Create( "DTextEntry", AccountMenu )
				local RankList= vgui.Create( "DComboBox",AccountMenu)
				local NameBox = vgui.Create( "DTextEntry", AccountMenu )
				RankList:SetPos(10,30)
				RankList:SetSize( 200, 20 )
				RankList:SetText( "" )
				for i = 1,4 do
					RankList:AddChoice(ARCBank.Msgs.AccountRank[i])
				end
				RankList:AddChoice(ARCBank.Msgs.AccountRank[6])
				RankList:AddChoice(ARCBank.Msgs.AccountRank[7])
			
				function RankList:OnSelect(index,value,data)
					if index > 4 then 
						index = index + 1
					end
					SelectedAccountIndex = index
				end
				
				
				
				local RankSButton = vgui.Create( "DButton", AccountMenu )
				RankSButton:SetText(ARCBank.Msgs.AdminMenu.SearchRank)
				RankSButton:SetPos( 210, 30 )
				RankSButton:SetSize( 120, 20 )
				RankSButton.DoClick = function()	
					ResultList:Clear()
					NameBox:SetValue("")
					SIDBox:SetValue("")
					local ii = 0
					for k,v in pairs(AccountTable) do
						if v.rank == SelectedAccountIndex then
							ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
							ii = ii + 1
						end
					end
					if ii > 512 then
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", ARCBank.Msgs.AdminMenu.Bigger.." 512" ) )
						ResultList:Clear()
					else
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", tostring(ii) ) )
					end
				end
				
				
				NameBox:SetPos( 10,60 )
				NameBox:SetWide( 200 )
				NameBox:SetTall( 20 )
				NameBox:SetEnterAllowed( true )
				NameBox:SetValue("")
				NameBox.OnEnter = function()
					RankList:SetValue("")
					SIDBox:SetValue("")
					ResultList:Clear()
					local ii = 0
					for k,v in pairs(AccountTable) do
						if string.find(string.lower(v.name), string.lower(NameBox:GetValue())) then
							ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
							ii = ii + 1
						end
					end
					if ii > 512 then
						ResultList:Clear()
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", ARCBank.Msgs.AdminMenu.Bigger.." 512" ) )
					else
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", tostring(ii) ) )
					end
				end
				local NameSButton = vgui.Create( "DButton", AccountMenu )
				NameSButton:SetText(ARCBank.Msgs.AdminMenu.SearchName)
				NameSButton:SetPos( 210, 60 )
				NameSButton:SetSize( 120, 20 )
				NameSButton.DoClick = NameBox.OnEnter
				
				SIDBox:SetPos( 10,90 )
				SIDBox:SetWide( 200 )
				SIDBox:SetTall( 20 )
				SIDBox:SetEnterAllowed( true )
				SIDBox:SetValue("")
				SIDBox.OnEnter = function()
					NameBox:SetValue("")
					RankList:SetValue("")
					ResultList:Clear()
					local ii = 0
					for k,v in pairs(AccountTable) do
						if v.isgroup then
							if v.owner == SIDBox:GetValue() || table.HasValue( v.members, SIDBox:GetValue() ) then
								ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
								ii = ii + 1
							end
						else
							if v.filename == "account_"..string.lower(string.gsub(SIDBox:GetValue(), "[^_%w]", "_")) then
								ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
								ii = ii + 1
							end
						end
					end
						
					if ii > 512 then
						ResultList:Clear()
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", ARCBank.Msgs.AdminMenu.Bigger.." 512" ) )
					else
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", tostring(ii) ) )
					end
				end
				local SIDSButton = vgui.Create( "DButton", AccountMenu )
				SIDSButton:SetText(ARCBank.Msgs.AdminMenu.SearchSID)
				SIDSButton:SetPos( 210, 90 )
				SIDSButton:SetSize( 120, 20 )
				SIDSButton.DoClick = SIDBox.OnEnter
				local ARCBank_AdminMenuBalOption = 1
				BalSelect= vgui.Create( "DComboBox",AccountMenu)
				BalSelect:SetPos(10,120)
				BalSelect:SetSize( 100, 20 )
				BalSelect:SetText(ARCBank.Msgs.AdminMenu.Bigger)
				function BalSelect:OnSelect(index,value,data)
					ARCBank_AdminMenuBalOption = index
				end
				BalSelect:AddChoice(ARCBank.Msgs.AdminMenu.Bigger)
				BalSelect:AddChoice(ARCBank.Msgs.AdminMenu.Smaller)
				BalSelect:AddChoice(ARCBank.Msgs.AdminMenu.Same)
				local Balnum = vgui.Create( "DNumberWang", AccountMenu )
				Balnum:SetPos( 110, 120 )
				Balnum:SetSize( 100, 20 )
				Balnum:SetValue( 1 )
				Balnum:SetMinMax( -100000000000000 , 100000000000000 )
				Balnum:SetDecimals(0)
				
				local BalButton = vgui.Create( "DButton", AccountMenu )
				BalButton:SetText(ARCBank.Msgs.AdminMenu.SearchBalance)
				BalButton:SetPos( 210, 120 )
				BalButton:SetSize( 120, 20 )
				BalButton.DoClick = function()
					NameBox:SetValue("")
					RankList:SetValue("")
					ResultList:Clear()
					local ii = 0
					for k,v in pairs(AccountTable) do
						if v.isgroup then
							if (ARCBank_AdminMenuBalOption == 1 && tonumber(v.money) > Balnum:GetValue())||(ARCBank_AdminMenuBalOption == 2 && tonumber(v.money) < Balnum:GetValue())||(ARCBank_AdminMenuBalOption == 3 && tonumber(v.money) == Balnum:GetValue()) then
								ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
								ii = ii + 1
							end
						else
							if (ARCBank_AdminMenuBalOption == 1 && tonumber(v.money) > Balnum:GetValue())||(ARCBank_AdminMenuBalOption == 2 && tonumber(v.money) < Balnum:GetValue())||(ARCBank_AdminMenuBalOption == 3 && tonumber(v.money) == Balnum:GetValue()) then
								ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
								ii = ii + 1
							end
						end
					end
						
					if ii > 512 then
						ResultList:Clear()
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", ARCBank.Msgs.AdminMenu.Bigger.." 512" ) )
					else
						ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", tostring(ii) ) )
					end
				end
				
				ResultList= vgui.Create( "DComboBox",AccountMenu)
				ResultList:SetPos(10,150)
				ResultList:SetSize( 320, 20 )
				ResultList:SetText("")
				function ResultList:OnSelect(index,value,data)
					PrintTable(AccountTable[data])
					local AccountPopup = vgui.Create( "DFrame" )
					AccountPopup:SetSize( 250, 215 )
					AccountPopup:Center()
					AccountPopup:SetTitle(value)
					AccountPopup:SetVisible( true )
					AccountPopup:SetDraggable( true )
					AccountPopup:ShowCloseButton( true )
					AccountPopup:MakePopup()
					local str = ARCBank.Msgs.AdminMenu.AccID..AccountTable[data].filename.."\n"..ARCBank.Msgs.AdminMenu.Name..AccountTable[data].name.."\n"..ARCBank.Msgs.AdminMenu.Rank..ARCBank.Msgs.AccountRank[AccountTable[data].rank].."\n"..ARCBank.Msgs.ATMMsgs.Balance..AccountTable[data].money
					if AccountTable[data].isgroup then
						local ply = ARCLib.GetPlayerBySteamID(AccountTable[data].owner)
						str = str.."\n"..ARCBank.Msgs.AdminMenu.Owner..ply:SteamID().." - "..ply:Nick()
						
						
						local AccountMembers = vgui.Create( "DButton", AccountPopup )
						AccountMembers:SetText(ARCBank.Msgs.AdminMenu.Members)
						AccountMembers:SetPos( 10, 125 )
						AccountMembers:SetSize( 230, 20 )
						AccountMembers.DoClick = function()
							local memstr = ""
							for k,v in pairs(AccountTable[data].members) do
								local ply = ARCLib.GetPlayerBySteamID(v)
								memstr = memstr..ply:SteamID().." - "..ply:Nick().."\n"
							end
							local MembersPopup = vgui.Create( "DFrame" )
							MembersPopup:SetSize( 250, 300 )
							MembersPopup:Center()
							MembersPopup:SetTitle(AccountTable[data].name.." - "..ARCBank.Msgs.AdminMenu.Members)
							MembersPopup:SetVisible( true )
							MembersPopup:SetDraggable( true )
							MembersPopup:ShowCloseButton( true )
							MembersPopup:MakePopup()
							MemText = vgui.Create("DTextEntry", MembersPopup) // The info text.
							MemText:SetPos( 5, 30 ) -- Set the position of the label
							MemText:SetSize( 240, 265 )
							MemText:SetText(memstr) --  Set the text of the label
							MemText:SetMultiline(true)
							MemText:SetEnterAllowed(false)
							MemText:SetVerticalScrollbarEnabled(true)
						end
						
					end
						
						
					local AccountDesc = vgui.Create( "DLabel", AccountPopup )
					AccountDesc:SetPos( 10, 30 ) -- Set the position of the label
					AccountDesc:SetText(str) --  Set the text of the label
					AccountDesc:SetWrap(true)
					AccountDesc:SetSize( 230, 90 )
					local AcountLog = vgui.Create( "DButton", AccountPopup )
					AcountLog:SetText(ARCBank.Msgs.ATMMsgs.ViewLog)
					AcountLog:SetPos( 10, 155 )
					AcountLog:SetSize( 230, 20 )
					AcountLog.DoClick = function()
						local AcountLogP = vgui.Create( "DFrame" )
						AcountLogP:SetSize( 600,545 )
						AcountLogP:Center()
						AcountLogP:SetTitle(value)
						AcountLogP:SetVisible( true )
						AcountLogP:SetDraggable( true )
						AcountLogP:ShowCloseButton( true )
						AcountLogP:MakePopup()
						
						AccText = vgui.Create("DTextEntry", AcountLogP) // The info text.
						AccText:SetPos( 5, 30 ) -- Set the position of the label
						AccText:SetSize( 590, 515 )
						AccText:SetText("") --  Set the text of the label
						AccText:SetMultiline(true)
						AccText:SetEnterAllowed(false)
						AccText:SetVerticalScrollbarEnabled(true)
						ARCBank.AdminLog(AccountTable[data].filename,AccountTable[data].isgroup,function(data,per)
							if isnumber(data) then
								if data == ARCBANK_ERROR_DOWNLOADING then
									AccText:SetText(ARCBank.Msgs.ATMMsgs.Loading.."(%"..math.Round(per*100)..")")
								else
									AccText:SetText(ARCBANK_ERRORSTRINGS[data])
								end
							else
								for k,v in pairs(player.GetAll()) do -- I don't know why I didn't think of this before...
									data = string.Replace(data,v:SteamID(),v:Nick())
								end
								AccText:SetText(data)
							end
						end)
					end
					
					local AccountAddMoney = vgui.Create( "DNumberWang", AccountPopup )
					AccountAddMoney:SetPos( 10, 185 )
					AccountAddMoney:SetSize( 120, 20 )
					AccountAddMoney:SetValue( 0 )
					AccountAddMoney:SetMinMax( -1000000 , 1000000 )
					AccountAddMoney:SetDecimals(0)
					local GiveTake = vgui.Create( "DButton", AccountPopup )
					GiveTake:SetText(ARCBank.Msgs.AdminMenu.GiveTakeMoney )
					GiveTake:SetPos( 130, 185 )
					GiveTake:SetSize( 110, 20 )
					GiveTake.DoClick = function()
						RunConsoleCommand("arcbank","give_money",AccountTable[data].filename,tostring(AccountTable[data].isgroup),tostring(AccountAddMoney:GetValue()))
					end
					
				end
				AccountProgress = vgui.Create( "DProgress",AccountMenu )
				AccountProgress:SetPos( 10, 180 )
				AccountProgress:SetSize( 320, 20 )
				AccountProgress:SetFraction(0)
				local RefreshButton = vgui.Create( "DButton", AccountMenu )
				RefreshButton:SetText(ARCBank.Msgs.AdminMenu.Refresh)
				RefreshButton:SetPos( 10, 180 )
				RefreshButton:SetSize( 320, 20 )
				RefreshButton:SetVisible(false)
				RefreshButton.DoClick = function()	
					AccountMenu:Close()
					AccountsButton.DoClick()
				end
				ARCBank.Admin_GetAllAccounts(function(data,per)
					if !IsValid(AccountProgress) || !IsValid(RefreshButton) then return end
					if isnumber(data) then
						if data > 0 then
							RefreshButton:SetText(ARCBANK_ERRORSTRINGS[data])
							RefreshButton:SetVisible(true)
						end
					else
						timer.Simple(math.random(),function() if IsValid(RefreshButton) then RefreshButton:SetVisible(true) end end)
						AccountTable = data
					end
					AccountProgress:SetFraction(per)
				end)
			end
			local SettingsButton = vgui.Create( "DButton", MainMenu )
			SettingsButton:SetText( ARCBank.Msgs.AdminMenu.Settings )
			SettingsButton:SetPos( 10, 90 )
			SettingsButton:SetSize( 180, 20 )
			SettingsButton.DoClick = function()	
				RunConsoleCommand( "arcbank","admin_gui","settings")
			end
			local CommandButton = vgui.Create( "DButton", MainMenu )
			CommandButton:SetText( ARCBank.Msgs.AdminMenu.Commands )
			CommandButton:SetPos( 10, 120 )
			CommandButton:SetSize( 180, 20 )
			CommandButton.DoClick = function()		
				local cmdlist = {"atm_save","atm_unsave","atm_respawn","atm_spawn"}
				local CommandFrame = vgui.Create( "DFrame" )
				CommandFrame:SetSize( 200*math.ceil(#cmdlist/8), 30+(30*math.Clamp(#cmdlist,0,8)) )
				CommandFrame:Center()
				CommandFrame:SetTitle(ARCBank.Msgs.AdminMenu.Commands)
				CommandFrame:SetVisible( true )
				CommandFrame:SetDraggable( true )
				CommandFrame:ShowCloseButton( true )
				CommandFrame:MakePopup()
				for i = 0,(#cmdlist-1) do
				
					local LogButton = vgui.Create( "DButton", CommandFrame )
					LogButton:SetText(tostring(ARCBank.Msgs.Commands[cmdlist[i+1]]))
					LogButton:SetPos( 10+(200*math.floor(i/8)), 30+(30*(i%8)) )
					LogButton:SetSize( 180, 20 )
					LogButton.DoClick = function()
					RunConsoleCommand( "arcbank",cmdlist[i+1])
					end
				end
			end
		
		end
	end)
end


