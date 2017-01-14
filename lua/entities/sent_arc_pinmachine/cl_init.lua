-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.
include('shared.lua')
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.ScreenMsg = {}
function ENT:Initialize()
	self.SScreenScroll = 1
	self.SScreenScrollDelay = CurTime() + 0.1
	self.ScreenScroll = 1
	self.ScreenScrollDelay = CurTime() + 0.1
	self.TopScreenText = "**ARCBank**"
	self.BottomScreenText = ARCBank.Msgs.CardMsgs.NoOwner
	net.Start( "ARCCHIPMACHINE_STRINGS" )
	net.WriteEntity(self.Entity)
	net.SendToServer()
	self.FromAccount = ARCBank.Msgs.ATMMsgs.PersonalAccount
	self.ToAccount = ARCBank.Msgs.ATMMsgs.PersonalAccount
	self.InputNum = 0
	self.Reason = ARCBank.Msgs.Items.PinMachine
end

function ENT:Think()

end


function ENT:Draw()
	self:DrawModel()
	self:DrawShadow( true )
	self.DisplayPos = self:GetPos() + ((self:GetAngles():Up() * 1.005) + (self:GetAngles():Forward() * -4.01) + (self:GetAngles():Right()*2.55))
	self.displayangle1 = self:GetAngles()
	self.displayangle1:RotateAroundAxis( self.displayangle1:Up(), 90 )
	--self.displayangle1:RotateAroundAxis( self.displayangle1:Forward(), -13 )
	if #self.BottomScreenText > 0 then
		if self.ScreenScrollDelay < CurTime() && utf8.len(self.BottomScreenText) > 11 then
			self.ScreenScrollDelay = CurTime() + 0.1
			self.ScreenScroll = self.ScreenScroll + 1
			if (self.ScreenScroll) > utf8.len(self.BottomScreenText) then
				self.ScreenScroll = -11
			end
		end
	end
	if #self.TopScreenText > 0 then
		if self.SScreenScrollDelay < CurTime() && utf8.len(self.TopScreenText) > 11 then
			self.SScreenScrollDelay = CurTime() + 0.1
			self.SScreenScroll = self.SScreenScroll + 1
			if (self.SScreenScroll) > utf8.len(self.TopScreenText) then
				self.SScreenScroll = -11
			end
		end
	end
	cam.Start3D2D(self.DisplayPos, self.displayangle1, 0.055)
			surface.SetDrawColor( 0, 255, 0, 200 )
			surface.DrawRect( 0, 0, 77, 24 ) 
			if utf8.len(self.TopScreenText) > 11 then
				draw.SimpleText( ARCLib.ScrollChars(self.TopScreenText,self.SScreenScroll,11), "ARCBankATM",0,0, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			else
				draw.SimpleText( self.TopScreenText, "ARCBankATM",0,0, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			end
			if utf8.len(self.BottomScreenText) > 11 then
				draw.SimpleText( ARCLib.ScrollChars(self.BottomScreenText,self.ScreenScroll,11), "ARCBankATM",0,12, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			else
				draw.SimpleText( self.BottomScreenText, "ARCBankATM",0,12, Color(0,0,0,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
			end
	cam.End3D2D()
end
--lollolol
net.Receive( "ARCCHIPMACHINE_STRINGS", function(length)
	local ent = net.ReadEntity()
	local topstring = net.ReadString()
	local bottomstring = net.ReadString()
	local ply = net.ReadEntity()
	ent.TopScreenText = topstring
	ent.BottomScreenText = bottomstring
	ent.ScreenScroll = 11
	ent.SScreenScroll = 11
	ent._Owner = ply
end)
net.Receive( "ARCCHIPMACHINE_MENU_CUSTOMER", function(length)
	local ent = net.ReadEntity()
	local accounts = net.ReadTable()
	local moneh = net.ReadFloat()
	if ent.FromAccount == "" then
		ent.FromAccount = ARCBank.Msgs.ATMMsgs.PersonalAccount
	end
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetPos( surface.ScreenWidth()/2-130,surface.ScreenHeight()/2-100 )
	DermaPanel:SetSize( 260, 104 )
	DermaPanel:SetTitle( ARCBank.Msgs.CardMsgs.AccountPay )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( false )
	DermaPanel:MakePopup()
	local NumLabel2 = vgui.Create( "DLabel", DermaPanel )
	NumLabel2:SetPos( 10, 26 )
	NumLabel2:SetText( string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", string.Comma(moneh)) )
	NumLabel2:SizeToContents()
	local AccountSelect = vgui.Create( "DComboBox", DermaPanel )
	AccountSelect:SetPos( 10,44 )
	AccountSelect:SetSize( 240, 20 )
	function AccountSelect:OnSelect(index,value,data)
		ent:EmitSound("buttons/button18.wav",75,255)
		ent.FromAccount = value
	end--$é
	AccountSelect:SetText(ent.FromAccount or ARCBank.Msgs.ATMMsgs.PersonalAccount)
	for i=1,#accounts do
		AccountSelect:AddChoice(accounts[i])
	end
	local OkButton = vgui.Create( "DButton", DermaPanel )
	OkButton:SetText( ARCBank.Msgs.ATMMsgs.OK )
	OkButton:SetPos( 10, 74 )
	OkButton:SetSize( 115, 20 )
	OkButton.DoClick = function()
		ent:EmitSound("buttons/button18.wav",75,255)
		DermaPanel:Remove()
		if ent.FromAccount == ARCBank.Msgs.ATMMsgs.PersonalAccount then
			ent.FromAccount = ""
		end
		net.Start( "ARCCHIPMACHINE_MENU_CUSTOMER" )
		net.WriteEntity(ent)
		net.WriteString(ent.FromAccount)
		net.SendToServer()
	end
	local CancelButton = vgui.Create( "DButton", DermaPanel )
	CancelButton:SetText( ARCBank.Msgs.ATMMsgs.Cancel )
	CancelButton:SetPos( 135, 74 )
	CancelButton:SetSize( 115, 20 )
	CancelButton.DoClick = function()
		DermaPanel:Remove()
	end
end)
net.Receive( "ARCCHIPMACHINE_MENU_OWNER", function(length)
	local ent = net.ReadEntity()
	local accounts = net.ReadTable()
	if ent.ToAccount == "" then
		ent.ToAccount = ARCBank.Msgs.ATMMsgs.PersonalAccount
	end
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetPos( surface.ScreenWidth()/2-130,surface.ScreenHeight()/2-120 )
	DermaPanel:SetSize( 260, 240 )
	DermaPanel:SetTitle( ARCBank.Msgs.Items.PinMachine )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( false )
	DermaPanel:MakePopup()
	local NumLabel1 = vgui.Create( "DLabel", DermaPanel )
	NumLabel1:SetPos( 10, 25 )
	NumLabel1:SetText( ARCBank.Msgs.CardMsgs.Charge )
	NumLabel1:SizeToContents()
	
	
	local EnterNum = vgui.Create( "DNumberWang", DermaPanel )
	EnterNum:SetPos( 76, 40 )
	EnterNum:SetSize( 175, 20 )
	EnterNum:SetMinMax( 0 , 2147483647)
	EnterNum:SetDecimals(0)
	EnterNum.OnValueChanged = function( pan, val )
		ent.InputNum = val
	end
	EnterNum:SetValue( ent.InputNum )
	local ErrorLabel = vgui.Create( "DLabel", DermaPanel )
	ErrorLabel:SetPos( 76, 64 )
	ErrorLabel:SetText( "" )
	ErrorLabel:SetSize( 175, 50 )
	ErrorLabel:SetWrap(true)
	local button = {}
	for i=1,12 do
		button[i] = vgui.Create( "DButton", DermaPanel )
		if i == 10 then
			button[i]:SetText( "<--" )
			button[i].DoClick = function()
				ent:EmitSound("buttons/button18.wav",75,255)
				ent.InputNum = math.floor(ent.InputNum/10)
				EnterNum:SetValue( ent.InputNum )
			end
		elseif i == 11 then
			button[i]:SetText( "0" )
			button[i].DoClick = function()
				ent:EmitSound("buttons/button18.wav",75,255)
				if (ent.InputNum*10) >= 2^31 then
					ErrorLabel:SetText( string.Replace( ARCBank.Msgs.ATMMsgs.NumberTooHigh, "%NUM%", string.Comma(2^31-1)) )
					return
				end
				ent.InputNum = (ent.InputNum*10)
				EnterNum:SetValue( ent.InputNum )
			end
		elseif i== 12 then
			button[i]:SetText( "X" )
			button[i].DoClick = function()
				ent:EmitSound("buttons/button18.wav",75,255)
				ent.InputNum = 0
				EnterNum:SetValue( ent.InputNum )
			end
		else
			button[i]:SetText( tostring(i) )
			button[i].DoClick = function()
				ent:EmitSound("buttons/button18.wav",75,255)
				if ((ent.InputNum*10) + i) >= 2^31 then
					ErrorLabel:SetText( string.Replace( ARCBank.Msgs.ATMMsgs.NumberTooHigh, "%NUM%", string.Comma(2^31-1)) )
					return
				end
				ent.InputNum = (ent.InputNum*10) + i
				EnterNum:SetValue( ent.InputNum )
			end
		end
		button[i]:SetSize( 20, 20 )
		button[i]:SetPos( 10+(20*((i-1)%3)), 40+(20*math.floor((i-1)/3)) )
	end
	local NumLabel2 = vgui.Create( "DLabel", DermaPanel )
	NumLabel2:SetPos( 10, 122 )
	NumLabel2:SetText( ARCBank.Msgs.CardMsgs.Account )
	NumLabel2:SizeToContents()
	local AccountSelect = vgui.Create( "DComboBox", DermaPanel )
	AccountSelect:SetPos( 10,140 )
	AccountSelect:SetSize( 240, 20 )
	function AccountSelect:OnSelect(index,value,data)
		ent:EmitSound("buttons/button18.wav",75,255)
		ent.ToAccount = value
	end
	AccountSelect:SetText(ent.ToAccount or ARCBank.Msgs.ATMMsgs.PersonalAccount)
	for i=1,#accounts do
		AccountSelect:AddChoice(accounts[i])
	end
	local NumLabel3 = vgui.Create( "DLabel", DermaPanel )
	NumLabel3:SetPos( 10, 162 )
	NumLabel3:SetText( ARCBank.Msgs.CardMsgs.Label )
	NumLabel3:SizeToContents()
	local ReasonSelect = vgui.Create( "DTextEntry", DermaPanel )
	ReasonSelect:SetPos( 10,180 )
	ReasonSelect:SetTall( 20 )
	ReasonSelect:SetWide( 240 )
	ReasonSelect:SetEnterAllowed( true )
	ReasonSelect:SetValue(ent.Reason)
	local OkButton = vgui.Create( "DButton", DermaPanel )
	OkButton:SetText( ARCBank.Msgs.ATMMsgs.OK )
	OkButton:SetPos( 10, 210 )
	OkButton:SetSize( 115, 20 )
	OkButton.DoClick = function()
		ent:EmitSound("buttons/button18.wav",75,255)
		DermaPanel:Remove()
		if ent.ToAccount == ARCBank.Msgs.ATMMsgs.PersonalAccount then
			ent.ToAccount = ""
		end
		net.Start( "ARCCHIPMACHINE_MENU_OWNER" )
		net.WriteEntity(ent)
		net.WriteString(ent.ToAccount)
		net.WriteInt(ent.InputNum,32)
		net.WriteString(ent.Reason)
		net.SendToServer()
	end
	local CancelButton = vgui.Create( "DButton", DermaPanel )
	CancelButton:SetText( ARCBank.Msgs.ATMMsgs.Cancel )
	CancelButton:SetPos( 135, 210 )
	CancelButton:SetSize( 115, 20 )
	CancelButton.DoClick = function()
		DermaPanel:Remove()
	end
end)

