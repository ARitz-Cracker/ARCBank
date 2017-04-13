-- GUI for ARitz Cracker Bank (Clientside)
-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
local ARCBankGUI = ARCBankGUI or {}
ARCBankGUI.SelectedAccountRank = 0
ARCBankGUI.SelectedAccount = ""
ARCBankGUI.Log = ""
ARCBankGUI.LogDownloaded = false
ARCBankGUI.AccountListTab = {}

local ARCBank_AdminLogDisplay_Place = -1
local ARCBank_AdminLogDisplay = {}
local function NewLogWindow(account,t)
	local MainPanel = vgui.Create( "DFrame" )
	MainPanel:SetSize( 775,602 )
	MainPanel:Center()
	MainPanel:SetTitle( ARCBank.Msgs.AdminMenu.TransactionLog )
	MainPanel:SetVisible( true )
	MainPanel:SetDraggable( true )
	MainPanel:ShowCloseButton( true )
	MainPanel:MakePopup()
	
	
	local AppList = vgui.Create( "DListView",MainPanel )
	AppList:SetPos( 5, 30 ) -- Set the position of the label
	AppList:SetSize( 775-10,475 )
	
	AppList:SetMultiSelect( false )
	for i=1,10 do
		AppList:AddColumn(ARCBank.Msgs.AdminMenu.Logs[i])
	end
	AppList:SetSortable( true )
	local checkboxes = {}
	for i=0,9 do
	
		checkboxes[i] = vgui.Create( "DCheckBoxLabel", MainPanel )
		checkboxes[i]:SetPos( 5+math.floor(i/3)*200, 511+(i%3)*16 )
		checkboxes[i]:SetText( ARCBank.Msgs.AccountTransactions[2^i] )
		checkboxes[i]:SetValue( 1 )
		checkboxes[i]:SizeToContents()
		--checkbox:SetVisible(false)
		--checkbox:SetDark( 1 )
	end
	

	local AccountLabel = vgui.Create( "DLabel", MainPanel )
	AccountLabel:SetPos( 5, 562 )
	AccountLabel:SetText( ARCBank.Msgs.AdminMenu.AccID )
	AccountLabel:SizeToContents()
	local AccountEntry = vgui.Create( "DTextEntry", MainPanel )
	AccountEntry:SetPos( 5, 577 )
	AccountEntry:SetSize( 215, 20 )
	AccountEntry:SetText( account or "" )
	

	local TimeLabel = vgui.Create( "DLabel", MainPanel )
	TimeLabel:SetPos( 228, 562 )
	TimeLabel:SetText( ARCBank.Msgs.AdminMenu.StartTime )
	TimeLabel:SizeToContents()
	local TimeEntry = vgui.Create( "DTextEntry", MainPanel )
	TimeEntry:SetPos( 228, 577 )
	TimeEntry:SetSize( 215, 20 )
	
	t = tonumber(t)
	if t != nil then
		--if t < 86400 then
		--	t = 86400
		--end
		TimeEntry:SetText(os.date("%Y-%m-%d %H:%M:%S",t))
	else
		TimeEntry:SetText( "YYYY-MM-DD HH:MM:SS" )
	end
	local SearchProgress = vgui.Create( "DProgress",MainPanel )
	SearchProgress:SetPos( 450, 577 )
	SearchProgress:SetSize( 320, 20 )
	SearchProgress:SetVisible(false)
	
	--{string.match(version,"([0-9]*)-([0-9]*)-([0-9]*) ([0-9]*):([0-9]*):([0-9]*)")}
	local SearchButton = vgui.Create( "DButton", MainPanel )
	SearchButton:SetText( ARCBank.Msgs.ATMMsgs.ViewLog )
	SearchButton:SetPos( 450, 577 )
	SearchButton:SetSize( 320, 20 )
	SearchButton.DoClick = function()
		--RunConsoleCommand( "say", "Hi" )
		local dates = {string.match(TimeEntry:GetText(),"([0-9]*)-([0-9]*)-([0-9]*) ([0-9]*):([0-9]*):([0-9]*)")}
		for i=1,6 do
			dates[i] = tonumber(dates[i])
			if dates[i] == nil then
				Derma_Message( ARCBank.Msgs.AdminMenu.InvalidStartTime, ARCBank.Msgs.AdminMenu.TransactionLog, ARCBank.Msgs.ATMMsgs.OK )
				TimeEntry:SetText( "YYYY-MM-DD HH:MM:SS" )
				return
			end
		end
		if dates[7] != nil then
			Derma_Message( ARCBank.Msgs.AdminMenu.InvalidStartTime, ARCBank.Msgs.AdminMenu.TransactionLog, ARCBank.Msgs.ATMMsgs.OK )
			TimeEntry:SetText( "YYYY-MM-DD HH:MM:SS" )
			return
		end
		local datadata = {}
		datadata.year = dates[1]
		datadata.month = dates[2]
		datadata.day = dates[3]
		datadata.hour = dates[4]
		datadata.min = dates[5]
		datadata.sec = dates[6]
		SearchProgress:SetVisible(true)
		SearchProgress:SetFraction( 0 )
		SearchButton:SetVisible(false)
		local transaction_type = 0
		--transaction_type
		for i=0,9 do
			if checkboxes[i]:GetChecked() then
				transaction_type = bit.bor(transaction_type,2^i)
			end
		end
		AppList:Clear()
		local thetime = os.time( datadata )
		if thetime == nil then
			Derma_Message( ARCBank.Msgs.AdminMenu.InvalidStartTime, ARCBank.Msgs.AdminMenu.TransactionLog, ARCBank.Msgs.ATMMsgs.OK )
			TimeEntry:SetText( "YYYY-MM-DD HH:MM:SS" )
			return
		end
		ARCBank.GetLog(LocalPlayer(),AccountEntry:GetText(),thetime,transaction_type,function(err,progress,data)
			if not IsValid(MainPanel) then return end --Panel was closed
			if err == ARCBANK_ERROR_DOWNLOADING then
				SearchProgress:SetFraction( progress*0.4 )
			elseif err != ARCBANK_ERROR_NONE then
				SearchProgress:SetVisible(false)
				SearchButton:SetVisible(true)
				Derma_Message( ARCBANK_ERRORSTRINGS[err], ARCBank.Msgs.ATMMsgs.ViewLog, ARCBank.Msgs.ATMMsgs.OK )
			else
				data[#data + 1] = AppList
				data[#data + 1] = SearchProgress
				data[#data + 1] = SearchButton
				ARCBank_AdminLogDisplay[#ARCBank_AdminLogDisplay +1] = data
				if ARCBank_AdminLogDisplay_Place > 0 then
					ARCBank_AdminLogDisplay_Place = ARCBank_AdminLogDisplay_Place + 1
				else
					ARCBank_AdminLogDisplay_Place = 1
				end
			end
		end,true) 
	end

	--SearchProgress:SetFraction( 0.75 )
end


ARCLib.AddThinkFunc("ARCBank ShowAdminMenuLogs",function()
	if ARCBank_AdminLogDisplay_Place > 0 then
		--{ent,account,timestamp,transaction_type,callback,rawsearch}
		local logs = ARCBank_AdminLogDisplay[ARCBank_AdminLogDisplay_Place]
		local SearchButton = table.remove(logs)
		local SearchProgress = table.remove(logs)
		local AppList = table.remove(logs)
		local loglen = #logs
		for k,v in ipairs(logs) do
			if not IsValid(AppList) then break end
			local user1 = v.user1
			local user2 = v.user2
			local ply1 = ARCBank.GetPlayerByID(v.user1)
			local ply2 = ARCBank.GetPlayerByID(v.user2)
			if IsValid(ply1) then
				user1 = ply1:Nick()
			end
			if IsValid(ply2) then
				user2 = ply2:Nick()
			end
			AppList:AddLine( v.transaction_id, os.date("%Y-%m-%d %H:%M:%S",v.timestamp), ARCBank.Msgs.AccountTransactions[v.transaction_type], v.account1, v.account2, user1, user2, v.moneydiff, v.money or "", v.comment )
			if IsValid(SearchProgress) then
				SearchProgress:SetFraction( 0.4+(k/loglen*0.6) )
			end
			coroutine.yield()
		end
		if IsValid(SearchProgress) then
			SearchProgress:SetVisible(false)
		end
		if IsValid(SearchButton) then
			SearchButton:SetVisible(true)
		end
		
		ARCBank_AdminLogDisplay_Place = ARCBank_AdminLogDisplay_Place + 1
		if not ARCBank_AdminLogDisplay[ARCBank_AdminLogDisplay_Place] then
			ARCBank_AdminLogDisplay_Place = -1
			ARCBank_AdminLogDisplay = {}
		end
		collectgarbage()
		coroutine.yield()
	end
end)


ARCBank_TestLogWindow = NewLogWindow

local function NewAccountPropertiesWindow(account)
	
	local AccountPopup = vgui.Create( "DFrame" )
	AccountPopup:SetSize( 250, 245 )
	AccountPopup:Center()
	AccountPopup:SetTitle(account)
	AccountPopup:SetVisible( true )
	AccountPopup:SetDraggable( true )
	AccountPopup:ShowCloseButton( true )
	AccountPopup:MakePopup()
	
	ARCBank.GetAccountProperties(LocalPlayer(),account,function(errcode,accountdata,_)
		if errcode == ARCBANK_ERROR_NONE then
			if not IsValid(AccountPopup) then return end
			accountdata.isgroup = accountdata.rank > ARCBANK_GROUPACCOUNTS_
			AccountPopup:SetTitle(accountdata.name)
			ARCBank.GetBalance(_,accountdata.account,function(err,money,_)
				if errcode != ARCBANK_ERROR_NONE then
					Derma_Message( ARCBANK_ERRORSTRINGS[err], accountdata.name, ARCBank.Msgs.ATMMsgs.OK )
					return
				end
				if not IsValid(AccountPopup) then return end
				accountdata.money = money
				
				
				local str = ARCBank.Msgs.AdminMenu.AccID..accountdata.account.."\n"..ARCBank.Msgs.AdminMenu.Name..accountdata.name.."\n"..ARCBank.Msgs.AdminMenu.Rank..ARCBank.Msgs.AccountRank[accountdata.rank].."\n"..ARCBank.Msgs.ATMMsgs.Balance..accountdata.money
				if accountdata.isgroup then
					local ply = ARCBank.GetPlayerByID(accountdata.owner)
					str = str.."\n"..ARCBank.Msgs.AdminMenu.Owner..ARCBank.GetPlayerID(ply).." - "..ply:Nick()
					
					
					local AccountMembers = vgui.Create( "DButton", AccountPopup )
					AccountMembers:SetText(ARCBank.Msgs.AdminMenu.Members)
					AccountMembers:SetPos( 10, 125 )
					AccountMembers:SetSize( 230, 20 )
					AccountMembers.DoClick = function()
						local memstr = ""
						local MembersPopup = vgui.Create( "DFrame" )
						MembersPopup:SetSize( 250, 300 )
						MembersPopup:Center()
						MembersPopup:SetTitle(accountdata.name.." - "..ARCBank.Msgs.AdminMenu.Members)
						MembersPopup:SetVisible( true )
						MembersPopup:SetDraggable( true )
						MembersPopup:ShowCloseButton( true )
						MembersPopup:MakePopup()
						MemText = vgui.Create("DTextEntry", MembersPopup) // The info text.
						MemText:SetPos( 5, 30 ) -- Set the position of the label
						MemText:SetSize( 240, 265 )
						
						MemText:SetMultiline(true)
						MemText:SetEnterAllowed(false)
						MemText:SetVerticalScrollbarEnabled(true)
						ARCBank.GroupGetPlayers(LocalPlayer(),accountdata.account,function(err,data)
							if err == ARCBANK_ERROR_NONE then
								for k,v in ipairs(data) do
									local ply = ARCBank.GetPlayerByID(v)
									memstr = memstr..ARCBank.GetPlayerID(ply).." - "..ply:Nick().."\n"
								end
								if IsValid(MemText) then
									MemText:SetText(memstr)
								end
							else
								Derma_Message( ARCBANK_ERRORSTRINGS[err], accountdata.name, ARCBank.Msgs.ATMMsgs.OK )
							end
						end)
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
					NewLogWindow(accountdata.account,0)
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
					RunConsoleCommand("arcbank","give_money",accountdata.account,tostring(AccountAddMoney:GetValue()))
				end
				
				local AcountATM = vgui.Create( "DButton", AccountPopup )
				AcountATM:SetText(ARCBank.Msgs.AdminMenu.OpenATM)
				AcountATM:SetPos( 10, 215 )
				AcountATM:SetSize( 230, 20 )
				AcountATM.DoClick = function()
					local atm = LocalPlayer().ARCBank_ATM
					if IsValid(atm) then
						atm:EmitSoundTable(atm.ATMType.PressSound,65)
						ARCLib.PlaySoundOnOtherPlayers(table.Random(atm.ATMType.PressSound),atm,65)
						atm.Loading = true
						atm.Percent = 0
						ARCBank.GetAccountProperties(atm,accountdata.account,function(errcode,accountdata,ent)
							ent:AccountOptions(errcode,accountdata)
						end)
					else
						Derma_Message( ARCBank.Msgs.AdminMenu.NoATM, accountdata.name, ARCBank.Msgs.ATMMsgs.OK )
					end
				end
				
			end)
		else
			Derma_Message( ARCBANK_ERRORSTRINGS[errcode], account, ARCBank.Msgs.ATMMsgs.OK )
			AccountPopup:Close()
		end
	end)
end
ARCBank_TestAccountWindow = NewAccountPropertiesWindow

local SyslogTextBox
ARCLib.ReceiveBigMessage("arcbank_comm_admin_log_dl",function(err,per,data,ply)
	if not IsValid(SyslogTextBox) then return end
	if err == ARCLib.NET_DOWNLOADING then
		SyslogTextBox:SetText(ARCBank.Msgs.ATMMsgs.Loading.."(%"..math.Round(per*100)..")")
	elseif err == ARCLib.NET_COMPLETE then
		SyslogTextBox:SetText(data)
	else
		SyslogTextBox:SetText("Incomming arcbank_comm_admin_log_dl message errored! "..err)
	end
end)
net.Receive( "ARCBank_Admin_GUI", function(length)
	local thing = net.ReadString()
	local tab = net.ReadTable()
	if thing == "settings" then
		error("Tell aritz that this shouldn't happen, be sure to attach the FULL error reporst")
		
	elseif thing == "logs" then
		if IsValid(theSyslogList) then
			theSyslogList:GetParent():Close()
		end
	
		local MainPanel = vgui.Create( "DFrame" )
		MainPanel:SetSize( 600,575 )
		MainPanel:Center()
		MainPanel:SetTitle( ARCBank.Msgs.AdminMenu.ServerLogs )
		MainPanel:SetVisible( true )
		MainPanel:SetDraggable( true )
		MainPanel:ShowCloseButton( true )
		MainPanel:MakePopup()
		
		Text = vgui.Create("DTextEntry", MainPanel)
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
			RunConsoleCommand( "arcbank","admin_gui","logs",value)
		end
		SyslogTextBox = Text
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
			local callback
			local ResultList
			
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
			local ResultList = vgui.Create( "DComboBox",AccountMenu)
			local AccountProgress = vgui.Create( "DProgress",AccountMenu )
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
				--ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
				AccountProgress:SetFraction(0.33)
				ARCBank.AdminSearch(7,tostring(SelectedAccountIndex),callback)
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
				--ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
				AccountProgress:SetFraction(0.33)
				ARCBank.AdminSearch(8,NameBox:GetValue(),callback)
			end
			local NameSButton = vgui.Create( "DButton", AccountMenu )
			NameSButton:SetText(ARCBank.Msgs.AdminMenu.SearchName)
			NameSButton:SetPos( 210, 60 )
			NameSButton:SetSize( 120, 20 )
			NameSButton.DoClick = NameBox.OnEnter
			
			
			local ARCBank_AdminMenuSIDOption = 3
			SIDSelect= vgui.Create( "DComboBox",AccountMenu)
			SIDSelect:SetPos(10,90)
			SIDSelect:SetSize( 100, 20 )
			SIDSelect:SetText(ARCBank.Msgs.AdminMenu.AccountMemberOwner)
			function SIDSelect:OnSelect(index,value,data)
				ARCBank_AdminMenuSIDOption = index
			end
			SIDSelect:AddChoice(ARCBank.Msgs.AdminMenu.AccountOwner)
			SIDSelect:AddChoice(ARCBank.Msgs.AdminMenu.AccountMember)
			SIDSelect:AddChoice(ARCBank.Msgs.AdminMenu.AccountMemberOwner)
			
			SIDBox:SetPos( 110, 90 )
			SIDBox:SetSize( 100, 20 )
			SIDBox:SetEnterAllowed( true )
			SIDBox:SetValue("")
			SIDBox.OnEnter = function()
				NameBox:SetValue("")
				RankList:SetValue("")
				ResultList:Clear()
				--ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
				AccountProgress:SetFraction(0.33)
				ARCBank.AdminSearch(ARCBank_AdminMenuSIDOption,SIDBox:GetValue(),callback)
			end
			local SIDSButton = vgui.Create( "DButton", AccountMenu )
			SIDSButton:SetText(ARCBank.Msgs.AdminMenu.SearchUser)
			SIDSButton:SetPos( 210, 90 )
			SIDSButton:SetSize( 120, 20 )
			SIDSButton.DoClick = SIDBox.OnEnter
			
			
			local ARCBank_AdminMenuBalOption = 2
			BalSelect= vgui.Create( "DComboBox",AccountMenu)
			BalSelect:SetPos(10,120)
			BalSelect:SetSize( 100, 20 )
			BalSelect:SetText(ARCBank.Msgs.AdminMenu.Bigger)
			function BalSelect:OnSelect(index,value,data)
				ARCBank_AdminMenuBalOption = index
			end
			BalSelect:AddChoice(ARCBank.Msgs.AdminMenu.Same)
			BalSelect:AddChoice(ARCBank.Msgs.AdminMenu.Bigger)
			BalSelect:AddChoice(ARCBank.Msgs.AdminMenu.Smaller)
			
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
				--ResultList:AddChoice(v.name.." - "..ARCBank.Msgs.AccountRank[5*ARCLib.BoolToNumber(v.isgroup)],k)
				AccountProgress:SetFraction(0.33)
				ARCBank.AdminSearch(ARCBank_AdminMenuBalOption+3,tostring(Balnum:GetValue()),callback)
			end
			
			
			ResultList:SetPos(10,150)
			ResultList:SetSize( 320, 20 )
			ResultList:SetText("")
			function ResultList:OnSelect(index,value,data)
				NewAccountPropertiesWindow(data)
			end
			
			AccountProgress:SetPos( 10, 180 )
			AccountProgress:SetSize( 320, 20 )
			AccountProgress:SetFraction(1)
			
			callback = function(err,tab)
				if not IsValid(AccountProgress) then return end
				if err == ARCBANK_ERROR_NONE then
					AccountProgress:SetFraction(1)
					for k,v in ipairs(tab) do
						local name = ""
						if string.sub(v,1,1) == "_" then
							name = ARCLib.basexx.from_base32(string.upper(string.sub(v,2,#v-1)))
							local ply = ARCBank.GetPlayerByID(name)
							if IsValid(ply) then
								name = ply:Nick()
							end
							name = name.." ("..ARCBank.Msgs.AccountRank[0]..")"
						else
							name = ARCLib.basexx.from_base32(string.upper(string.sub(v,1,#v-1)))
							name = name.." ("..ARCBank.Msgs.AccountRank[5]..")"
						end
						ResultList:AddChoice(name,v)
					end
					ResultList:SetValue(string.Replace( ARCBank.Msgs.AdminMenu.Results, "%NUM%", tostring(#tab) ) )
				else
					AccountProgress:SetFraction(0)
					Derma_Message( ARCBANK_ERRORSTRINGS[err], ARCBank.Msgs.AdminMenu.Accounts, ARCBank.Msgs.ATMMsgs.OK )
				end
			end
		end
		local SettingsButton = vgui.Create( "DButton", MainMenu )
		SettingsButton:SetText( ARCBank.Msgs.AdminMenu.Settings )
		SettingsButton:SetPos( 10, 90 )
		SettingsButton:SetSize( 180, 20 )
		SettingsButton.DoClick = function()	
			ARCLib.AddonConfigMenu("ARCBank","arcbank")
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

