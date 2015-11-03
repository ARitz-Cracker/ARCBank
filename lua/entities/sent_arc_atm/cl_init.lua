-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
include('shared.lua')
local icons_rank = {}
icons_rank[0] = "hand_fuck"
icons_rank[1] = "user"
icons_rank[2] = "medal_bronze_1"
icons_rank[3] = "medal_silver_3"
icons_rank[4] = "medal_gold_2"
icons_rank[5] = "hand_fuck"
icons_rank[6] = "group"
icons_rank[7] = "group_add"
ENT.MsgBox = {}
ARCBank.ATM_DarkTheme = false
net.Receive( "ARCBank CustomATM", function(length)
	local atm = net.ReadEntity()
	if IsValid(atm) then
		atm.ATMType = util.JSONToTable(net.ReadString())
		for i=1,#atm.ATMType.HackedWelcomeScreen do
			atm.hackedscrs[i] = surface.GetTextureID(atm.ATMType.HackedWelcomeScreen[i])
		end
		atm.hackedscrs[#atm.hackedscrs+1] = surface.GetTextureID(atm.ATMType.WelcomeScreen)
	end
end)
function ENT:Initialize()
	net.Start("ARCBank CustomATM")
	net.WriteEntity(self.Entity)
	net.SendToServer()
	self.hackedscrs = {surface.GetTextureID("arc/atm_base/screen/welcome_new")}
	self.LastCheck = CurTime()
	self.HackRecover = CurTime() + 6
	

	self.LogTable = {}
	self.LogPage = 1
	self.LogPageMax = 1
	
	self.Loading = false
	self.Percent = 0
	self.Resolutionx = 278
	self.Resolutiony = 315
	self.MoneyMsg = 0
	self.UseDelay = CurTime() 

	self.MsgBox = {}
	self.MsgBox.Title = ""
	self.MsgBox.Text = ""
	self.MsgBox.TitleIcon = ""
	self.MsgBox.TextIcon = ""
	self.MsgBox.Type = 0
	self.MsgBox.GreenFunc = function() self.MsgBox.Type = 0 end
	self.MsgBox.RedFunc = function() self.MsgBox.Type = 0 end
	self.MsgBox.YellowFunc = function() self.MsgBox.Type = 0 end
	
	self.RequestedAccount = ""
	--self.ActiveAccount = {}
	
	self.BackFunc = function() self:HomeScreen() end
	
	self.InputFunc = function(num) MsgN("Inputted: "..num) end
	
	self.InputNum = 0
	
	self.InputSID = ""
	
	self.OnHomeScreen = true
	
	self.Title = ""
	
	self.TitleText = ""
	
	self.Page = 0
	--Screen buttons start on 13
	self.ScreenOptions = {}
	self.buttonpos = {}
	self:UpdateList()
	--Special thanks to swep construction kit
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
	self.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
	

end
function ENT:EnableInput(usesteamid,callback)
	self.InputNum = 0
	
	self.InputFunc = callback
	self.InputtingNumber = true
	self.InputSteamID = usesteamid
end
function ENT:UpdateList()
	self.Page = 0
	if table.maxn(self.ScreenOptions) < 8 then
		self.ScreenOptions[8] = {}
		if self.OnHomeScreen then
			self.ScreenOptions[8].icon = "cross"
			self.ScreenOptions[8].text = ARCBank.Msgs.ATMMsgs.Exit
		else
			self.ScreenOptions[8].icon = "arrow_down"
			self.ScreenOptions[8].text = ARCBank.Msgs.ATMMsgs.Back
		end
		
		self.ScreenOptions[8].func = function() self:PushCancel() end
	else
		local i = 1
		
		local doublebackcmd = {}
		if self.OnHomeScreen then
			doublebackcmd.icon = "cross"
			doublebackcmd.text = ARCBank.Msgs.ATMMsgs.Exit
		else
			doublebackcmd.icon = "arrow_down"
			doublebackcmd.text = ARCBank.Msgs.ATMMsgs.Back
		end
		
		doublebackcmd.func = function() self:PushCancel() end
		
		
		local nextcmd = {}
		nextcmd.icon = "arrow_right"
		nextcmd.text = ARCBank.Msgs.ATMMsgs.More
		nextcmd.func = function() 
			self.Page = self.Page + 1
		end
		local backcmd = {}
		backcmd.icon = "arrow_left"
		backcmd.text = ARCBank.Msgs.ATMMsgs.Back
		backcmd.func = function() 
			self.Page = self.Page - 1
		end
		table.insert(self.ScreenOptions, 7, nextcmd ) 
		table.insert(self.ScreenOptions, 8, doublebackcmd ) 
		while i <= (math.ceil(#self.ScreenOptions/8)-1) do -- Eh, for some reason I just feel safer doing this in a while loop
			if self.ScreenOptions[8+(i*8)] then
				table.insert(self.ScreenOptions, 7+(i*8), nextcmd ) 
			end
			table.insert(self.ScreenOptions, 8+(i*8), backcmd ) 
			i = i + 1
		end
	end
end


local function ENT_AccountOptions(accountdata,ent)
	ent.Loading = false
	if isnumber(accountdata) then
		ent:ThrowError(accountdata)
	else
		ent.OnHomeScreen = false
		ent.Title = accountdata.name
		ent.TitleText = ARCBank.Msgs.ATMMsgs.Balance.." "..ARCLib.MoneyLimit(accountdata.money)
		ent.TitleIcon = icons_rank[accountdata.rank]
		
		ent.ScreenOptions = {}
		ent.ScreenOptions[1] = {}
		ent.ScreenOptions[1].text = ARCBank.Msgs.ATMMsgs.Withdrawal
		ent.ScreenOptions[1].icon = "money_delete"
		ent.ScreenOptions[1].func = function() 
			ent.MoneyTake = true
			ent:MoneyOptions()
			ent.TitleIcon = "money_delete"
		end
		
		ent.ScreenOptions[2] = {}
		ent.ScreenOptions[2].text = ARCBank.Msgs.ATMMsgs.Deposit
		ent.ScreenOptions[2].icon = "money_add"
		ent.ScreenOptions[2].func = function() 
			ent.MoneyTake = false
			ent:MoneyOptions()
			ent.TitleIcon = "money_add"
		end
		
		ent.ScreenOptions[3] = {}
		ent.ScreenOptions[3].text = ARCBank.Msgs.ATMMsgs.Transfer
		ent.ScreenOptions[3].icon = "money_in_envelope"
		ent.ScreenOptions[3].func = function() 
			ent:PlayerSearch(addgroup)
		end
		
		ent.ScreenOptions[4] = {}
		ent.ScreenOptions[4].text = ARCBank.Msgs.ATMMsgs.ViewLog
		ent.ScreenOptions[4].icon = "file_extension_log"
		ent.ScreenOptions[4].func = function() 
			ent.Loading = true
			local accn = ""
			if accountdata.isgroup then
				accn = accountdata.name
			end
			ARCBank.Log(accn,ent,function(data,per,_)
				if !IsValid(ent) then return end
				if data == ARCBANK_ERROR_DOWNLOADING then
					ent.Percent = per*0.5
				elseif isnumber(data) then
					ent.Percent = 0
					ent.Loading = false
					ent:ThrowError(data)
				else
					data = string.Replace(data,"STEAM_0:0:0",LocalPlayer():Nick())
					for k,v in pairs(player.GetAll()) do -- I don't know why I didn't think of this before...
						data = string.Replace(data,v:SteamID(),v:Nick())
					end
					ARCLib.FitTextRealtime(data,"ARCBankATMSmall",274,function(per,tab)
						if !IsValid(ent) then return end
						if per == 1 then
							ent.Percent = 1
							ent.LogTable = tab
							ent.LogPageMax = math.ceil(#ent.LogTable/20)
							ent.LogPage = ent.LogPageMax
							timer.Simple(math.Rand(1.5,3),function()
								ent.Percent = 0
								ent.Loading = false
							end)
						else
							ent.Percent = 0.5 + per*0.5
						end
					end)
					
					
					--[[
					ent.LogTable = ARCLib.FitText(data,"ARCBankATMSmall",274)
					
					ent.LogPageMax = math.ceil(#ent.LogTable/20)
					ent.LogPage = ent.LogPageMax
					ent.Percent = 0
					ent.Loading = false
					]]
				end
			end)
		end
		
		if accountdata.isgroup then
			PrintTable(accountdata.members)
			ent.ScreenOptions[5] = {}
			ent.ScreenOptions[5].text = ARCBank.Msgs.ATMMsgs.RemovePlayerGroup
			ent.ScreenOptions[5].icon = "user_delete"
			ent.ScreenOptions[5].func = function() 
				ent:PlayerGroup(accountdata.members)
			end
			
			ent.ScreenOptions[6] = {}
			ent.ScreenOptions[6].text = ARCBank.Msgs.ATMMsgs.AddPlayerGroup
			ent.ScreenOptions[6].icon = "user_add"
			ent.ScreenOptions[6].func = function() 
				ent:PlayerSearch(true)
			end
			
			ent.ScreenOptions[7] = {}
			ent.ScreenOptions[7].text = ARCBank.Msgs.ATMMsgs.CloseAccount
			ent.ScreenOptions[7].icon = "bin"
			ent.ScreenOptions[7].func = function() 
				
				ent:Question(string.Replace(ARCBank.Msgs.ATMMsgs.CloseNotice,"ARCBank",ARCBank.Settings.name),function()
					ent.Loading = true
					ARCBank.DeleteAccount(ent.RequestedAccount,ent,function(err,ent) 
						ent:HomeScreen()
						ent.Loading = false
						ent:ThrowError(err) 
					end)
				end)
			end
		end
		ent.BackFunc = function() ent:HomeScreen() end
		
		ent:UpdateList()
	end
end
function ENT:PlayerSearch(addgroup)
	local plys = player.GetAll()
	self.ScreenOptions = {}
	for i = 1,#plys do 
		self.ScreenOptions[i] = {}
		self.ScreenOptions[i].text = plys[i]:Nick().."\n"..string.Replace(plys[i]:SteamID(),"STEAM_","")
		if addgroup then
			self.ScreenOptions[i].icon = "user_add"
			self.ScreenOptions[i].func = function() 
				self.Loading = true
				ARCBank.EditPlayerGroup(self.RequestedAccount,plys[i]:SteamID(),true,self.Entity,function(err,ent) 
					ent.Loading = false
					ent:ThrowError(err) 
				end)
			end
		else
			self.ScreenOptions[i].icon = "user"
			self.ScreenOptions[i].func = function() 
				--Clicked one of the players

				self.Loading = true
				ARCBank.GroupList(plys[i]:SteamID(),self.Entity,function(data,per,_)
					if data == ARCBANK_ERROR_DOWNLOADING then
						self.Percent = per
					elseif isnumber(data) then
						self.Percent = 0
						self.Loading = false
						self:ThrowError(data)
					else
						self.OnHomeScreen = false
						self.ScreenOptions = {}
						self.ScreenOptions[1] = {}
						self.ScreenOptions[1].text = ARCBank.Msgs.ATMMsgs.PersonalAccount
						self.ScreenOptions[1].icon = "user"
						self.ScreenOptions[1].func = function()
							self:EnableInput(false,function(nummm)
								self.Loading = true
								ARCBank.TransferFunds(plys[i]:SteamID(),self.RequestedAccount,"",nummm,"ATM Transfer",self.Entity,function(err,ent) 
									ent:ThrowError(err) 
									ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
								end)
							end)
							
							
						end
						
						for ii = 1,#data do
							self.ScreenOptions[ii+1] = {}
							self.ScreenOptions[ii+1].text = data[ii]
							self.ScreenOptions[ii+1].icon = "group"
							self.ScreenOptions[ii+1].func = function()
								self:EnableInput(false,function(nummm)
									self.Loading = true
									ARCBank.TransferFunds(plys[i]:SteamID(),self.RequestedAccount,self.ScreenOptions[ii+1].text,nummm,"ATM Transfer",self.Entity,function(err,ent) 
										ent:ThrowError(err) 
										ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
									end)
								end)
								
								
							end
						end
						
						self.BackFunc = function() 
							self.Loading = true
							ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
						end
						self:UpdateList()
						
						
						self.Percent = 0
						self.Loading = false
					end
				end)
				
				
				
				
				--[[
				ARCBank.TransferFunds(plys[i]:SteamID(),self.RequestedAccount,accto,amount,"ATM Transfer",self.Entity,function(err,ent) 
					ent.Loading = false
					ent:ThrowError(err) 
				end)
				]]
			end
		end
	end
	
	self.ScreenOptions[#plys+1] = {}
	self.ScreenOptions[#plys+1].text = ARCBank.Msgs.ATMMsgs.OfflinePlayer
	self.ScreenOptions[#plys+1].icon = "textfield"
	self.ScreenOptions[#plys+1].func = function() 
		self.InputSID = ""
		local function ENT_SID_Yes()
			self.InputSID = "STEAM_0:1:"
			self.MsgBox.Type = 0
		end
		local function ENT_SID_No()
			self.InputSID = "STEAM_0:0:"
			self.MsgBox.Type = 0
		end
		self:Question(ARCBank.Msgs.ATMMsgs.SIDAsk,ENT_SID_Yes,ENT_SID_No)
		self:EnableInput(true,function(nummmmm)
			self.Loading = true
			if addgroup then
				ARCBank.EditPlayerGroup(self.RequestedAccount,self.InputSID..nummmmm,true,self.Entity,function(err,ent) 
					ent.Loading = false
					ent:ThrowError(err) 
				end)
			else
				local ENTSTEAMID = self.InputSID..nummmmm
				

				self.Loading = true
				ARCBank.GroupList(ENTSTEAMID,self.Entity,function(data,per,_)
					if data == ARCBANK_ERROR_DOWNLOADING then
						self.Percent = per
					elseif isnumber(data) then
						self.Percent = 0
						self.Loading = false
						self:ThrowError(data)
					else
						self.OnHomeScreen = false
						self.ScreenOptions = {}
						self.ScreenOptions[1] = {}
						self.ScreenOptions[1].text = ARCBank.Msgs.ATMMsgs.PersonalAccount
						self.ScreenOptions[1].icon = "user"
						self.ScreenOptions[1].func = function()
							self:EnableInput(false,function(nummm)
								self.Loading = true
								ARCBank.TransferFunds(ENTSTEAMID,self.RequestedAccount,"",nummm,"ATM Transfer",self.Entity,function(err,ent) 
									ent:ThrowError(err) 
									ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
								end)
							end)
							
							
						end
						
						for ii = 1,#data do
							self.ScreenOptions[ii+1] = {}
							self.ScreenOptions[ii+1].text = data[ii]
							self.ScreenOptions[ii+1].icon = "group"
							self.ScreenOptions[ii+1].func = function()
								self:EnableInput(false,function(nummm)
									self.Loading = true
									ARCBank.TransferFunds(ENTSTEAMID,self.RequestedAccount,self.ScreenOptions[ii].text,nummm,"ATM Transfer",self.Entity,function(err,ent) 
										ent:ThrowError(err) 
										ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
									end)
								end)
								
								
							end
						end
						
						self.BackFunc = function() 
							self.Loading = true
							ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
						end
						self:UpdateList()
						
						
						self.Percent = 0
						self.Loading = false
					end
				end)
			
			
			
			end
		end)
	end
	
	self.BackFunc = function() 
		self.Loading = true
		ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
	end
	self:UpdateList()
end
function ENT:PlayerGroup(members)
	self.ScreenOptions = {}
	for i = 1,#members do 
		local ply = ARCLib.GetPlayerBySteamID(members[i])
		self.ScreenOptions[i] = {}
		self.ScreenOptions[i].text = tostring(ply:Nick()).."\n"..string.Replace(tostring(ply:SteamID()),"STEAM_","")
		self.ScreenOptions[i].icon = "user_delete"
		self.ScreenOptions[i].func = function() 
			self.Loading = true
			ARCBank.EditPlayerGroup(self.RequestedAccount,ply:SteamID(),false,self.Entity,function(err,ent) 
				ent:ThrowError(err)
				ent.Loading = false
			end)
		end
	end
	
	self.BackFunc = function() 
		self.Loading = true
		ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions)
	end
	self:UpdateList()
end
net.Receive( "ARCATM_COMM_CASH", function(length,ply)
	local atm = net.ReadEntity() 
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	atm.Loading = true
	ARCBank.GetAccountInformation(atm.RequestedAccount,atm,ENT_AccountOptions)
	atm:ThrowError(errcode)
end)
function ENT:MoneyOptions()
	self.ScreenOptions = {}
	
	for i = 1,3 do
		self.ScreenOptions[i*2] = {}
		self.ScreenOptions[i*2].text = tostring(2^(i-1)*50)
		self.ScreenOptions[i*2].icon = "money"
		self.ScreenOptions[i*2].func = function() 
			self.Loading = true
			timer.Simple(math.random(),function()
				net.Start( "ARCATM_COMM_CASH" )
				net.WriteEntity( self )
				net.WriteString(self.RequestedAccount)
				net.WriteBit(self.MoneyTake)
				net.WriteUInt(2^(i-1)*50,32)
				net.SendToServer()
			end)
		end
		self.ScreenOptions[i*2-1] = {}
		self.ScreenOptions[i*2-1].text = tostring(i*1000)
		self.ScreenOptions[i*2-1].icon = "money"
		self.ScreenOptions[i*2-1].func = function() 
			self.Loading = true
			timer.Simple(math.random(),function()
				net.Start( "ARCATM_COMM_CASH" )
				net.WriteEntity( self )
				net.WriteString(self.RequestedAccount)
				net.WriteBit(self.MoneyTake)
				net.WriteUInt(i*1000,32)
				net.SendToServer()
			end)
		end
	end
	self.ScreenOptions[7] = {}
	self.ScreenOptions[7].text = ARCBank.Msgs.ATMMsgs.OtherNumber
	self.ScreenOptions[7].icon = "textfield"
	self.ScreenOptions[7].func = function() --Yo dawg, I herd you liked functions.
		self:EnableInput(false,function(nummm)
			self.Loading = true
			timer.Simple(math.random(),function()
				net.Start( "ARCATM_COMM_CASH" )
				net.WriteEntity( self )
				net.WriteString(self.RequestedAccount)
				net.WriteBit(self.MoneyTake)
				net.WriteUInt(nummm,32)
				net.SendToServer()
			end)
		end)
	end 
	self.BackFunc = function() 
		self.Loading = true
		ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions) 
	end
	self:UpdateList()
end
local function ENT_DoUpgrade(errcode,ent)
	ent:ThrowError(errcode)
	ent.Loading = false
	ent:HomeScreen()
end

local function ENT_AccountUpgrade(errcode,ent)
	ent.Loading = false
	if errcode == ARCBANK_ERROR_NAME_DUPE then
		ent:Question(ARCBank.Msgs.ATMMsgs.UpgradeAccount,function()
			ent.Loading = true
			ARCBank.UpgradeAccount(ent.RequestedAccount,ent,ENT_DoUpgrade)
		end)
	else
		ent:ThrowError(errcode)
		ent:HomeScreen()
	end
end

function ENT:HomeScreen()
	self.OnHomeScreen = true
	self.Title = ARCBank.Settings.name_long
	self.TitleText = string.Replace(ARCBank.Msgs.ATMMsgs.MainMenu,"%PLAYERNAME%",LocalPlayer():Nick())
	self.TitleIcon = "atm"
	self.ScreenOptions = {}
	self.ScreenOptions[1] = {}
	self.ScreenOptions[1].text = ARCBank.Msgs.ATMMsgs.GroupInformation
	self.ScreenOptions[1].icon = "group"
	self.ScreenOptions[1].func = function() 
		self.Loading = true
		ARCBank.GroupList(LocalPlayer():SteamID(),self.Entity,function(data,per,_)
			if data == ARCBANK_ERROR_DOWNLOADING then
				self.Percent = per
			elseif isnumber(data) then
				self.Percent = 0
				self.Loading = false
				self:ThrowError(data)
			else
				if #data == 0 then
					self:ThrowError(ARCBANK_ERROR_PLAYER_FOREVER_ALONE)
				else
					self.OnHomeScreen = false
					self.ScreenOptions = {}
					for i = 1,#data do
						self.ScreenOptions[i] = {}
						self.ScreenOptions[i].text = data[i]
						self.ScreenOptions[i].icon = "group"
						self.ScreenOptions[i].func = function()
							self.Loading = true
							self.RequestedAccount = self.ScreenOptions[i].text
							ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions)
						end
					end
					
					self.BackFunc = function() self:HomeScreen() end
					self:UpdateList()
				end
				
				self.Percent = 0
				self.Loading = false
			end
		end)
	end
	
	self.ScreenOptions[2] = {}
	self.ScreenOptions[2].text = ARCBank.Msgs.ATMMsgs.PersonalInformation
	self.ScreenOptions[2].icon = "user"
	self.ScreenOptions[2].func = function()
		self.Loading = true
		self.RequestedAccount = ""
		ARCBank.GetAccountInformation(self.RequestedAccount,self.Entity,ENT_AccountOptions)
	end
	
	self.ScreenOptions[3] = {}
	self.ScreenOptions[3].text = ARCBank.Msgs.ATMMsgs.GroupUpgrade
	self.ScreenOptions[3].icon = "group_edit"
	self.ScreenOptions[3].func = function() 
			self.Loading = true
			ARCBank.GroupList(LocalPlayer():SteamID(),self.Entity,function(data,per,_)
				if data == ARCBANK_ERROR_DOWNLOADING then
					self.Percent = per
				elseif isnumber(data) then
					self.Percent = 0
					self.Loading = false
					self:ThrowError(data)
				else
					self.OnHomeScreen = false
					self.ScreenOptions = {}
					for i = 1,#data do
						self.ScreenOptions[i] = {}
						self.ScreenOptions[i].text = data[i]
						self.ScreenOptions[i].icon = "group"
						self.ScreenOptions[i].func = function()
							self.Loading = true
							self.RequestedAccount = self.ScreenOptions[i].text
							ARCBank.CreateAccount(self.RequestedAccount,self.Entity,ENT_AccountUpgrade)
						end
					end
					self.ScreenOptions[#data+1] = {}
					self.ScreenOptions[#data+1].text = ARCBank.Msgs.ATMMsgs.CreateGroupAccount
					self.ScreenOptions[#data+1].icon = "group_edit"
					self.ScreenOptions[#data+1].func = function()
						Derma_StringRequest( ARCBank.Msgs.ATMMsgs.CreateGroupAccount, "Enter name", "", function(text)
							self:EmitSoundTable(self.ATMType.PressSound,65)
							ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
							self.Loading = true
							self.RequestedAccount = text
							ARCBank.CreateAccount(self.RequestedAccount,self.Entity,ENT_AccountUpgrade)
						end) 
					end
					
					
					self.BackFunc = function() self:HomeScreen() end
					self:UpdateList()
					
					
					self.Percent = 0
					self.Loading = false
				end
			end)
	end
	
	self.ScreenOptions[4] = {}
	self.ScreenOptions[4].text = ARCBank.Msgs.ATMMsgs.PersonalUpgrade
	self.ScreenOptions[4].icon = "user_edit"
	self.ScreenOptions[4].func = function() 
		self.Loading = true
		self.RequestedAccount = ""
		ARCBank.CreateAccount(self.RequestedAccount,self.Entity,ENT_AccountUpgrade)
	
	end
	
	
	self.ScreenOptions[9] = {}
	self.ScreenOptions[9].text = ARCBank.Msgs.ATMMsgs.Fullscreen
	self.ScreenOptions[9].icon = "lcd_tv"
	self.ScreenOptions[9].func = function()
		LocalPlayer().ARCBank_FullScreen = !LocalPlayer().ARCBank_FullScreen
		if LocalPlayer().ARCBank_FullScreen then
			RunConsoleCommand("arcbank","fullscreenmode","true")
			gui.EnableScreenClicker(true) 
		else
			RunConsoleCommand("arcbank","fullscreenmode","false")
			gui.EnableScreenClicker(false) 
		end
	end
	self.ScreenOptions[10] = {}
	self.ScreenOptions[10].text = ARCBank.Msgs.ATMMsgs.DarkMode
	self.ScreenOptions[10].icon = "color_picker_switch"
	self.ScreenOptions[10].func = function()
		ARCBank.ATM_DarkTheme = !ARCBank.ATM_DarkTheme
		RunConsoleCommand("arcbank","darktheme",tostring(ARCBank.ATM_DarkTheme))
	end
	self.ScreenOptions[15] = {}
	self.ScreenOptions[15].text = "ARitz Cracker Bank\n"..ARCBank.Version.." - "..ARCBank.Update
	self.ScreenOptions[15].icon = "help"
	self.ScreenOptions[15].func = function()
		self.Loading = true
		ARCLib.FitTextRealtime(ARCBank.About,"ARCBankATMSmall",274,function(per,tab)
			if !IsValid(self) then return end
			if per == 1 then
				self.Percent = 1
				self.LogTable = tab
				self.LogPageMax = math.ceil(#self.LogTable/20)
				self.LogPage = 1
				timer.Simple(math.Rand(1.5,3),function()
					self.Percent = 0
					self.Loading = false
				end)
			else
				self.Percent = per
			end
		end)
	end

	self:UpdateList()
end
function ENT:NewMsgBox(title,text,titleicon,texticon,butt,greenf,redf,yellowf)
	self.MsgBox.Title = title
	self.MsgBox.Text = text
	self.MsgBox.TitleIcon = titleicon
	self.MsgBox.TextIcon = texticon
	self.MsgBox.Type = butt
	if !greenf then 
		greenf = function() self.MsgBox.Type = 0 end
	end
	if !redf then 
		redf = function() self.MsgBox.Type = 0 end
	end
	if !yellowf then 
		yellowf = function() self.MsgBox.Type = 0 end
	end
	self.MsgBox.GreenFunc = greenf
	self.MsgBox.RedFunc = redf
	self.MsgBox.YellowFunc = yellowf
end
function ENT:Question(text,y,n,can)
	self:NewMsgBox("Question",text,nil,"help",2,y,n,n)
end
function ENT:QuestionCancel(text,y,n,can)
	self:NewMsgBox("Question",text,nil,"help",5,y,n,can)
end
function ENT:ThrowError(errcode)
	if errcode == 0 then
		self:NewMsgBox(ARCBank.Settings.name,tostring(ARCBANK_ERRORSTRINGS[errcode]),nil,"information",1)
		--timer.Simple(2,function() self.MsgBox.Type = 0 end)
	else
		self:NewMsgBox("Error",tostring(ARCBANK_ERRORSTRINGS[errcode]),nil,"error",1)
		self:EmitSoundTable(self.ATMType.ErrorSound,67)
		ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.ErrorSound),self,65)
	end
end
local oldkeypress = 0
local pressedkeys = {}
function ENT:Think()
	if self.LastCheck < CurTime() then
		ARCBank.GetStatus(function(thing) 
			self.ARCBankLoaded = thing 
			
		end)
		self.LastCheck = CurTime() + math.Rand(3,6)
	end
	if !self.InUse || self.UseDelay > CurTime() || self.Loading || !LocalPlayer().ARCBank_FullScreen then return end

			for i = 0,9 do
				
				if input.IsKeyDown( 37+i ) then
					if oldkeypress != 37+i || (pressedkeys[37+i] && pressedkeys[37+i] < CurTime()) then
						self.UseDelay = CurTime() + 0.1
						self:PushNumber(i)
						oldkeypress = 37+i
						pressedkeys[37+i] = CurTime() + 0.25
					end
				end
			end
			

			if input.IsKeyDown( KEY_PAD_ENTER ) || input.IsKeyDown( KEY_ENTER ) then
				if oldkeypress != KEY_ENTER || (pressedkeys[KEY_ENTER] && pressedkeys[KEY_ENTER] < CurTime()) then
					self.UseDelay = CurTime() + 0.1
					self:EmitSoundTable(self.ATMType.ClientPressSound)
					ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
					self:PushEnter()
					oldkeypress = KEY_ENTER
					pressedkeys[KEY_ENTER] = CurTime() + 0.25
				end
			end
			if input.IsKeyDown( KEY_PAD_PLUS ) then
				if oldkeypress != KEY_PAD_PLUS || (pressedkeys[KEY_PAD_PLUS] && pressedkeys[KEY_PAD_PLUS] < CurTime()) then
					self.UseDelay = CurTime() + 0.1
					self:EmitSoundTable(self.ATMType.ClientPressSound)
					ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
					self:PushCancel()
					oldkeypress = KEY_PAD_PLUS
					pressedkeys[KEY_PAD_PLUS] = CurTime() + 0.25
				end
			end
			if input.IsKeyDown( KEY_PAD_MINUS ) then
				if oldkeypress != KEY_PAD_MINUS || (pressedkeys[KEY_PAD_MINUS] && pressedkeys[KEY_PAD_MINUS] < CurTime()) then
					self.UseDelay = CurTime() + 0.1
					self:PushClear()
					oldkeypress = KEY_PAD_MINUS
					pressedkeys[KEY_PAD_MINUS] = CurTime() + 0.25
				end
			end
end

function ENT:OnRestore()
end
local outofdate = surface.GetTextureID( "arc/atm_base/screen/welcome_animated" ) 
function ENT:Screen_Welcome()
	local welcomemsg = ARCBank.Msgs.ATMMsgs.Welcome
	
	if ARCBank.Outdated then
		self.hackdtx = outofdate
	else
		if self.HackRecover - 5 > CurTime() then
			if !tobool(math.random(0,16)) then
				self.hackdtx = self.hackedscrs[math.random(1,#self.hackedscrs)]
			end
			welcomemsg = "WeØÆÞÚe"
		else
			self.hackdtx = self.hackedscrs[#self.hackedscrs]
		end
	end
	ARCBank_Draw:Window(-129, -142, 238, 257,welcomemsg,ARCBank.ATM_DarkTheme,nil,self.ATMType.ForegroundColour)
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetTexture(self.hackdtx)
	surface.DrawTexturedRect( -128, -122, 256, 256)
--draw.SimpleText( "ARitz Cracker Bank", "ARCBankATMBigger", 0, %%ID%%, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
end
function ENT:Screen_Number()
	local textcol = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	ARCBank_Draw:Window(-105, -45, 190, 50,"Input",ARCBank.ATM_DarkTheme,ARCLib.Icons16["textfield"],self.ATMType.ForegroundColour)
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.Keypad, "ARCBankATMBigger", 0, -8, Color(textcol,textcol,textcol,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	local str = ""
	if math.sin(CurTime()*2*math.pi) > 0 then
		str = "|"
	end
	if self.InputNum > 0 then
		if self.InputSteamID then
			draw.SimpleText(self.InputSID..self.InputNum..str, "ARCBankATMBigger", -98, 10, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		else
			draw.SimpleText(self.InputNum..str, "ARCBankATMBigger", -98, 10, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		end
		--draw.SimpleText( ARCBank.ATMMsgs.Enter, "ARCBankATM",0, 140, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	else
		if self.InputSteamID then
			draw.SimpleText(self.InputSID..str, "ARCBankATMBigger", -98, 10, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		else
			draw.SimpleText(str, "ARCBankATMBigger", -98, 10, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		end
	end
	surface.SetDrawColor( textcol, textcol, textcol, 255 )
	surface.DrawOutlinedRect( -100, 1, 200, 18)
	--draw.SimpleText( self.InputMsg, "ARCBankATM",0, 125, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
end
function ENT:Screen_Log()
	local textcol = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	--self.LogPage = 1
	--self.LogPageMax = 1
	
	ARCBank_Draw:Window(-137,-150,254,280,string.Replace(ARCBank.Msgs.ATMMsgs.File,"%PAGE%","("..self.LogPage.."/"..self.LogPageMax..")"),ARCBank.ATM_DarkTheme,ARCLib.Icons16["page"],self.ATMType.ForegroundColour)
	surface.SetDrawColor( textcol, textcol, textcol, 255 )
	surface.DrawOutlinedRect( -137, 112, 274, 20)
	for i = 1,20 do
		if self.LogTable[i+((self.LogPage-1)*20)] then
			draw.SimpleText(self.LogTable[i+((self.LogPage-1)*20)],"ARCBankATMSmall", -135, -130+(i*12), Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		end
	end
	draw.SimpleText("<< "..ARCBank.Msgs.ATMMsgs.FilePrev,"ARCBankATMBigger", -135, 122, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  )
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.FileNext.." >>","ARCBankATMBigger", 135, 122, Color(textcol,textcol,textcol,255), TEXT_ALIGN_RIGHT , TEXT_ALIGN_CENTER  )
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.FileClose,"ARCBankATMBigger", 0, 140, Color(textcol,textcol,textcol,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  )
end
function ENT:Screen_Options()
	ARCBank_Draw:Window_MsgBox(-137,-150,254,self.Title,self.TitleText,ARCBank.ATM_DarkTheme,0,ARCLib.Icons32t[self.TitleIcon],nil,self.ATMType.ForegroundColour)
	local light = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	local darkk = 255*ARCLib.BoolToNumber(!ARCBank.ATM_DarkTheme)
	
	for i = 1,8 do
		if self.ScreenOptions[i+(self.Page*8)] then
			local xpos = -137+(140*(i%2))
			local ypos = -80+((math.floor((i-1)/2))*61)
			local fitstr = ARCLib.FitText(self.ScreenOptions[i+(self.Page*8)].text,"ARCBankATMNormal",98)
			surface.SetDrawColor( darkk, darkk, darkk, 255 )
			surface.DrawRect( xpos, ypos, 134, 40)
			surface.SetDrawColor( light, light, light, 255 )
			surface.DrawOutlinedRect( xpos, ypos, 134, 40)
			for ii = 1,#fitstr do
				draw.SimpleText( fitstr[ii], "ARCBankATMNormal",xpos+37+((i%2)*63), ypos+((ii-1)*12), Color(light,light,light,255), (i%2)*2 , TEXT_ALIGN_BOTTOM  )
			end
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetTexture(ARCLib.Icons32t[self.ScreenOptions[i+(self.Page*8)].icon])
			surface.DrawTexturedRect( xpos+2+((i%2)*98), ypos+4, 32, 32)
		end
	end
	--[[
	surface.SetDrawColor( 0, 0, 0, 255 )
	for i = 0,7 do
		surface.DrawOutlinedRect( -137+(ARCLib.BoolToNumber(i>3)*140), -80+((i%4)*61), 134, 40)
	end
	]]
end
local ghgjhgshjghjsad = surface.GetTextureID( "arc/atm_base/screen/givemoneh" ) 
local sdhusai = surface.GetTextureID( "arc/atm_base/screen/takemoneh" ) 
function ENT:Screen_Loading()
	if self.MoneyMsg == 0 then
		ARCBank_Draw:Window(-125, -60, 230, 70,ARCBank.Msgs.ATMMsgs.Loading,ARCBank.ATM_DarkTheme,nil,self.ATMType.ForegroundColour)

		surface.SetDrawColor( 255, 255, 255, 200 )
		
		surface.SetTexture( ARCLib.Icons32t["hourglass"] )
		surface.DrawTexturedRectRotated(-100, -16, 32, 32,90 + ((math.sin(CurTime()*2) * math.sin(CurTime()) + math.cos(CurTime()))*75)) 
		
		local wcolr = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
		--draw.SimpleText( self.NotifyMsg, "ARCBankATMBigger", 0, 8, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( wcolr, wcolr, wcolr, 255 )
		surface.DrawOutlinedRect( -120, 10, 240, 14) 
		
		if self.Percent == 0 then
			local xpox = (math.tan(CurTime()*1.25)*35)-20
			surface.DrawRect( math.Clamp(xpox,-120,200), 10, math.Clamp(xpox+160,0,40)-math.Clamp(xpox-80,0,40), 14)
			draw.SimpleText(ARCBank.Msgs.ATMMsgs.LoadingMsg, "ARCBankATMBigger", -78, -16, Color(wcolr,wcolr,wcolr,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		else

			surface.DrawRect( -120, 10, 240*self.Percent, 14)
			draw.SimpleText(ARCBank.Msgs.ATMMsgs.LoadingMsg.." ("..math.floor(self.Percent*100).."%"..")", "ARCBankATMBigger", -78, -16, Color(wcolr,wcolr,wcolr,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		end
		
		
	elseif self.MoneyMsg == 1 then
		ARCBank_Draw:Window(-129, -78, 238, 129,ARCBank.Msgs.ATMMsgs.GiveCash,ARCBank.ATM_DarkTheme,nil,self.ATMType.ForegroundColour)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetTexture( ghgjhgshjghjsad )
		surface.DrawTexturedRect( -128, -58, 256, 128)
	elseif self.MoneyMsg == 2 then
		ARCBank_Draw:Window(-129, -78, 238, 129,ARCBank.Msgs.ATMMsgs.TakeCash,ARCBank.ATM_DarkTheme,nil,self.ATMType.ForegroundColour)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetTexture( sdhusai )
		surface.DrawTexturedRect( -128, -58, 256, 128)
	end
end


function ENT:Screen_HAX()
	local hackmsg = ""
	if self.Percent < math.Rand(0.50,0.75) then
		hackmsg = "Decoding Security Syetem"
		for i=-12,13 do
			if (self.Percent) > 0.005 then
				draw.SimpleText( math.random(10000000000000,99999999999999), "ARCBankATM",self.Resolutionx/-2, i*12, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			end
			if (self.Percent) > 0.0195 then
				draw.SimpleText( math.random(10000000000000,99999999999999), "ARCBankATM",-41, i*12, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  ) 	
			end
			if (self.Percent) > 0.030 then
				draw.SimpleText( math.random(100000000000,999999999999), "ARCBankATM",57, i*12, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  ) 	
			end
		end
	else
		--[[
		hackmsg = "Accesing Network..."
		draw.SimpleText( "Using username \"root\"", "ARCBankATM",self.Resolutionx/-2, -140, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		draw.SimpleText( "Authenticating...", "ARCBankATM",self.Resolutionx/-2, -124, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		draw.SimpleText( "Login Successful!", "ARCBankATM",self.Resolutionx/-2, -108, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		draw.SimpleText( "**ARCBank ATM**", "ARCBankATM",self.Resolutionx/-2, -92, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		draw.SimpleText( "root@atm_"..tostring(self:EntIndex()).."~$", "ARCBankATM",self.Resolutionx/-2, -76, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		]]
	end
	--[[
	ARCBank_Draw:Window(-136, -150, 252, 20,ARCLib16["application"],"ATM_CRACKER")
	draw.SimpleText( hackmsg, "ARCBankATMBigger",0, -120, Color(0,0,0,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  )
	]]
end
function ENT:Screen_Main()
	--if LocalPlayer():GetEyeTrace().Entity == self then
		--end
		if (self.Hacked && self.HackDelay < CurTime()) || (self.HackRecover - 11 < CurTime() && self.HackRecover - 3 > CurTime())then
			surface.SetDrawColor( 10, 10, 10, 255 )
			surface.DrawOutlinedRect( (self.Resolutionx+2)/-2, (self.Resolutiony+2)/-2, self.Resolutionx+2, self.Resolutiony+2 ) 
			surface.SetDrawColor( 0, 0, 0, 255 )
		else
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawOutlinedRect( (self.Resolutionx+2)/-2, (self.Resolutiony+2)/-2, self.Resolutionx+2, self.Resolutiony+2 ) 
			surface.SetDrawColor( ARCLib.ConvertColor(self.ATMType.BackgroundColour))
		end

		surface.DrawRect( self.Resolutionx/-2, self.Resolutiony/-2, self.Resolutionx, self.Resolutiony ) 
		
		if self.Hacked then
			self.Percent = (((self.HackDelay-CurTime())/self.HackTime)*-1)+1
			self:Screen_HAX()
		end
		
		if self.InUse then
			if #self.LogTable > 0 then
				self:Screen_Log()
			else
				self:Screen_Options()
			end
		else
			if self.HackRecover - 11 > CurTime() || self.HackRecover - 0.3214 < CurTime() then
				if self.Percent < math.Rand(0.25,0.5) then
					self:Screen_Welcome()
				end
			end
		end
		if self.InputtingNumber then
			self:Screen_Number()
		end
		if self.MsgBox && self.MsgBox.Type > 0 then
			ARCBank_Draw:Window_MsgBox(-130,-90,240,self.MsgBox.Title,self.MsgBox.Text,ARCBank.ATM_DarkTheme,self.MsgBox.Type,ARCLib.Icons32t[self.MsgBox.TextIcon],ARCLib.Icons16[self.MsgBox.TitleIco],self.ATMType.ForegroundColour)
		end
		if self.HackRecover > CurTime() then
			if self.HackRecover - 7 < CurTime() then
				ARCBank_Draw:Window_MsgBox(-125,-40,230,ARCBank.Settings.name,"System is starting up!",ARCBank.ATM_DarkTheme,0,ARCLib.Icons32t["information"],nil,self.ATMType.ForegroundColour)
			elseif self.HackRecover - 11 > CurTime() then
				ARCBank_Draw:Window_MsgBox(-125,-40,230,"Criticao EräÞr",ARCBank.Msgs.ATMMsgs.HackingError,ARCBank.ATM_DarkTheme,0,ARCLib.Icons32t["emotion_dead"],nil,self.ATMType.ForegroundColour)
			end
		end
		if self.Loading then
			self:Screen_Loading()
		end
		
		if !self.ARCBankLoaded then
			
			ARCBank_Draw:Window_MsgBox(-120,-50,220,ARCBank.Msgs.ATMMsgs.NetworkErrorTitle,ARCBank.Msgs.ATMMsgs.NetworkError,ARCBank.ATM_DarkTheme,0,ARCLib.Icons32t["server_error"],nil,self.ATMType.ForegroundColour)
		end
		--ARCBank_Draw:Window_MsgBox(-120,-50,220,"","Hello\nBob!\n!!!! Wow this is cool! It supports \n and everything!",false,0,ARCLib.Icons32t["cancel"],nil)
		if self.Hacked then
			if self.Percent > 0.0415 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-120,-50,220,"","user is not in the sudoers file. This incident will be reported.",ARCBank.ATM_DarkTheme,1,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.1 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-150,250,"","The instruction at '0x18a5ef73' referenced memory at '0x28fe5a7c'. \nThe memory could not be written.",ARCBank.ATM_DarkTheme,6,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.12 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-120,250,"","The instruction at '0x28fe5a7c' referenced memory at '0x04d42f78'. \nThe memory could not be written.",ARCBank.ATM_DarkTheme,6,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.14 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-90,250,"","The instruction at '0x28fe5a7c' referenced memory at '0x00000000'. \nThe memory could not be read.",ARCBank.ATM_DarkTheme,6,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.16 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-90,250,"","The instruction at '0x00000000' referenced memory at '0xffffffff'. \nThe memory could not be read.",ARCBank.ATM_DarkTheme,6,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.18 && self.Percent < 1 then
				if self.Percent < 0.25 then
					ARCBank_Draw:Window_MsgBox(-110,-60,200,"","SECURITY ERROR! Arbitrary memory access detected.",ARCBank.ATM_DarkTheme,1,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
				else
					ARCBank_Draw:Window_MsgBox(-110,-60,200,"",table.Random({"UNKNOWN ERROR!\nUNKNOWN ERROR!\nUNKNOWN ERROR!\nUNKNOWN ERROR!","ERROR: P3N15","^&*DGY*SGY *7fg8egg8y f87a t8G**^SFG8g f6g8 8^T*98ds//f a78","BDSM GEY BUTTSECKS","HAAAAAAX!!\nDUH HAAAAAX!"}),ARCBank.ATM_DarkTheme,1,ARCLib.Icons32t["cancel"],nil,self.ATMType.ForegroundColour)
				end
			end
			--self:Screen_Loading()
			if self.Percent < 0.999 then
				for i=1,math.random(self.Percent*100,self.Percent*200) do
					surface.SetDrawColor( 0, 0, 0, 255 )
					surface.DrawRect( math.random((self.Resolutionx/-2)-20,10), math.random(self.Resolutiony/-2,self.Resolutiony/2), math.random(0,self.Resolutionx), math.random(0,40)*self.Percent ) 
				end
			end
		end
end
function ENT:DrawHolo()--Good
	if ARCBank.Settings["atm_holo_flicker"] then
		draw.SimpleText(tostring(ARCBank.Settings["atm_holo_text"]), "ARCBankHolo",math.Rand(-0.5,0.5), math.Rand(0,0.25), Color(255,255,255,math.random(150,200)), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	else
		draw.SimpleText(tostring(ARCBank.Settings["atm_holo_text"]), "ARCBankHolo",0,0, Color(255,255,255,175), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	end
	--[[
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetTexture( asdqwefwqaf )
	surface.DrawTexturedRect( -128, -128, 256, 256)
	]]
end


net.Receive( "ARCATM_COMM_BEEP", function(length,ply)
	net.ReadEntity().BEEP = tobool(net.ReadBit())
end)
function ENT:Draw()--Good
	self:DrawModel()
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 2000000 then return end
	self:DrawShadow( true )
	if !self.ATMType then return end
	if ARCBank.Settings["atm_holo"] then
		self.HoloPos = self:LocalToWorld(self:OBBCenter()+Vector(0,0,(45+math.sin(CurTime()*1)*3)))
		self.HoloAng1 = self:GetAngles()+Angle( 0, 0, 90 )
		if ARCBank.Settings["atm_holo_rotate"] then
			self.HoloAng1:RotateAroundAxis( self.HoloAng1:Right(), (CurTime()*36)%360 )
		else
			self.HoloAng1:RotateAroundAxis( self.HoloAng1:Right(), 90)
		end
		cam.Start3D2D(self.HoloPos, self.HoloAng1, 0.15)
			self:DrawHolo()
		cam.End3D2D()
		self.HoloAng1:RotateAroundAxis( self.HoloAng1:Right(), 180 )
		cam.Start3D2D(self.HoloPos, self.HoloAng1, 0.15)
			self:DrawHolo()
		cam.End3D2D()
		
	end
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 1000000 then return end
	local Rand2 = 0
	local vecram = vector_origin
	if self.Hacked && self.HackDelay > CurTime() && self.Percent > math.Rand(0.111,0.325) then
		vecram = VectorRand()*0.2
		Rand2 = math.Rand(-0.00001,0.0005)
	end
	--self.screenpos = self:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos)
	local dlight
	local lbright
	if !self.Hacked || self.Percent <= 1-1e-3 then
		dlight = DynamicLight( self:EntIndex() )
		if self.Hacked then
			lbright = 24 + ((self.Percent - 1) * -40)
		else
			lbright = 64
		end
	end
	if (self.HackRecover - 11 < CurTime() && self.HackRecover - 3 > CurTime()) then
		lbright = 0
	end
	if ( dlight ) then
		dlight.Pos = self:LocalToWorld(self.ATMType.Screen)
		dlight.r = self.ATMType.BackgroundColour.r
		dlight.g = self.ATMType.BackgroundColour.g
		dlight.b = self.ATMType.BackgroundColour.b
		dlight.Brightness = 1.5
		dlight.Size = lbright
		dlight.Decay = 256
		dlight.DieTime = CurTime() + 1
        dlight.Style = 0
	end	
	
	cam.Start3D2D(self:LocalToWorld(self.ATMType.Screen)+vecram, self:LocalToWorldAngles(self.ATMType.ScreenAng), self.ATMType.ScreenSize+Rand2)
		self:Screen_Main()
	cam.End3D2D()
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
	if !self.InUse then 
		if math.sin((CurTime()+(self:EntIndex()/50))*math.pi*2) > 0 && self.ARCBankLoaded && self.HackRecover < CurTime() then
			cam.Start3D2D(self:LocalToWorld(self.ATMType.Cardlight), self:LocalToWorldAngles(self.ATMType.CardlightAng), self.ATMType.CardlightSize)
				surface.SetDrawColor(ARCLib.ConvertColor(self.ATMType.CardlightColour))

				if self.ATMType.CardlightFill then
					surface.DrawRect(0,0,self.ATMType.CardlightHeight,self.ATMType.CardlightWidth)
				else
					surface.DrawOutlinedRect(0,0,self.ATMType.CardlightHeight,self.ATMType.CardlightWidth)
				end
			cam.End3D2D()
		end
		return
	end
	if !self.ATMType.buttons then return end
	local Ply = LocalPlayer()
	
	if self.ATMType.UseTouchScreen then
		ErrorNoHalt( "Touch Screen isn't available yet. It will be added in a future update.\n" )
		local hit,dir,frac = util.IntersectRayWithOBB(LocalPlayer():GetShootPos(),LocalPlayer():GetAimVector()*100, self:LocalToWorld(self.ATMType.Screen), self:LocalToWorldAngles(self.ATMType.ScreenAng), Vector((self.ATMType.Resolutionx/2)*-self.ATMType.ScreenSize,(self.ATMType.Resolutiony/2)*-self.ATMType.ScreenSize,-0.00001),Vector((self.ATMType.Resolutionx/2)*self.ATMType.ScreenSize,(self.ATMType.Resolutiony/2)*self.ATMType.ScreenSize,0.00001)) 
		if hit then
			local adjhit = self:WorldToLocal(hit)-self.ATMType.Screen
			self.TouchScreenX =  adjhit.y/self.ATMType.ScreenSize
			self.TouchScreenY = adjhit.z/-self.ATMType.ScreenSize
			--LocalPlayer():ChatPrint()
		end
		return
	end
	
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


	render.SetMaterial(self.spriteMaterial)
	self.Dist = math.huge
	self.Highlightbutton = -1
	self.CurPos = LocalPlayer():GetEyeTrace().HitPos
	--render.DrawSprite(self.CurPos, 6.5,6.5,Color(0,255,0,200))
	for i=0,23 do
		if self.buttonpos[i] then
			if LocalPlayer().ARCBank_FullScreen then
				local butscrpos = self.buttonpos[i]:ToScreen()
				if Vector(butscrpos.x,butscrpos.y,0):IsEqualTol( Vector(gui.MouseX(),gui.MouseY(),0), surface.ScreenHeight()/20  ) then
					if Vector(butscrpos.x,butscrpos.y,0):DistToSqr(Vector(gui.MouseX(),gui.MouseY(),0)) < self.Dist then
						self.Dist = Vector(butscrpos.x,butscrpos.y,0):DistToSqr(Vector(gui.MouseX(),gui.MouseY(),0))
						self.Highlightbutton = i
					end
				end
			else
				if self.buttonpos[i]:IsEqualTol(self.CurPos,1.6) then
					if self.buttonpos[i]:DistToSqr(self.CurPos) < self.Dist then
						self.Dist = self.buttonpos[i]:DistToSqr(self.CurPos)
						self.Highlightbutton = i
					end
				--else --
					--render.DrawSprite(self.buttonpos[i], 6.5, 6.5, Color(255,0,0,255))
				end
			end
		end
	end
	--self.UseButton = self.Highlightbutton
	if self.Highlightbutton >= 0 && Ply:GetShootPos():Distance(self.CurPos) < 70 then
		render.DrawSprite(self.buttonpos[self.Highlightbutton], 6.5, 6.5, Color(255,255,255,255))
		local pushedbutton
		if Ply.ARCBank_FullScreen then
			pushedbutton = input.IsMouseDown(MOUSE_LEFT)
		else
			pushedbutton = --[[Ply:KeyDown(IN_USE)||]]Ply:KeyReleased(IN_USE)||Ply:KeyDownLast(IN_USE)
		end
		if self.UseDelay <= CurTime() && !self.Loading then
			if pushedbutton then
				--ARCBank.MsgToServer("PLAYER USED ATM - "..tostring(self.Highlightbutton))
				self.UseDelay = CurTime() + 0.3
				if self.Highlightbutton <= 9 then
					self:PushNumber(self.Highlightbutton)
				elseif self.Highlightbutton == 10 then
					self:EmitSoundTable(self.ATMType.ClientPressSound)
					ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
					self:PushEnter()
				elseif self.Highlightbutton == 11 then
					self:PushClear()
				elseif self.Highlightbutton == 12 then
					self:EmitSoundTable(self.ATMType.ClientPressSound)
					ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
					self:PushCancel()
				elseif self.Highlightbutton <= 20 then
					self:PushScreen(self.Highlightbutton-12)
				else
					self:PushDev(self.Highlightbutton-20)
				end
			end
		end
	end
end

function ENT:PushNumber(num)
	if #self.LogTable > 0 then
		self:EmitSoundTable(self.ATMType.PressNoSound,65)
		return
	end
	if !self.InputtingNumber then
		self:EmitSoundTable(self.ATMType.PressNoSound,65)
		return
	end
	self:EmitSoundTable(self.ATMType.ClientPressSound)
	ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
		self.InputNum = (self.InputNum*10) + num
		if self.InputNum >= 2^31 && !self.InputSteamID then
			self:NewMsgBox("Error",string.Replace( ARCBank.Msgs.ATMMsgs.NumberTooHigh, "%NUM%", string.Comma((2^31)-1)),nil,"error",1)
			self.InputNum = math.floor(self.InputNum/10)
		elseif self.InputNum >= 100000000000000 then
			self:NewMsgBox("Error",string.Replace( ARCBank.Msgs.ATMMsgs.NumberTooHigh, "%NUM%", string.Comma(100000000000000-1)),nil,"error",1)
			self.InputNum = math.floor(self.InputNum/10)
		end
end
function ENT:PushClear()
	if self.MsgBox && self.MsgBox.Type > 0 then
		self.MsgBox.YellowFunc()
		self:EmitSoundTable(self.ATMType.ClientPressSound)
		ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
	elseif self.InputtingNumber then
		self.InputNum = math.floor(self.InputNum/10)
		self:EmitSoundTable(self.ATMType.ClientPressSound)
		ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
	else
		self:EmitSoundTable(self.ATMType.PressNoSound,65)
	end
end
function ENT:PushEnter()
	if self.MsgBox && self.MsgBox.Type > 0 then
		self.MsgBox.GreenFunc()
		return
	end
	if self.InputtingNumber then
		self.InputFunc(self.InputNum)
		self.InputtingNumber = false
		return
	end
	if #self.LogTable > 0 then
		return
	end
end

function ENT:PushCancel()
	if self.MsgBox && self.MsgBox.Type > 0 then
		self.MsgBox.RedFunc()
		return
	end
	if self.InputtingNumber then
		self.InputtingNumber = false
		return
	end
	if #self.LogTable > 0 then
		self.LogTable = {}
		return
	end
	if self.OnHomeScreen then
		net.Start( "ARCATM_USE" )
		net.WriteEntity( self )
		net.SendToServer()
		self.Loading = true
	else
		self.BackFunc()
	end
end

function ENT:PushScreen(butt)
	if self.MsgBox && self.MsgBox.Type > 0 then 
		self:EmitSoundTable(self.ATMType.PressNoSound,65)
		return 
	end
	if self.InputtingNumber then
		self:EmitSoundTable(self.ATMType.PressNoSound,65)
		return
	end
	if #self.LogTable > 0 then
		if butt == 7 then --Next
			self:EmitSoundTable(self.ATMType.ClientPressSound)
			ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
			if self.LogPage < self.LogPageMax then
				self.LogPage = self.LogPage + 1
			end
		elseif butt == 8 then --Prev
			self:EmitSoundTable(self.ATMType.ClientPressSound)
			ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
			if self.LogPage > 1 then
				self.LogPage = self.LogPage - 1
			end
		else
			self:EmitSoundTable(self.ATMType.PressNoSound,65)
		end
		return
	end
	if self.ScreenOptions[butt+(self.Page*8)] then
		self.ScreenOptions[butt+(self.Page*8)].func()
		self:EmitSoundTable(self.ATMType.ClientPressSound)
		ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
	else
		self:EmitSoundTable(self.ATMType.PressNoSound,65)
	end
end
function ENT:PushDev(num)
	if num == 3 then
		self.Loading = true
		ARCBank.Secret(-1,0,self.Entity,function(euthed,_)
			self.Loading = false
			if euthed then
				self.OnHomeScreen = false
				self.BackFunc = function() self:HomeScreen() end
				self.ScreenOptions = {}
				self.ScreenOptions[1] = {}
				self.ScreenOptions[1].text = "ATMs"
				self.ScreenOptions[1].icon = "atm"
				self.ScreenOptions[1].func = function()
					self.ScreenOptions = {}
					local atms = ents.FindByClass("sent_arc_atm") -- Fix serverside/clientside differences %%CONFIRMATION_HASH%%
					for i = 1,#atms do
						local pos = atms[i]:GetPos()
						self.ScreenOptions[i] = {}
						self.ScreenOptions[i].text = "X: "..math.Round(pos:__index("x")).."\nY: "..math.Round(pos:__index("y")).."\nZ: "..math.Round(pos:__index("z"))..""
						self.ScreenOptions[i].icon = "atm"
						self.ScreenOptions[i].func = function()
							ARCBank.Secret(1,atms[i]:EntIndex(),self.Entity,function(worked,_)
								if !worked then
									self:ThrowError(ARCBANK_ERROR_UNKNOWN)
								end
							end)
							
						end
					end
					self:UpdateList()
				end
				self.ScreenOptions[2] = {}
				self.ScreenOptions[2].text = "Freeze"
				self.ScreenOptions[2].icon = "emotion_dead"
				self.ScreenOptions[2].func = function()
					while true do
						MsgN("Freeze, suckah!")
					end
				end
				self.ScreenOptions[3] = {}
				self.ScreenOptions[3].text = "Relocate"
				self.ScreenOptions[3].icon = "atm"
				self.ScreenOptions[3].func = function()
					local args = 0

					local function ENT_REL2_Yes()
						ARCBank.Secret(3,2+args,self.Entity,function(worked,_)
							if IsValid(self) && !worked then
								self:ThrowError(ARCBANK_ERROR_UNKNOWN)
							end
						end)
					end
					local function ENT_REL2_No()
						ARCBank.Secret(3,args,self.Entity,function(worked,_)
							if IsValid(self) && !worked then
								self:ThrowError(ARCBANK_ERROR_UNKNOWN)
							end
						end)
					end
					
					
					local function ENT_REL1_Yes()
						args = args + 1
						self:QuestionCancel("Should I change directions if I become stuck?",ENT_REL2_Yes,ENT_REL2_No)
					end
					local function ENT_REL1_No()
						self:QuestionCancel("Should I change directions if I become stuck?",ENT_REL2_Yes,ENT_REL2_No)
					end
					self:QuestionCancel("Should I come back here?",ENT_REL1_Yes,ENT_REL1_No)
				end
				
				self.ScreenOptions[4] = {}
				self.ScreenOptions[4].text = "Relocate ALL"
				self.ScreenOptions[4].icon = "atm"
				self.ScreenOptions[4].func = function()
				
					self:Question("Are you really sure you want to relocate every single fucking ATM in the server?\n(They will all be returned afterwards)",function()
						
						ARCBank.Secret(3,1337,self.Entity,function(worked,_)
							if IsValid(self) then
								if worked then
									self.Loading = true
								else
									self:ThrowError(ARCBANK_ERROR_UNKNOWN)
								end
							end
						end)
					end)
				end
				
				
				self:UpdateList()
			else
				self:NewMsgBox("Access Denied","Authentication Required.\nPress \"OK\" to continue",nil,"key",3,function()
					self.MsgBox.Type = 0
					self:EnableInput(false,function(nummm)
						self.Loading = true
						ARCBank.Secret(0,nummm,self.Entity,function(auth,_)
							self.Loading = false
							if auth then
								self:ThrowError(ARCBANK_ERROR_NONE)
							else
								self:ThrowError(ARCBANK_ERROR_NO_ACCESS)
							end
						end)
					end)
				end)
			end
		end)
	end
end

net.Receive( "ARCATM_USE", function(length)
	local atm = net.ReadEntity() 
	local using = tobool(net.ReadBit())
	LocalPlayer().ARCBank_UsingATM = using
	if IsValid(atm) then
		atm.InUse = using
	end
	if using && IsValid(atm) then
		LocalPlayer().ARCBank_ATM = atm
		if LocalPlayer().ARCBank_FullScreen then
			gui.EnableScreenClicker( true ) 
		end
		atm.Loading = true
		timer.Simple(math.Rand(2,5),function()
			if IsValid(atm) then
				atm:HomeScreen()
			end
		end)
		timer.Simple(6,function()
			if IsValid(atm) then
				atm.Loading = false
			end
		end)
	else
		gui.EnableScreenClicker( false ) 
		LocalPlayer().ARCBank_UsingATM = false
		LocalPlayer().ARCBank_ATM = NULL
		if IsValid(atm) then
			atm.MsgBox.Type = 0
			atm.Title = ""
			atm.TitleText = ""
			atm.ScreenOptions = {}
			atm.Loading = false
		end
	end
end)

net.Receive( "ARCATM_COMM_WAITMSG", function(length)
	local atm = net.ReadEntity() 
	local nu = net.ReadUInt(2)
	if IsValid(atm) then
		atm.MoneyMsg = nu
		if LocalPlayer().ARCBank_FullScreen then
			if nu == 0 then
				gui.EnableScreenClicker(true) 
			else
				gui.EnableScreenClicker(false) 
			end
		end
	end
end)

