-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
include('shared.lua')
local icons_rank = {}
icons_rank[0] = "hand_fuck"
icons_rank[1] = "user"
icons_rank[2] = "medal_bronze_red"
icons_rank[3] = "medal_silver_blue"
icons_rank[4] = "medal_gold_green"
icons_rank[5] = "hand_fuck"
icons_rank[6] = "group"
icons_rank[7] = "group_add"
ENT.MsgBox = {}
ARCBank.ATM_DarkTheme = false
net.Receive( "ARCBank CustomATM", function(length)
	local atm = net.ReadEntity()
	if IsValid(atm) then
		local strlen = net.ReadUInt(32)
		atm.ATMType = util.JSONToTable(util.Decompress(net.ReadData(strlen)))
		for i=1,#atm.ATMType.HackedWelcomeScreen do
			atm.hackedscrs[i] = surface.GetTextureID(atm.ATMType.HackedWelcomeScreen[i])
		end
		atm.hackedscrs[#atm.hackedscrs+1] = surface.GetTextureID(atm.ATMType.WelcomeScreen)
		atm.ATMType.FullScreen = atm.ATMType.FullScreen || vector_origin
		atm.ATMType.FullScreenAng = atm.ATMType.FullScreenAng || angle_zero
		
	end
end)

local brokenATMs = {}

function ENT:Initialize()
	net.Start("ARCBank CustomATM")
	net.WriteEntity(self.Entity)
	net.SendToServer()
	self.hackedscrs = {surface.GetTextureID("arc/atm_base/screen/welcome_new")}
	self.LastCheck = CurTime()
	self.RebootTime = CurTime() + 6
	if brokenATMs[enti] then
		table.Merge( self, brokenATMs[enti] )
		table.remove( brokenATMs, enti )
	end
	self.RequestedAccountName = ""
	self.LogTable = {}
	self.LogPage = 1
	self.LogPageMax = 1
	self.NewLogTable = {}
	self.NewLogPage = 1
	self.NewLogPageMax = 1
	
	self.Loading = false
	self.Percent = 0
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
	self.TouchIcons = {}
	self.TouchScreenX = 0
	self.TouchScreenY = 0
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



--local function ENT_AccountOptions(accountdata,ent)
local function ENT_AccountOptions(errcode,accountdata,ent)
	ent:AccountOptions(errcode,accountdata)
end

function ENT:AccountOptions(errcode,accountdata)
	local ent = self
	if errcode != ARCBANK_ERROR_NONE then
		ent.Loading = false
		ent:ThrowError(errcode)
	else
		accountdata.isgroup = accountdata.rank > ARCBANK_GROUPACCOUNTS_
		ARCBank.GetBalance(ent,accountdata.account,function(err,money,ent)
			if err != ARCBANK_ERROR_NONE then
				ARCBank.Msg("ATM Error "..tostring(err).." was thrown while getting the account balance AFTER the account perperties were sucessfully retrieved!")
				ent:ThrowError(err)
			else
				accountdata.money = money
				ent.RequestedAccount = accountdata.account
				ent.RequestedAccountName = accountdata.name
				
				ent.OnHomeScreen = false
				ent.Title = accountdata.name
				ent.TitleText = ARCBank.Msgs.ATMMsgs.Balance..string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(money))
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
					ent:PlayerSearch(false)
				end
				
				ent.ScreenOptions[4] = {}
				ent.ScreenOptions[4].text = ARCBank.Msgs.ATMMsgs.ViewLog
				ent.ScreenOptions[4].icon = "file_extension_log"
				ent.ScreenOptions[4].func = function()
					ent.TitleText = ARCBank.Msgs.ATMMsgs.ViewLog
					ent.TitleIcon = "file_extension_log"
					
					local dayopt = {7,14,30,60,90,120}
					local days = 0
					
					ent.ScreenOptions = {}
					for i=1,3 do
						local ii = i*2
						ent.ScreenOptions[ii] = {}
						ent.ScreenOptions[ii].text = dayopt[i].." "..ARCBank.Msgs.Time.days
						ent.ScreenOptions[ii].icon = "table"
						ent.ScreenOptions[ii].func = function()
							ent:ViewLogOptions(dayopt[i],accountdata)
						end
						ii = ii - 1
						ent.ScreenOptions[ii] = {}
						ent.ScreenOptions[ii].text = dayopt[i+3].." "..ARCBank.Msgs.Time.days
						ent.ScreenOptions[ii].icon = "table_multiple"
						ent.ScreenOptions[ii].func = function()
							ent:ViewLogOptions(dayopt[i+3],accountdata)
						end
					end
					ent.ScreenOptions[7] = {}
					ent.ScreenOptions[7].text = ARCBank.Msgs.ATMMsgs.OtherNumber
					ent.ScreenOptions[7].icon = "textfield"
					ent.ScreenOptions[7].func = function()
						ent:EnableInput(false,function(nummm)
							ent:ViewLogOptions(nummm,accountdata)
						end)
					end 
					ent.BackFunc = function() 
						ent.Loading = true
						ARCBank.GetAccountProperties(ent,ent.RequestedAccount,ENT_AccountOptions)
					end
					ent:UpdateList()
				end
				
				if accountdata.isgroup then
					--PrintTable(accountdata.members)
					ent.ScreenOptions[5] = {}
					ent.ScreenOptions[5].text = ARCBank.Msgs.ATMMsgs.RemovePlayerGroup
					ent.ScreenOptions[5].icon = "user_delete"
					ent.ScreenOptions[5].func = function()
						ent.Loading = true
						ARCBank.GroupGetPlayers(ent,ent.RequestedAccount,function(err,data)
							if err == ARCBANK_ERROR_NONE then
								ent:PlayerGroup(data)
							else
								ent:ThrowError(err) 
							end
							ent.Loading = false
						end)
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
							ARCBank.RemoveAccount(ent,ent.RequestedAccount,"ATM",function(err,ent) 
								if err == ARCBANK_ERROR_NONE then
									ent:HomeScreen()
								end
								ent.Loading = false
								ent:ThrowError(err) 
							end)
						end)
					end
				end
				ent.BackFunc = function() ent:HomeScreen() end
				
				ent:UpdateList()
			
				
			end
			ent.Percent = 0
			ent.Loading = false
		end)
	end
end

function ENT:ViewLogOptions(days,accountdata)
	local transaction_type = ARCBANK_TRANSACTION_EVERYTHING
	
	local transaction_types = {1,2,4,24,96,512}


	self.ScreenOptions = {}
	for i=1,6 do
		self.ScreenOptions[i] = {}
		self.ScreenOptions[i].text = ARCBank.Msgs.AccountTransactions[transaction_types[i]]
		self.ScreenOptions[i].icon = "check_box"
		self.ScreenOptions[i].func = function(ii) 
			if self.ScreenOptions[ii].icon == "check_box_uncheck" then
				transaction_type = bit.bor(transaction_type,transaction_types[ii])
				self.ScreenOptions[ii].icon = "check_box"
			else
				transaction_type = bit.band(transaction_type,bit.bnot(transaction_types[ii]))
				self.ScreenOptions[ii].icon = "check_box_uncheck"
			end
		end
	end
	self.ScreenOptions[7] = {}
	self.ScreenOptions[7].text = ARCBank.Msgs.ATMMsgs.ViewLog
	self.ScreenOptions[7].icon = "file_extension_log"
	self.ScreenOptions[7].func = function()
		self.Loading = true
		local accn = ""
		if accountdata.isgroup then
			accn = accountdata.name
		end
		MsgN(transaction_type)
		ARCBank.GetLog(self,accn,os.time()-(days*86400),transaction_type,function(err,prog,tab,self)
			if err == ARCBANK_ERROR_DOWNLOADING then
				self.Percent = prog
			elseif err == ARCBANK_ERROR_NONE then
				self.Percent = 1
				self.NewLogTable = tab
				self.NewLogPageMax = math.ceil(#tab/5)
				self.NewLogPage = self.NewLogPageMax
				ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions) --This will make sure that your account info will be displayed after you close the log
				if #tab == 0 then
					self:ThrowError(ARCBANK_ERROR_LOG_EMPTY)
				end
			else
				self.Percent = 0
				self.Loading = false
				self:ThrowError(err)
			end
		end)
	end

	self:UpdateList()
end

function ENT:PlayerAccountSearch(ply)
	self.Loading = true
	ARCBank.GetAccessableAccounts(ply,function(err,data)
		if err != ARCBANK_ERROR_NONE then
			self.Percent = 0
			self.Loading = false
			self:ThrowError(err)
		else
			local names = {}
			ARCLib.ForEachAsync(data,function(k,v,callback)
				if string.StartWith( v, "_" ) then --TODO: Since the names aren't lost like in 1.4.0-beta1 can't we decode them instead of asking the server for them?
					callback()
				else
					ARCBank.GetAccountName(v,function(err,name)
						if err == ARCBANK_ERROR_NONE then
							names[#names + 1] = name
						else
							names[#names + 1] = v
						end
						callback()
					end)
				end
			end,function()
				self.OnHomeScreen = false
				self.ScreenOptions = {}
				self.ScreenOptions[1] = {}
				self.ScreenOptions[1].text = ARCBank.Msgs.ATMMsgs.PersonalAccount
				self.ScreenOptions[1].icon = "user"
				self.ScreenOptions[1].func = function()
					self:EnableInput(false,function(nummm)
						self.Loading = true
						ARCBank.Transfer(self,ply,self.RequestedAccount,"",nummm,"ATM Transfer",function(err,ent) 
							ent:ThrowError(err) 
							ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
						end)
					end)
					
					
				end
				
				for ii = 1,#names do
					self.ScreenOptions[ii+1] = {}
					self.ScreenOptions[ii+1].text = names[ii]
					self.ScreenOptions[ii+1].icon = "group"
					self.ScreenOptions[ii+1].func = function(iconnum)
						self:EnableInput(false,function(nummm)
							self.Loading = true
							ARCBank.Transfer(self,ply,self.RequestedAccount,self.ScreenOptions[iconnum].text,nummm,"ATM Transfer",function(err,ent) 
								ent:ThrowError(err) 
								ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
							end)
						end)
						
						
					end
				end
				self.BackFunc = function() 
					self.Loading = true
					ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
				end
				self:UpdateList()
				
				self.Percent = 0
				self.Loading = false
			end)
		end
	end)
end

function ENT:PlayerSearch(addgroup)
	local plys = player.GetAll()
	self.ScreenOptions = {}
	for i = 1,#plys do 
		self.ScreenOptions[i] = {}
		self.ScreenOptions[i].text = plys[i]:Nick().."\n"..string.sub(ARCBank.GetPlayerID(plys[i]),#ARCBank.PlayerIDPrefix+1)
		if addgroup then
			self.ScreenOptions[i].icon = "user_add"
			self.ScreenOptions[i].func = function() 
				self.Loading = true
				ARCBank.GroupAddPlayer(self,self.RequestedAccount,plys[i],"",function(err,ent) 
					ent.Loading = false
					ent:ThrowError(err) 
				end)
			end
		else
			self.ScreenOptions[i].icon = "user"
			self.ScreenOptions[i].func = function() 
				self:PlayerAccountSearch(plys[i])
			end
		end
	end
	
	self.ScreenOptions[#plys+1] = {}
	self.ScreenOptions[#plys+1].text = ARCBank.Msgs.ATMMsgs.OfflinePlayer
	self.ScreenOptions[#plys+1].icon = "textfield"
	self.ScreenOptions[#plys+1].func = function() 
		self.InputSID = ARCBank.PlayerIDPrefix
		
		if ARCBank.PlayerIDPrefix == "STEAM_" then
			local function ENT_SID_Yes()
				self.InputSID = "STEAM_0:1:"
				self.MsgBox.Type = 0
			end
			local function ENT_SID_No()
				self.InputSID = "STEAM_0:0:"
				self.MsgBox.Type = 0
			end
			self:Question(ARCBank.Msgs.ATMMsgs.SIDAsk,ENT_SID_Yes,ENT_SID_No)
		else
			self:NewMsgBox(ARCBank.Settings.name,ARCBank.Msgs.ATMMsgs.EnterPlayer,nil,"information",1)
		end
		self:EnableInput(true,function(nummmmm)
			self.Loading = true
			local ENTSTEAMID = self.InputSID..nummmmm
			if addgroup then
				ARCBank.GroupAddPlayer(self,self.RequestedAccount,ENTSTEAMID,"",function(err,ent) 
					ent.Loading = false
					ent:ThrowError(err) 
				end)
			else
				self:PlayerAccountSearch(ENTSTEAMID)
			end
		end)
	end
	
	self.BackFunc = function() 
		self.Loading = true
		ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
	end
	self:UpdateList()
end
function ENT:PlayerGroup(members)
	self.ScreenOptions = {}
	for i = 1,#members do 
		local ply = ARCBank.GetPlayerByID(members[i])
		self.ScreenOptions[i] = {}
		self.ScreenOptions[i].text = tostring(ply:Nick()).."\n"..string.sub(ARCBank.GetPlayerID(ply),#ARCBank.PlayerIDPrefix+1)
		self.ScreenOptions[i].icon = "user_delete"
		self.ScreenOptions[i].func = function() 
			self.Loading = true
			ARCBank.GroupRemovePlayer(self,self.RequestedAccount,members[i],"",function(err,ent) 
				if err == ARCBANK_ERROR_NONE then
					ARCBank.GroupGetPlayers(ent,ent.RequestedAccount,function(err,data)
						if err == ARCBANK_ERROR_NONE then
							ent:PlayerGroup(data)
						else
							ent:ThrowError(err) 
						end
						ent.Loading = false
					end)
				else
					ent:ThrowError(err)
				end
			end)
		end
	end
	
	self.BackFunc = function() 
		self.Loading = true
		ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
	end
	self:UpdateList()
end
net.Receive( "ARCATM_COMM_CASH", function(length,ply)
	local atm = net.ReadEntity() 
	if !IsValid(atm) or LocalPlayer().ARCBank_ATM != atm then return end
	local errcode = net.ReadInt(ARCBANK_ERRORBITRATE)
	atm.Loading = true
	ARCBank.GetAccountProperties(atm,atm.RequestedAccount,ENT_AccountOptions)
	if errcode != ARCBANK_ERROR_NONE then
		atm:ThrowError(errcode)
	end
end)
function ENT:MoneyOptions()
	self.ScreenOptions = {}
	
	for i = 1,3 do
		self.ScreenOptions[i*2] = {}
		self.ScreenOptions[i*2].text = tostring(ARCBank.Settings["atm_fast_amount_"..tostring(i)])
		self.ScreenOptions[i*2].icon = "money"
		self.ScreenOptions[i*2].func = function() 
			self.Loading = true
			timer.Simple(math.random(),function()
				net.Start( "ARCATM_COMM_CASH" )
				net.WriteEntity( self )
				net.WriteString(self.RequestedAccount)
				net.WriteBit(self.MoneyTake)
				net.WriteUInt(ARCBank.Settings["atm_fast_amount_"..tostring(i)],32)
				net.SendToServer()
			end)
		end
		self.ScreenOptions[i*2-1] = {}
		self.ScreenOptions[i*2-1].text = tostring(ARCBank.Settings["atm_fast_amount_"..tostring(i+3)])
		self.ScreenOptions[i*2-1].icon = "money"
		self.ScreenOptions[i*2-1].func = function() 
			self.Loading = true
			timer.Simple(math.random(),function()
				net.Start( "ARCATM_COMM_CASH" )
				net.WriteEntity( self )
				net.WriteString(self.RequestedAccount)
				net.WriteBit(self.MoneyTake)
				net.WriteUInt(ARCBank.Settings["atm_fast_amount_"..tostring(i+3)],32)
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
		ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
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
			ARCBank.UpgradeAccount(ent,ent.RequestedAccount,ENT_DoUpgrade)
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
		
		
		
		
		ARCBank.GetAccessableAccounts(LocalPlayer(),function(err,data)
			if err != ARCBANK_ERROR_NONE then
				self.Percent = 0
				self.Loading = false
				self:ThrowError(err)
			else
				local names = {}
				ARCLib.ForEachAsync(data,function(k,v,callback)
					if string.StartWith( v, "_" ) then --TODO: Since the names aren't lost like in 1.4.0-beta1 can't we decode them instead of asking the server for them?
						callback()
					else
						ARCBank.GetAccountName(v,function(err,name)
							if err == ARCBANK_ERROR_NONE then
								names[#names + 1] = name
							else
								names[#names + 1] = v
							end
							callback()
						end)
					end
				end,function()
					self.OnHomeScreen = false
					self.ScreenOptions = {}
					
					for i = 1,#names do
						self.ScreenOptions[i] = {}
						self.ScreenOptions[i].text = names[i]
						self.ScreenOptions[i].icon = "group"
						self.ScreenOptions[i].func = function(iconnum)
							self.Loading = true
							self.RequestedAccount = self.ScreenOptions[iconnum].text
							ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
						end
					end
					self.BackFunc = function() self:HomeScreen() end
					self:UpdateList()
					
					self.Percent = 0
					self.Loading = false
				end)
			end
		end)
	end
	
	self.ScreenOptions[2] = {}
	self.ScreenOptions[2].text = ARCBank.Msgs.ATMMsgs.PersonalInformation
	self.ScreenOptions[2].icon = "user"
	self.ScreenOptions[2].func = function()
		self.Loading = true
		self.RequestedAccount = ""
		ARCBank.GetAccountProperties(self.Entity,self.RequestedAccount,ENT_AccountOptions)
	end
	
	self.ScreenOptions[3] = {}
	self.ScreenOptions[3].text = ARCBank.Msgs.ATMMsgs.GroupUpgrade
	self.ScreenOptions[3].icon = "group_edit"
	self.ScreenOptions[3].func = function() 
			self.Loading = true
			
		ARCBank.GetAccessableAccounts(LocalPlayer(),function(err,data)
			if err != ARCBANK_ERROR_NONE then
				self.Percent = 0
				self.Loading = false
				self:ThrowError(err)
			else
				local names = {}
				ARCLib.ForEachAsync(data,function(k,v,callback)
					if string.StartWith( v, "_" ) then --TODO: Since the names aren't lost like in 1.4.0-beta1 can't we decode them instead of asking the server for them?
						callback()
					else
						ARCBank.GetAccountName(v,function(err,name)
							if err == ARCBANK_ERROR_NONE then
								names[#names + 1] = name
							else
								names[#names + 1] = v
							end
							callback()
						end)
					end
				end,function()
					self.OnHomeScreen = false
					self.ScreenOptions = {}
					
					for i = 1,#names do
						self.ScreenOptions[i] = {}
						self.ScreenOptions[i].text = names[i]
						self.ScreenOptions[i].icon = "group"
						self.ScreenOptions[i].func = function(iconnum)
							self.Loading = true
							self.RequestedAccount = self.ScreenOptions[iconnum].text
							ARCBank.CreateAccount(self.Entity,self.RequestedAccount,ARCBANK_GROUPACCOUNTS_STANDARD,ENT_AccountUpgrade)
						end
					end
					local i = #names + 1
					self.ScreenOptions[i] = {}
					self.ScreenOptions[i].text = ARCBank.Msgs.ATMMsgs.CreateGroupAccount
					self.ScreenOptions[i].icon = "group_edit"
					self.ScreenOptions[i].func = function()
						Derma_StringRequest( ARCBank.Msgs.ATMMsgs.CreateGroupAccount, "Enter name", "", function(text)
							self:EmitSoundTable(self.ATMType.PressSound,65)
							ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
							self.Loading = true
							self.RequestedAccount = text
							ARCBank.CreateAccount(self.Entity,self.RequestedAccount,ARCBANK_GROUPACCOUNTS_STANDARD,ENT_AccountUpgrade)
						end) 
					end
					
					
					self.BackFunc = function() self:HomeScreen() end
					self:UpdateList()
					
					self.Percent = 0
					self.Loading = false
				end)
			end
		end)
	end
	
	self.ScreenOptions[4] = {}
	self.ScreenOptions[4].text = ARCBank.Msgs.ATMMsgs.PersonalUpgrade
	self.ScreenOptions[4].icon = "user_edit"
	self.ScreenOptions[4].func = function() 
		self.Loading = true
		self.RequestedAccount = ""
		ARCBank.CreateAccount(self.Entity,self.RequestedAccount,ARCBANK_PERSONALACCOUNTS_STANDARD,ENT_AccountUpgrade)
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
	if IsValid(self:GetARCBankUsePlayer()) and self:GetARCBankUsePlayer() != LocalPlayer() then
		
		local light = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
		local darkk = 255*ARCLib.BoolToNumber(!ARCBank.ATM_DarkTheme)
		local halfres = math.Round(self.ATMType.Resolutionx*0.5)
		ARCBank_Draw:Window_MsgBox((halfres*-1)+2,-150,self.ATMType.Resolutionx-24,ARCBank.Settings["name"],ARCBank.Settings["name_long"],ARCBank.ATM_DarkTheme,0,ARCLib.GetIcon(2,"application"),nil,self.ATMType.ForegroundColour)

		for i = 1,8 do
			--if self.ScreenOptions[i+(self.Page*8)] then
				local xpos = 0
				if i%2 == 0 then
					xpos = (halfres*-1)+2
				else
					xpos = halfres - 136
				end
				local ypos = -80+((math.floor((i-1)/2))*61)
				local fitstr = ARCLib.FitText(ARCBank.Msgs.ATMMsgs.LoadingMsg,"ARCBankATMNormal",98)
				surface.SetDrawColor( darkk, darkk, darkk, 255 )
				surface.DrawRect( xpos, ypos, 134, 40)
				surface.SetDrawColor( light, light, light, 255 )
				surface.DrawOutlinedRect( xpos, ypos, 134, 40)
				for ii = 1,#fitstr do
					draw.SimpleText( fitstr[ii], "ARCBankATMNormal",xpos+37+((i%2)*63), ypos+((ii-1)*12), Color(light,light,light,255), (i%2)*2 , TEXT_ALIGN_TOP  )
				end
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial(ARCLib.GetIcon(2,"page"))
				surface.DrawTexturedRect( xpos+2+((i%2)*98), ypos+4, 32, 32)
			--end
		end
		
		return
	end

	local welcomemsg = ARCBank.Msgs.ATMMsgs.Welcome
	
	if ARCBank.Outdated then
		self.hackdtx = outofdate
	else
		if self.Broken then
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
	local shiftup = 60*ARCLib.BoolToNumber(self.ATMType.UseTouchScreen)
	ARCBank_Draw:Window(-105, -45 - shiftup, 190, 50,"Input",ARCBank.ATM_DarkTheme,ARCLib.GetIcon(1,"textfield"),self.ATMType.ForegroundColour)
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.Keypad, "ARCBankATMBigger", 0, -8 - shiftup, Color(textcol,textcol,textcol,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	local str = ""
	if math.sin(CurTime()*2*math.pi) > 0 then
		str = "|"
	end
	if self.InputNum > 0 then
		if self.InputSteamID then
			draw.SimpleText(self.InputSID..self.InputNum..str, "ARCBankATMBigger", -98, 10 - shiftup, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		else
			draw.SimpleText(self.InputNum..str, "ARCBankATMBigger", -98, 10 - shiftup, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		end
		--draw.SimpleText( ARCBank.ATMMsgs.Enter, "ARCBankATM",0, 140, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	else
		if self.InputSteamID then
			draw.SimpleText(self.InputSID..str, "ARCBankATMBigger", -98, 10 - shiftup, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		else
			draw.SimpleText(str, "ARCBankATMBigger", -98, 10 - shiftup, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		end
	end
	surface.SetDrawColor( textcol, textcol, textcol, 255 )
	surface.DrawOutlinedRect( -100, 1  - shiftup, 200, 18)
	--draw.SimpleText( self.InputMsg, "ARCBankATM",0, 125, Color(255,255,255,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
end

local transactionIcons = {}
transactionIcons[1] = "wallet"
transactionIcons[2] = "user_go"
transactionIcons[3] = "group_go" -- 2 but with group
transactionIcons[4] = "bank"
transactionIcons[8] = "add"
transactionIcons[16] = "delete"
transactionIcons[32] = "user_add"
transactionIcons[64] = "user_delete"
transactionIcons[128] = "new"
transactionIcons[256] = "bin"
transactionIcons[512] = "user_suit"
--[[
	self.NewLogTable = {}
	self.NewLogPage = 1
	self.NewLogPageMax = 1
]]
--money_add,money_delete,textfield,money
function ENT:Screen_NewLog()
	local textcol = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	local text_color = Color(textcol,textcol,textcol,255)
	
	--local filltextcol = 255*ARCLib.BoolToNumber(!ARCBank.ATM_DarkTheme)
	
	ARCBank_Draw:Window(-137,-150,254,280,self.RequestedAccountName.." - ("..self.NewLogPage.."/"..self.NewLogPageMax..")",ARCBank.ATM_DarkTheme,ARCLib.GetWebIcon16("file_extension_log"),self.ATMType.ForegroundColour)
	
	for i=1,5 do
		local y = (i-1)*48
		local entry = self.NewLogTable[(self.NewLogPage-1)*5+i]
		if entry then
			surface.SetDrawColor( 255,255,255,255 )
			surface.SetMaterial(ARCLib.GetWebIcon16("time"))
			surface.DrawTexturedRect( -135, -129+y, 12, 12)
			surface.SetDrawColor( text_color )
			surface.DrawOutlinedRect( -137, -131+y, 104, 16)
			draw.SimpleText(os.date("%Y-%m-%d %H:%M:%S",tonumber(entry.timestamp)),"ARCBankATMSmall", -36, -129+y, text_color, TEXT_ALIGN_RIGHT , TEXT_ALIGN_TOP  )
			
			surface.SetDrawColor( 255,255,255,255 )
			if entry.moneydiff < 0 then
				surface.SetMaterial(ARCLib.GetWebIcon16("money_delete"))
			else
				surface.SetMaterial(ARCLib.GetWebIcon16("money_add"))
			end
			surface.DrawTexturedRect( -32, -129+y, 12, 12)
			surface.SetDrawColor( text_color )
			surface.DrawOutlinedRect( -34, -131+y, 69, 16)
			draw.SimpleText(math.abs(entry.moneydiff),"ARCBankATMSmall", 32, -129+y, text_color, TEXT_ALIGN_RIGHT , TEXT_ALIGN_TOP  )
			
			surface.SetDrawColor( 255,255,255,255 )
			surface.SetMaterial(ARCLib.GetWebIcon16("money"))
			surface.DrawTexturedRect( 36, -129+y, 12, 12)
			surface.SetDrawColor( text_color )
			surface.DrawOutlinedRect( 34, -131+y, 103, 16)

			draw.SimpleText(entry.money or "","ARCBankATMSmall", 134, -129+y, text_color, TEXT_ALIGN_RIGHT , TEXT_ALIGN_TOP  )
			
			surface.SetDrawColor( 255,255,255,255 )
			surface.SetMaterial(ARCLib.GetWebIcon16(transactionIcons[entry.transaction_type+ARCLib.BoolToNumber(entry.transaction_type == 2 and string.sub(entry.account2,1,1) != "_")]))
			surface.DrawTexturedRect( -32, -129+15+y, 12, 12)
			surface.SetDrawColor( text_color )
			surface.DrawOutlinedRect( -137, -131+15+y, 104, 16)
			
			local txt = ""
			if entry.transaction_type == 1 then
				if entry.moneydiff < 0 then
					txt = ARCBank.Msgs.ATMMsgs.Withdrawal
				else
					txt = ARCBank.Msgs.ATMMsgs.Deposit
				end
			elseif entry.transaction_type == 2 then
				if string.sub(entry.account2,1,1) == "_" then
					txt = ARCLib.basexx.from_base32(string.upper(string.sub(entry.account2,2,#entry.account2-1)))
				else
					txt = ARCLib.basexx.from_base32(string.upper(string.sub(entry.account2,1,#entry.account2-1)))
				end
			elseif entry.transaction_type == 4 then
				txt = ARCBank.Msgs.AccountTransactions[4]
			elseif entry.transaction_type == 8 then
				txt = ARCBank.Msgs.LogMsgs.Upgraded
			elseif entry.transaction_type == 16 then
				txt = ARCBank.Msgs.LogMsgs.Downgraded
			elseif entry.transaction_type == 32 or entry.transaction_type == 64 then
				local otherply = ARCBank.GetPlayerByID(entry.user2)
				if IsValid(otherply) then
					txt = otherply:Nick()
				else
					txt = entry.user2
				end
			elseif entry.transaction_type == 128 then
				txt = ARCBank.Msgs.LogMsgs.Created
			elseif entry.transaction_type == 256 then
				txt = ARCBank.Msgs.LogMsgs.Deleted
			elseif entry.transaction_type == 512 then
				txt = ARCBank.Msgs.LogMsgs.Salary
			end
			draw.SimpleText(ARCLib.CutOutText(txt,"ARCBankATMSmall",252),"ARCBankATMSmall", -32+14, -129+15+y, text_color, TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			
			
			surface.SetDrawColor( 255,255,255,255 )
			surface.SetMaterial(ARCLib.GetWebIcon16("user"))
			surface.DrawTexturedRect( -135, -129+15+y, 12, 12)
			surface.SetDrawColor( text_color )
			local name = entry.user1
			local ply = ARCBank.GetPlayerByID(name)
			if IsValid(ply) then
				name = ply:Nick()
			end
			draw.SimpleText(ARCLib.CutOutText(name,"ARCBankATMSmall",88),"ARCBankATMSmall", -135 + 14, -129+15+y, text_color, TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			
			surface.SetDrawColor( 255,255,255,255 )
			surface.SetMaterial(ARCLib.GetWebIcon16("textfield"))
			surface.DrawTexturedRect( -135, -129+30+y, 12, 12)
			surface.SetDrawColor( text_color )
			surface.DrawOutlinedRect( -137, -131+30+y, 274, 16)
			draw.SimpleText(ARCLib.CutOutText(entry.comment,"ARCBankATMSmall",252),"ARCBankATMSmall", -135 + 14, -129+30+y, text_color, TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			
			surface.SetDrawColor( text_color )
			surface.DrawRect( -137, -131+46+y, 274, 2)
		end
		surface.DrawRect( -137, -131+240, 274, 3)
	end
	
	--[[
	surface.SetDrawColor( 255,255,255,255 )
	surface.SetMaterial(ARCLib.GetWebIcon16("money_add"))
	surface.DrawTexturedRect( -135, -129, 12, 12)
	surface.SetDrawColor( text_color )
	surface.DrawOutlinedRect( -137, -131, 16, 16)
	surface.SetDrawColor( 255,255,255,255 )
	surface.SetMaterial(ARCLib.GetWebIcon16("textfield"))
	surface.DrawTexturedRect( -135, -129+15, 12, 12)
	surface.SetDrawColor( text_color )
	surface.DrawOutlinedRect( -137, -131+15, 16, 16)
	
	]]
	
	
	surface.SetDrawColor( textcol, textcol, textcol, 255 )
	surface.DrawOutlinedRect( -137, 112, 274, 20)
	draw.SimpleText("<< "..ARCBank.Msgs.ATMMsgs.FilePrev,"ARCBankATMBigger", -135, 122, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  )
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.FileNext.." >>","ARCBankATMBigger", 135, 122, Color(textcol,textcol,textcol,255), TEXT_ALIGN_RIGHT , TEXT_ALIGN_CENTER  )
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.FileClose,"ARCBankATMBigger", 0, 140, Color(textcol,textcol,textcol,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  )
end
function ENT:Screen_Log()
	local textcol = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	--self.LogPage = 1
	--self.LogPageMax = 1
	
	ARCBank_Draw:Window(-137,-150,254,280,string.Replace(ARCBank.Msgs.ATMMsgs.File,"%PAGE%","("..self.LogPage.."/"..self.LogPageMax..")"),ARCBank.ATM_DarkTheme,ARCLib.GetIcon(1,"page"),self.ATMType.ForegroundColour)
	surface.SetDrawColor( textcol, textcol, textcol, 255 )
	surface.DrawOutlinedRect( -137, 112, 274, 20)
	for i = 1,20 do
		if self.LogTable[i+((self.LogPage-1)*20)] then
			draw.SimpleText(self.LogTable[i+((self.LogPage-1)*20)],"ARCBankATMSmall", -135, -130+(i*12), Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		end
	end
	draw.SimpleText("<< "..ARCBank.Msgs.ATMMsgs.FilePrev,"ARCBankATMBigger", -135, 122, Color(textcol,textcol,textcol,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  )
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.FileNext.." >>","ARCBankATMBigger", 135, 122, Color(textcol,textcol,textcol,255), TEXT_ALIGN_RIGHT , TEXT_ALIGN_CENTER  )
	draw.SimpleText(ARCBank.Msgs.ATMMsgs.FileClose,"ARCBankATMBigger", 0, 140, Color(textcol,textcol,textcol,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  )
end
function ENT:Screen_Options()
	local light = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	local darkk = 255*ARCLib.BoolToNumber(!ARCBank.ATM_DarkTheme)
	local halfres = math.Round(self.ATMType.Resolutionx*0.5)
	ARCBank_Draw:Window_MsgBox((halfres*-1)+2,-150,self.ATMType.Resolutionx-24,self.Title,self.TitleText,ARCBank.ATM_DarkTheme,0,ARCLib.GetIcon(2,self.TitleIcon),nil,self.ATMType.ForegroundColour)

	for i = 1,8 do
		if self.ScreenOptions[i+(self.Page*8)] then
			local xpos = 0
			if i%2 == 0 then
				xpos = (halfres*-1)+2
			else
				xpos = halfres - 136
			end
			local ypos = -80+((math.floor((i-1)/2))*61)
			local fitstr = ARCLib.FitText(self.ScreenOptions[i+(self.Page*8)].text,"ARCBankATMNormal",98)
			surface.SetDrawColor( darkk, darkk, darkk, 255 )
			surface.DrawRect( xpos, ypos, 134, 40)
			surface.SetDrawColor( light, light, light, 255 )
			surface.DrawOutlinedRect( xpos, ypos, 134, 40)
			for ii = 1,#fitstr do
				draw.SimpleText( fitstr[ii], "ARCBankATMNormal",xpos+37+((i%2)*63), ypos+((ii-1)*12), Color(light,light,light,255), (i%2)*2 , TEXT_ALIGN_TOP  )
			end
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial(ARCLib.GetIcon(2,self.ScreenOptions[i+(self.Page*8)].icon))
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
		if (self.ATMType.UseTouchScreen && self.Percent == 0) then return end
		ARCBank_Draw:Window(-125, -60, 230, 70,ARCBank.Msgs.ATMMsgs.Loading,ARCBank.ATM_DarkTheme,nil,self.ATMType.ForegroundColour)

		surface.SetDrawColor( 255, 255, 255, 200 )
		
		surface.SetMaterial( ARCLib.GetIcon(2,"hourglass") )
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

local hexarr = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

function ENT:Screen_HAX()
	local hackmsg = ""
	if self.Percent < math.Rand(0.50,0.75) then
		hackmsg = "Decoding Security Syetem"
		for i=-12,13 do
			if (self.Percent) > 0.005 then
				draw.SimpleText( ARCLib.RandomString(math.floor(self.ATMType.Resolutionx*ARCLib.BetweenNumberScale(0.005,self.Percent,0.1)/7),hexarr), "ARCBankATM",self.ATMType.Resolutionx/-2, i*12, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
			end
		end
	else
		
		--hackmsg = "Accesing Network..."
		
		draw.SimpleText( "Using username \"root\"", "ARCBankATM",self.ATMType.Resolutionx/-2, -140, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		draw.SimpleText( "Authenticating...", "ARCBankATM",self.ATMType.Resolutionx/-2, -124, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		draw.SimpleText( "Login Successful!", "ARCBankATM",self.ATMType.Resolutionx/-2, -108, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		draw.SimpleText( "**ARCBank ATM**", "ARCBankATM",self.ATMType.Resolutionx/-2, -92, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		if self.HackCompleted then
			draw.SimpleText( "root@atm_"..self:EntIndex()..":~# mount /dev/sdb1 /mnt", "ARCBankATM",self.ATMType.Resolutionx/-2, -76, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
			draw.SimpleText( "root@atm_"..self:EntIndex()..":~# /mnt/atm_money_stealer", "ARCBankATM",self.ATMType.Resolutionx/-2, -60, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
			if self.HackRandom then
				draw.SimpleText( "Targetting ARCBank system...", "ARCBankATM",self.ATMType.Resolutionx/-2, -44, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
			else
				draw.SimpleText( "Withdrawing cash from random account...", "ARCBankATM",self.ATMType.Resolutionx/-2, -44, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
			end
		else
			draw.SimpleText( "root@atm_"..tostring(self:EntIndex())..":~#", "ARCBankATM",self.ATMType.Resolutionx/-2, -76, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		end
	end
	--[[
	ARCBank_Draw:Window(-136, -150, 252, 20,ARCLib16["application"],"ATM_CRACKER")
	draw.SimpleText( hackmsg, "ARCBankATMBigger",0, -120, Color(0,0,0,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  )
	]]
end
net.Receive( "arcbank_atm_reboot", function(length,ply)
	local enti = net.ReadUInt(16)
	local ent = Entity(enti)
	local stuff = {}
	stuff.Broken = net.ReadBool()
	stuff.RebootTime = net.ReadDouble()
	--MsgN(ent)
	--PrintTable(stuff)
	if IsValid(ent) then
		table.Merge( ent, stuff )
		ent.MsgBox = {}
		ent.MsgBox.Title = ""
		ent.MsgBox.Text = ""
		ent.MsgBox.TitleIcon = ""
		ent.MsgBox.TextIcon = ""
		ent.MsgBox.Type = 0
		ent.MsgBox.GreenFunc = function() self.MsgBox.Type = 0 end
		ent.MsgBox.RedFunc = function() self.MsgBox.Type = 0 end
		ent.MsgBox.YellowFunc = function() self.MsgBox.Type = 0 end
		if (!stuff.Broken) then
			ent.TouchScreenX = 0
			ent.TouchScreenY = 0
		end
	else
		brokenATMs[enti] = stuff
	end
end)
function ENT:Hackable()
	return !self.Broken && self.RebootTime < CurTime()
end
function ENT:HackStop()
	self.Percent = 0
	self.Hacked = false

end
function ENT:HackStart()
	self.Hacked = true
	self.HackAmount = false
	self.HackCompleted = false
end
function ENT:HackSpark()

end
function ENT:HackProgress(per)
	self.Percent = per
end
function ENT:HackComplete(ply,amount,rand)
	self.Percent = 1
	self.HackAmount = amount
	self.HackRandom = rand
	timer.Simple(math.Rand(0.5,3),function()
		if !IsValid(self) then return end
		self.HackCompleted = true
	end)
	
end


function ENT:Screen_Main()
	--if LocalPlayer():GetEyeTrace().Entity == self then
		--end
		local maxx = self.ATMType.Resolutionx/2
		local maxy = self.ATMType.Resolutiony/2
		local minx = self.ATMType.Resolutionx/-2
		local miny = self.ATMType.Resolutiony/-2
		
		if (self.Hacked && self.Percent == 1) || (self.RebootTime - 3 > CurTime())then
			surface.SetDrawColor( 10, 10, 10, 255 )
			surface.DrawOutlinedRect( (self.ATMType.Resolutionx+2)/-2, (self.ATMType.Resolutiony+2)/-2, self.ATMType.Resolutionx+2, self.ATMType.Resolutiony+2 ) 
			surface.SetDrawColor( 0, 0, 0, 255 )
		else
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawOutlinedRect( (self.ATMType.Resolutionx+2)/-2, (self.ATMType.Resolutiony+2)/-2, self.ATMType.Resolutionx+2, self.ATMType.Resolutiony+2 ) 
			surface.SetDrawColor( ARCLib.ConvertColor(self.ATMType.BackgroundColour))
		end

		surface.DrawRect( self.ATMType.Resolutionx/-2, self.ATMType.Resolutiony/-2, self.ATMType.Resolutionx, self.ATMType.Resolutiony ) 
		
		if self.Hacked then
			self:Screen_HAX()
		end
		
		if self.InUse then
			if self.LogTable[1] != nil then
				self:Screen_Log()
			elseif self.NewLogTable[1] != nil then
				self:Screen_NewLog()
			else
				self:Screen_Options()
			end
		else
			if self.RebootTime - 0.3214 < CurTime() then
				if not self.Hacked or self.Percent < math.Rand(0.25,0.5) then
					self:Screen_Welcome()
				end
			end
		end
		if self.InputtingNumber then
			self:Screen_Number()
		end
		if self.MsgBox && self.MsgBox.Type > 0 then
			self.boxY,self.boxGX,self.boxRX,self.boxYX = ARCBank_Draw:Window_MsgBox(-130,-90,240,self.MsgBox.Title,self.MsgBox.Text,ARCBank.ATM_DarkTheme,self.MsgBox.Type,ARCLib.GetIcon(2,self.MsgBox.TextIcon),ARCLib.GetIcon(1,self.MsgBox.TitleIco),self.ATMType.ForegroundColour)
		end
		if self.RebootTime -7 < CurTime() && self.RebootTime > CurTime() then
			ARCBank_Draw:Window_MsgBox(-125,-40,230,ARCBank.Settings.name,"System is starting up!",ARCBank.ATM_DarkTheme,0,ARCLib.GetIcon(2,"information"),nil,self.ATMType.ForegroundColour)
		end
		if self.Broken then
			ARCBank_Draw:Window_MsgBox(-125,-40,230,"Criticao EräÞr",ARCBank.Msgs.ATMMsgs.HackingError,ARCBank.ATM_DarkTheme,0,ARCLib.GetIcon(2,"emotion_dead"),nil,self.ATMType.ForegroundColour)
		end
		if self.Loading then
			self:Screen_Loading()
		end
		
		if !self.ARCBankLoaded then
			ARCBank_Draw:Window_MsgBox(-120,-50,220,ARCBank.Msgs.ATMMsgs.NetworkErrorTitle,ARCBank.Msgs.ATMMsgs.NetworkError,ARCBank.ATM_DarkTheme,0,ARCLib.GetIcon(2,"server_error"),nil,self.ATMType.ForegroundColour)
		end
		if self.ATMType.UseTouchScreen && self.RebootTime -7.1 < CurTime() && !self.Hacked then
			self:Screen_Touch()
		end
		--ARCBank_Draw:Window_MsgBox(-120,-50,220,"","Hello\nBob!\n!!!! Wow this is cool! It supports \n and everything!",false,0,ARCLib.GetIcon(2,"cancel"),nil)
		if self.Hacked then
			if self.Percent > 0.0415 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-120,-50,220,"/usr/bin/arcbank-client","",ARCBank.ATM_DarkTheme,1,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.0515 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-120,-50,220,"/usr/bin/arcbank-client","sudo: user is not in the sudoers file. This incident will be reported.",ARCBank.ATM_DarkTheme,1,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.1 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-150,250,"Segmentation fault","The instruction at '0x18a5ef73' referenced memory at '0x28fe5a7c'. \nThe memory could not be written.",ARCBank.ATM_DarkTheme,6,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.12 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-120,250,"Segmentation fault","The instruction at '0x28fe5a7c' referenced memory at '0x04d42f78'. \nThe memory could not be written.",ARCBank.ATM_DarkTheme,6,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.14 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-90,250,"Segmentation fault","The instruction at '0x28fe5a7c' referenced memory at '0x00000000'. \nThe memory could not be read.",ARCBank.ATM_DarkTheme,6,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.16 && self.Percent < 1 then
				ARCBank_Draw:Window_MsgBox(-135,-60,250,"Segmentation fault","The instruction at '0x00000000' referenced memory at '0xffffffff'. \nThe memory could not be read.",ARCBank.ATM_DarkTheme,6,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
			end
			if self.Percent > 0.18 && self.Percent < 1 then
				if self.Percent < 0.25 then
					ARCBank_Draw:Window_MsgBox(-110,-30,200,"","SECURITY ERROR! Arbitrary memory access detected.",ARCBank.ATM_DarkTheme,1,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
				else
					ARCBank_Draw:Window_MsgBox(-110,-30,200,"",table.Random({"UNKNOWN ERROR!\nUNKNOWN ERROR!\nUNKNOWN ERROR!\nUNKNOWN ERROR!","ERROR: P3N15","^&*DGY*SGY *7fg8egg8y f87a t8G**^SFG8g f6g8 8^T*98ds//f a78","BDSM GEY BUTTSECKS","HAAAAAAX!!\nDUH HAAAAAX!"}),ARCBank.ATM_DarkTheme,1,ARCLib.GetIcon(2,"cancel"),nil,self.ATMType.ForegroundColour)
				end
			end
			
			--self:Screen_Loading()
			if self.Percent < 0.999 then
				local xpos
				local ypos
				local maxw
				local maxh
				for i=1,math.random(self.Percent*100,self.Percent*200) do
					surface.SetDrawColor( 0, 0, 0, 255 )
					xpos = math.random((self.ATMType.Resolutionx/-2)-20,10)
					ypos = math.random(self.ATMType.Resolutiony/-2,self.ATMType.Resolutiony/2)
					maxw = self.ATMType.Resolutionx/2 - xpos
					maxh = self.ATMType.Resolutiony/2 - ypos + 1
					--MsgN(maxw)
					surface.DrawRect( math.Clamp(xpos,-self.ATMType.Resolutionx/2,maxw), ypos, math.Clamp(math.random(0,self.ATMType.Resolutionx),0,maxw), math.Clamp(math.random(0,40)*self.Percent,0,maxh) )
				end
			end
		end
end

local touchPadIcons = {}
touchPadIcons[0] = "tick"
touchPadIcons[1] = "button_navigation_back"
touchPadIcons[2] = "cross"

function ENT:Screen_Touch()
	local len = 0
	local maxx = self.ATMType.Resolutionx/2
	local maxy = self.ATMType.Resolutiony/2
	local minx = self.ATMType.Resolutionx/-2
	local miny = self.ATMType.Resolutiony/-2
	local light = 255*ARCLib.BoolToNumber(ARCBank.ATM_DarkTheme)
	local darkk = 255*ARCLib.BoolToNumber(!ARCBank.ATM_DarkTheme)
	local halfres = math.Round(self.ATMType.Resolutionx*0.5)
	self.Highlightbutton = -1
	if !self.Loading then
		if false then
		
		elseif self.MsgBox && self.MsgBox.Type > 0 && self.boxY then
			if (self.boxGX) then
				len = len + 1
				self.TouchIcons[len] = self.TouchIcons[len] || {}
				self.TouchIcons[len].x = self.boxGX
				self.TouchIcons[len].y = self.boxY
				self.TouchIcons[len].w = 70
				self.TouchIcons[len].h = 20
				self.TouchIcons[len].button = 10
			end
			if (self.boxRX) then
				len = len + 1
				self.TouchIcons[len] = self.TouchIcons[len] || {}
				self.TouchIcons[len].x = self.boxRX
				self.TouchIcons[len].y = self.boxY
				self.TouchIcons[len].w = 70
				self.TouchIcons[len].h = 20
				self.TouchIcons[len].button = 12
			end
			if (self.boxYX) then
				len = len + 1
				self.TouchIcons[len] = self.TouchIcons[len] || {}
				self.TouchIcons[len].x = self.boxYX
				self.TouchIcons[len].y = self.boxY
				self.TouchIcons[len].w = 70
				self.TouchIcons[len].h = 20
				self.TouchIcons[len].button = 11
			end
		elseif self.InputtingNumber then
			
			ARCBank_Draw:Window(-80, -28, 160 - 22, 146,"Touch Keypad",ARCBank.ATM_DarkTheme,ARCLib.GetIcon(1,"keyboard"),self.ATMType.ForegroundColour)
			surface.SetDrawColor( light, light, light, 255 )
			
			for i=0,8 do
				len = len + 1
				self.TouchIcons[len] = self.TouchIcons[len] || {}
				self.TouchIcons[len].x = i%3*32 - 70
				self.TouchIcons[len].y = math.floor(i/3)*32
				self.TouchIcons[len].w = 32
				self.TouchIcons[len].h = 32
				self.TouchIcons[len].button = i+1
				surface.DrawOutlinedRect( self.TouchIcons[len].x, self.TouchIcons[len].y, 32, 32)
				draw.SimpleText(i+1, "ARCBankATMBigger",  self.TouchIcons[len].x + 16, self.TouchIcons[len].y + 16, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
			end
			len = len + 1
			self.TouchIcons[len] = self.TouchIcons[len] || {}
			self.TouchIcons[len].x = 32 - 70
			self.TouchIcons[len].y = 96
			self.TouchIcons[len].w = 32
			self.TouchIcons[len].h = 32
			self.TouchIcons[len].button = 0
			surface.DrawOutlinedRect( 32 - 70, 96, 32, 32)
			draw.SimpleText(0, "ARCBankATMBigger",  32 - 70 + 16, 96 + 16, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 

			
			for i=0,2 do
				surface.SetDrawColor(light,light,light,255)
				surface.DrawOutlinedRect( 37, i*32, 32, 32)
				len = len + 1
				self.TouchIcons[len] = self.TouchIcons[len] || {}
				self.TouchIcons[len].x = 37
				self.TouchIcons[len].y = i*32
				self.TouchIcons[len].w = 32
				self.TouchIcons[len].h = 32
				self.TouchIcons[len].button = i + 10
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(ARCLib.GetIcon(1,touchPadIcons[i]))
				surface.DrawTexturedRect( 37 + 8, i*32 + 8, 16, 16)
			end
		elseif self.LogTable[1] != nil or self.NewLogTable[1] != nil then
			len = len + 1
			self.TouchIcons[len] = self.TouchIcons[len] || {}
			self.TouchIcons[len].x = 8
			self.TouchIcons[len].y = 112
			self.TouchIcons[len].w = 128
			self.TouchIcons[len].h = 20
			self.TouchIcons[len].button = 19
			len = len + 1
			self.TouchIcons[len] = self.TouchIcons[len] || {}
			self.TouchIcons[len].x = -112-24
			self.TouchIcons[len].y = 112
			self.TouchIcons[len].w = 128
			self.TouchIcons[len].h = 20
			self.TouchIcons[len].button = 20
			len = len + 1
			self.TouchIcons[len] = self.TouchIcons[len] || {}
			self.TouchIcons[len].x = -128
			self.TouchIcons[len].y = 132
			self.TouchIcons[len].w = 256
			self.TouchIcons[len].h = 18
			self.TouchIcons[len].button = 12
		else
			for i = 1,8 do
				if self.ScreenOptions[i+(self.Page*8)] then
					local xpos = 0
					if i%2 == 0 then
						xpos = (halfres*-1)+2
					else
						xpos = halfres - 136
					end
					local ypos = -80+((math.floor((i-1)/2))*61)
					local fitstr = ARCLib.FitText(self.ScreenOptions[i+(self.Page*8)].text,"ARCBankATMNormal",98)
					len = len + 1
					self.TouchIcons[len] = self.TouchIcons[len] || {}
					self.TouchIcons[len].x = xpos
					self.TouchIcons[len].y = ypos
					self.TouchIcons[len].w = 134
					self.TouchIcons[len].h = 40
					self.TouchIcons[len].button = i + 12
				end
			end
		end
	end
	
	for i=1,len do
		if ARCLib.InBetween(self.TouchIcons[i].x,self.TouchScreenX,self.TouchIcons[i].x+self.TouchIcons[i].w) && ARCLib.InBetween(self.TouchIcons[i].y,self.TouchScreenY,self.TouchIcons[i].y+self.TouchIcons[i].h) then
			surface.SetDrawColor(light,light,light,128)
			surface.DrawRect(self.TouchIcons[i].x,self.TouchIcons[i].y,self.TouchIcons[i].w,self.TouchIcons[i].h)

			self.Highlightbutton = self.TouchIcons[i].button
			break
		end
	end
	surface.SetMaterial(ARCLib.GetIcon(1,"cursor"))
	surface.SetDrawColor(255,255,255,255)
	if self.Loading || self.RebootTime + 0.5 > CurTime() then
		surface.SetMaterial(ARCLib.GetIcon(1,"hourglass"))
		surface.DrawTexturedRectRotated(math.Clamp(self.TouchScreenX,minx+8,maxx-8),math.Clamp(self.TouchScreenY,miny+8,maxy-8),16,16,270 - ((math.sin(CurTime()*2) * math.sin(CurTime()) + math.cos(CurTime()))*75)) 
	else
		surface.SetMaterial(ARCLib.GetIcon(1,"cursor"))
		surface.DrawTexturedRect(math.Clamp(self.TouchScreenX-3,minx,maxx-16),math.Clamp(self.TouchScreenY,miny,maxy-16),16,16)
	end
end

function ENT:DrawHolo()--Good
	if self.Hacked && math.random(1,3) == 1 then
		draw.SimpleText(tostring(ARCBank.Settings["atm_holo_text"]), "ARCBankHolo",math.Rand(-4,4), math.Rand(0,0.5), Color(255,255,255,math.random(5,180)), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	else
		draw.SimpleText(tostring(ARCBank.Settings["atm_holo_text"]), "ARCBankHolo",0,0, Color(255,255,255,175), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
	end
	--[[
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetTexture( asdqwefwqaf )
	surface.DrawTexturedRect( -128, -128, 256, 256)
	]]
end

local vector_up = Vector(0,0,1)
net.Receive( "ARCATM_COMM_BEEP", function(length,ply)
	net.ReadEntity().BEEP = tobool(net.ReadBit())
end)
function ENT:Draw()--Good
	self:DrawModel()
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 2000000 then return end
	self:DrawShadow( true )
	if !self.ATMType then return end
	if ARCBank.Settings["atm_holo"] then
		self.HoloPos = self:LocalToWorld(self:OBBCenter()+(self:OBBMaxs()-self:OBBMins())*0.5*vector_up+Vector(0,0,(8+math.sin(CurTime()*1)*3)))
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
	if self.Hacked && self.Percent > math.Rand(0.111,0.325) && self.Percent < 1 then
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
	if (self.Hacked && self.Percent == 1) || (self.RebootTime - 3 > CurTime())then
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
	if self.BEEP && self.ATMType.UseMoneylight then
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
		if self.ATMType.UseCardlight && math.sin((CurTime()+(self:EntIndex()/50))*math.pi*2) > 0 && self.ARCBankLoaded && self.RebootTime < CurTime() then
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
	local ply = LocalPlayer()
	self.CurPos = ply:GetEyeTrace().HitPos
	if self.ATMType.UseTouchScreen then
		if !ply.ARCBank_FullScreen then
			local pos = util.IntersectRayWithPlane( ply:GetShootPos(), ply:GetAimVector(), self:LocalToWorld(self.ATMType.Screen), self:LocalToWorldAngles(self.ATMType.ScreenAng):Up() ) 
			if pos then
				--local adjhit = self:WorldToLocal(hit)-self.ATMType.Screen
				pos = WorldToLocal( pos, self:LocalToWorldAngles(self.ATMType.ScreenAng), self:LocalToWorld(self.ATMType.Screen), self:LocalToWorldAngles(self.ATMType.ScreenAng) ) 
				self.TouchScreenX = pos.x/self.ATMType.ScreenSize
				self.TouchScreenY = pos.y/-self.ATMType.ScreenSize
			end
		end
	else
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
	end
	--self.UseButton = self.Highlightbutton
	if self.Highlightbutton >= 0 && ply:GetShootPos():Distance(self.CurPos) < 70 then
		if !self.ATMType.UseTouchScreen then
			render.DrawSprite(self.buttonpos[self.Highlightbutton], 6.5, 6.5, Color(255,255,255,255))
		end
		local pushedbutton
		if ply.ARCBank_FullScreen then
			pushedbutton = input.IsMouseDown(MOUSE_LEFT)
		else
			pushedbutton = --[[ply:KeyDown(IN_USE)||]]ply:KeyReleased(IN_USE)||ply:KeyDownLast(IN_USE)
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
	if #self.NewLogTable > 0 then
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
	if #self.NewLogTable > 0 then
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
	if #self.NewLogTable > 0 then
		self.NewLogTable = {}
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
	if #self.NewLogTable > 0 then
		if butt == 7 then --Next
			self:EmitSoundTable(self.ATMType.ClientPressSound)
			ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
			if self.NewLogPage < self.NewLogPageMax then
				self.NewLogPage = self.NewLogPage + 1
			end
		elseif butt == 8 then --Prev
			self:EmitSoundTable(self.ATMType.ClientPressSound)
			ARCLib.PlaySoundOnOtherPlayers(table.Random(self.ATMType.PressSound),self,65)
			if self.NewLogPage > 1 then
				self.NewLogPage = self.NewLogPage - 1
			end
		else
			self:EmitSoundTable(self.ATMType.PressNoSound,65)
		end
		return
	end
	local num = butt+(self.Page*8)
	if self.ScreenOptions[num] then
		self.ScreenOptions[num].func(num)
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
					local atms = ents.FindByClass("sent_arc_atm")
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
		timer.Simple(atm.ATMType.CardInsertAnimationLength,function()
			if IsValid(atm) then
				atm:HomeScreen()
			end
		end)
		timer.Simple(atm.ATMType.CardInsertAnimationLength+0.5,function()
			if IsValid(atm) then
				atm.Loading = false
			end
		end)
		--[[
		timer.Simple(atm.ATMType.CardInsertAnimationLength+2,function()
			if IsValid(atm) then
				--ENT:NewMsgBox(title,text,titleicon,texticon,butt,greenf,redf,yellowf)
				--asdf
				atm:NewMsgBox("ASSHOLE","You are an asshole.",nil,"hand_fuck",6)
				atm:EmitSoundTable(atm.ATMType.ErrorSound,67)
				ARCLib.PlaySoundOnOtherPlayers(table.Random(atm.ATMType.ErrorSound),atm,65)
			end
		end)
		]]
	else
		gui.EnableScreenClicker( false ) 
		LocalPlayer().ARCBank_UsingATM = false
		LocalPlayer().ARCBank_ATM = NULL
		if IsValid(atm) then
			atm.InputtingNumber = false
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

