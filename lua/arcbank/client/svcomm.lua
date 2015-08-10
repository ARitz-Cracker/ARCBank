-- svcomm.lua - Client/Server communications for ARCBank
-- This shit is under copyright.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.

local ARCBank_PingBusy = false
local ARCBank_PingCallBack = {}
local ARCBank_PingCount = 1
function ARCBank.GetStatus(callback)
	if ARCBank_PingCallBack[1] then
		ARCBank_PingCount = ARCBank_PingCount + 1
		ARCBank_PingCallBack[ARCBank_PingCount] = callback
	else
		net.Start("arcbank_comm_check")
		net.SendToServer()
		ARCBank_PingCallBack[1] = callback
	end
end


net.Receive( "arcbank_comm_check", function(length)
	local ready = tobool(net.ReadBit())
	local outdated = tobool(net.ReadBit())
	for k,v in pairs(ARCBank_PingCallBack) do
		v(ready)
	end
	ARCBank.Loaded = ready
	ARCBank.Outdated = outdated
	ARCBank_PingCallBack = {}
end)
-- Account information --
local ARCBank_AccountInform_IsBusy = false
local ARCBank_AccountInform_CallBack
function ARCBank.GetAccountInformation(groupname,entity,callback)
	if ARCBank_AccountInform_IsBusy then callback(ARCBANK_ERROR_BUSY,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,entity) return end -- I know that checking for ARCBank_IsAValidDevice on the client is kinda useless... but I'll try anyway!
	ARCBank_AccountInform_CallBack = callback
	ARCBank_AccountInform_IsBusy = true
	net.Start("arcbank_comm_get_account_information")
	net.WriteEntity(entity)
	net.WriteString(groupname)
	net.SendToServer()
end

net.Receive( "arcbank_comm_get_account_information", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	if succ != 0 then
		ARCBank_AccountInform_CallBack(succ,ent)
	else
		local acc = {}
		acc.isgroup = tobool(net.ReadBit())
		acc.filename = net.ReadString()
		acc.name = net.ReadString()
		acc.owner = net.ReadString()
		acc.money = net.ReadDouble() 
		acc.rank = net.ReadUInt(ARCBANK_ACCOUNTBITRATE)
		acc.members = net.ReadTable()
		ARCBank_AccountInform_CallBack(acc,ent)
	end
	ARCBank_AccountInform_IsBusy = false
	ARCBank_AccountInform_CallBack = nil
end)

-- Transfer funds --

local ARCBank_TransferFunds_IsBusy = false
local ARCBank_TransferFunds_CallBack
function ARCBank.TransferFunds(toply,accfrom,accto,amount,reason,entity,callback)
	if ARCBank_TransferFunds_IsBusy then callback(ARCBANK_ERROR_BUSY,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,entity) return end
	ARCBank_TransferFunds_CallBack = callback
	ARCBank_TransferFunds_IsBusy = true
	net.Start("arcbank_comm_transfer")
	net.WriteEntity(entity)--ARCBank_IsAValidDevice
	net.WriteString(toply)
	net.WriteString(accfrom)
	net.WriteString(accto)
	net.WriteUInt(math.floor(amount),32)
	net.WriteString(reason)
	net.SendToServer()
end

net.Receive( "arcbank_comm_transfer", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	ARCBank_TransferFunds_CallBack(succ,ent)
	ARCBank_TransferFunds_CallBack = false
	ARCBank_TransferFunds_IsBusy = nil
end)

--Get Group List

local ARCBank_GroupList_IsBusy = false
local ARCBank_GroupList_CallBack
local ARCBank_GroupList_Progress = 0
local ARCBank_GroupList_Chunks = ""
function ARCBank.GroupList(steamid,entity,callback)
	if ARCBank_GroupList_IsBusy then callback(ARCBANK_ERROR_BUSY,0,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,0,entity) return end
	net.Start("arcbank_comm_group_list")
	net.WriteEntity(entity)
	net.WriteString(steamid)
	net.SendToServer()
	ARCBank_GroupList_CallBack = callback
	ARCBank_GroupList_IsBusy = true
	ARCBank_GroupList_Chunks = ""
	ARCBank_GroupList_Progress = 0
end
net.Receive( "arcbank_comm_group_list", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	local part = net.ReadUInt(32)
	local whole = net.ReadUInt(32)
	local str = net.ReadString()
	if succ == 0 then
		if part != ARCBank_GroupList_Progress then
			MsgN("ARCBank: Chuck Mismatch Error. Possibly due to lag.")
			ARCBank_GroupList_CallBack(ARCBANK_ERROR_CHUNK_MISMATCH,part/whole,ent)
			ARCBank_GroupList_CallBack = nil
			ARCBank_GroupList_IsBusy = false
		else
			ARCBank_GroupList_Chunks = ARCBank_GroupList_Chunks .. str
			if part == whole then
				local tab = util.JSONToTable(ARCBank_GroupList_Chunks)
				if !tab then
					ARCBank_GroupList_CallBack(ARCBANK_ERROR_DOWNLOAD_FAILED,1,ent)
				else
					ARCBank_GroupList_CallBack(tab,1,ent)
				end
				ARCBank_GroupList_CallBack = nil
				ARCBank_GroupList_IsBusy = false
			else
				net.Start("arcbank_comm_group_list")
				net.WriteEntity(ent)
				net.WriteString("RECIEVED DUH FOOKING CHUNK ||||"..tostring(part).."/"..tostring(whole))
				net.SendToServer()
				ARCBank_GroupList_Progress = ARCBank_GroupList_Progress + 1
				ARCBank_GroupList_CallBack(ARCBANK_ERROR_DOWNLOADING,part/whole,ent)
			end
		end
	else
		ARCBank_GroupList_CallBack(succ,0,ent)
		ARCBank_GroupList_CallBack = nil
		ARCBank_GroupList_IsBusy = false
	end
end)
--Create Account

local ARCBank_CreateAccount_IsBusy = false
local ARCBank_CreateAccount_CallBack
function ARCBank.CreateAccount(name,entity,callback)
	if ARCBank_CreateAccount_IsBusy then callback(ARCBANK_ERROR_BUSY,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,entity) return end
	ARCBank_CreateAccount_CallBack = callback
	ARCBank_CreateAccount_IsBusy = true
	net.Start("arcbank_comm_create")
	net.WriteEntity(entity)--ARCBank_IsAValidDevice
	net.WriteString(name)
	net.SendToServer()
end

net.Receive( "arcbank_comm_create", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	ARCBank_CreateAccount_CallBack(succ,ent)
	ARCBank_CreateAccount_CallBack = false
	ARCBank_CreateAccount_IsBusy = nil
end)


--Delete Account

local ARCBank_DeleteAccount_IsBusy = false
local ARCBank_DeleteAccount_CallBack
function ARCBank.DeleteAccount(name,entity,callback)
	if ARCBank_DeleteAccount_IsBusy then callback(ARCBANK_ERROR_BUSY,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,entity) return end
	ARCBank_DeleteAccount_CallBack = callback
	ARCBank_DeleteAccount_IsBusy = true
	net.Start("arcbank_comm_delete")
	net.WriteEntity(entity)--ARCBank_IsAValidDevice
	net.WriteString(name)
	net.SendToServer()
end

net.Receive( "arcbank_comm_delete", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	ARCBank_DeleteAccount_CallBack(succ,ent)
	ARCBank_DeleteAccount_CallBack = false
	ARCBank_DeleteAccount_IsBusy = nil
end)


--Upgrade Account

local ARCBank_UpgradeAccount_IsBusy = false
local ARCBank_UpgradeAccount_CallBack
function ARCBank.UpgradeAccount(name,entity,callback)
	if ARCBank_UpgradeAccount_IsBusy then callback(ARCBANK_ERROR_BUSY,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,entity) return end
	ARCBank_UpgradeAccount_CallBack = callback
	ARCBank_UpgradeAccount_IsBusy = true
	net.Start("arcbank_comm_upgrade")
	net.WriteEntity(entity)--ARCBank_IsAValidDevice
	net.WriteString(name)
	net.SendToServer()
end

net.Receive( "arcbank_comm_upgrade", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	ARCBank_UpgradeAccount_CallBack(succ,ent)
	ARCBank_UpgradeAccount_CallBack = false
	ARCBank_UpgradeAccount_IsBusy = nil
end)


--Get Log

local ARCBank_Log_IsBusy = false
local ARCBank_Log_CallBack
local ARCBank_Log_Progress = 0
local ARCBank_Log_Chunks = ""
function ARCBank.Log(accname,entity,callback)
	if ARCBank_Log_IsBusy then callback(ARCBANK_ERROR_BUSY,0,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,0,entity) return end
	net.Start("arcbank_comm_log")
	net.WriteEntity(entity)
	net.WriteString(accname)
	net.SendToServer()
	ARCBank_Log_CallBack = callback
	ARCBank_Log_IsBusy = true
	ARCBank_Log_Chunks = ""
	ARCBank_Log_Progress = 0
end
net.Receive( "arcbank_comm_log", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	local part = net.ReadUInt(32)
	local whole = net.ReadUInt(32)
	local str = net.ReadString()
	if succ == 0 then
		if part != ARCBank_Log_Progress then
			MsgN("ARCBank: Chuck Mismatch Error. Possibly due to lag.")
			ARCBank_Log_CallBack(ARCBANK_ERROR_CHUNK_MISMATCH,part/whole,ent)
			ARCBank_Log_CallBack = nil
			ARCBank_Log_IsBusy = false
		else
			ARCBank_Log_Chunks = ARCBank_Log_Chunks .. str
			if part == whole then
				ARCBank_Log_CallBack(ARCBank_Log_Chunks,1,ent)
				ARCBank_Log_CallBack = nil
				ARCBank_Log_IsBusy = false
			else
				net.Start("arcbank_comm_log")
				net.WriteEntity(ent)
				net.WriteString("RECIEVED DUH FOOKING CHUNK ||||"..tostring(part).."/"..tostring(whole))
				net.SendToServer()
				ARCBank_Log_Progress = ARCBank_Log_Progress + 1
				ARCBank_Log_CallBack(ARCBANK_ERROR_DOWNLOADING,part/whole,ent)
			end
		end
	else
		ARCBank_Log_CallBack(succ,0,ent)
		ARCBank_Log_CallBack = nil
		ARCBank_Log_IsBusy = false
	end
end)


local ARCBank_EditPlayerGroup_IsBusy = false
local ARCBank_EditPlayerGroup_CallBack
function ARCBank.EditPlayerGroup(name,steamid,add,entity,callback)
	if ARCBank_EditPlayerGroup_IsBusy then callback(ARCBANK_ERROR_BUSY,entity) return end
	if !entity.ARCBank_IsAValidDevice then callback(ARCBANK_ERROR_EXPLOIT,entity) return end
	ARCBank_EditPlayerGroup_CallBack = callback
	ARCBank_EditPlayerGroup_IsBusy = true
	net.Start("arcbank_comm_playergroup")
	net.WriteEntity(entity)
	net.WriteString(name)
	net.WriteString(steamid)
	net.WriteBit(add)
	net.SendToServer()
end

net.Receive( "arcbank_comm_playergroup", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	ARCBank_EditPlayerGroup_CallBack(succ,ent)
	ARCBank_EditPlayerGroup_CallBack = false
	ARCBank_EditPlayerGroup_IsBusy = nil
end)

--Send languages to player
local ARCBank_UpdateLang_Progress = 0
local ARCBank_UpdateLang_Chunks = ""
net.Receive( "arcbank_comm_lang", function(length)
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	local part = net.ReadUInt(32)
	local whole = net.ReadUInt(32)
	local chunklen = net.ReadUInt(32)
	local str = ""
	if (chunklen > 0) then
		str = net.ReadData(chunklen)
	end
	if succ == 0 then
		if part != ARCBank_UpdateLang_Progress then
			MsgN("ARCBank: Chuck Mismatch Error while loading language. Possibly due to lag.")
		else
			ARCBank_UpdateLang_Chunks = ARCBank_UpdateLang_Chunks .. str
			if part == whole then
				local tab = util.JSONToTable(util.Decompress(ARCBank_UpdateLang_Chunks))
				if tab then
					ARCBANK_ERRORSTRINGS = ARCLib.RecursiveTableMerge(ARCBANK_ERRORSTRINGS,tab.errmsgs)
					ARCBank.Msgs = ARCLib.RecursiveTableMerge(ARCBank.Msgs,tab.msgs)
					ARCBank.SettingsDesc = ARCLib.RecursiveTableMerge(ARCBank.SettingsDesc,tab.settingsdesc)
					for k,v in pairs(ents.FindByClass("weapon_arc_atmcard")) do
						if ARCBank.Settings.name_long then
							v.PrintName = ARCBank.Settings.name_long.." "..ARCBank.Msgs.Items.Card
						end
						v.Slot = ARCBank.Settings.card_weapon_slot or 1
						v.SlotPos = ARCBank.Settings.card_weapon_slotpos or 4
					end
					for k,v in pairs(ents.FindByClass("weapon_arc_atmhack")) do
						v.PrintName = ARCBank.Msgs.Items.Hacker
					end
					
				end
				ARCBank_UpdateLang_Chunks = ""
				ARCBank_UpdateLang_Progress = 0
			else
				net.Start("arcbank_comm_lang")
				net.WriteUInt(part,32)
				net.WriteUInt(whole,32)
				net.SendToServer()
				ARCBank_UpdateLang_Progress = ARCBank_UpdateLang_Progress + 1
			end
		end
	end
end)

---------------------
-- ADMIN FUNCTIONS --
---------------------

--Get Log

local ARCBank_Admin_Log_IsBusy = false
local ARCBank_Admin_Log_CallBack -- %%CONFIRMATION_HASH%%
local ARCBank_Admin_Log_Progress = 0
local ARCBank_Admin_Log_Chunks = ""
function ARCBank.AdminLog(accname,isgroup,callback)
	if ARCBank_Admin_Log_IsBusy then callback(ARCBANK_ERROR_BUSY,0) return end
	net.Start("arcbank_comm_admin_log")
	net.WriteString(accname)
	net.WriteBit(isgroup)
	net.SendToServer()
	ARCBank_Admin_Log_CallBack = callback
	ARCBank_Admin_Log_IsBusy = true
	ARCBank_Admin_Log_Chunks = ""
	ARCBank_Admin_Log_Progress = 0
end
net.Receive( "arcbank_comm_admin_log", function(length)
	local ent = net.ReadEntity()
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	local part = net.ReadUInt(32)
	local whole = net.ReadUInt(32)
	local str = net.ReadString()
	if succ == 0 then
		if part != ARCBank_Admin_Log_Progress then
			MsgN("ARCBank: Chuck Mismatch Error. Possibly due to lag.")
			ARCBank_Admin_Log_CallBack(ARCBANK_ERROR_CHUNK_MISMATCH,part/whole)
			ARCBank_Admin_Log_CallBack = nil
			ARCBank_Admin_Log_IsBusy = false
		else
			ARCBank_Admin_Log_Chunks = ARCBank_Admin_Log_Chunks .. str
			if part == whole then
				ARCBank_Admin_Log_CallBack(ARCBank_Admin_Log_Chunks,1)
				ARCBank_Admin_Log_CallBack = nil
				ARCBank_Admin_Log_IsBusy = false
			else
				net.Start("arcbank_comm_admin_log")
				net.WriteString("RECIEVED DUH FOOKING CHUNK ||||"..tostring(part).."/"..tostring(whole))
				net.SendToServer()
				ARCBank_Admin_Log_Progress = ARCBank_Admin_Log_Progress + 1
				ARCBank_Admin_Log_CallBack(ARCBANK_ERROR_DOWNLOADING,part/whole)
			end
		end
	else
		ARCBank_Admin_Log_CallBack(succ,0)
		ARCBank_Admin_Log_CallBack = nil
		ARCBank_Admin_Log_IsBusy = false
	end
end)


--Get Table
-- AdminAccounts
local ARCBank_Admin_Accounts_IsBusy = false
local ARCBank_Admin_Accounts_CallBack
local ARCBank_Admin_Accounts_Progress = 0
local ARCBank_Admin_Accounts_Chunks = ""
function ARCBank.Admin_GetAllAccounts(callback)
	if ARCBank_Admin_Accounts_IsBusy then callback(ARCBANK_ERROR_BUSY,0) return end
	net.Start("arcbank_comm_admin_accounts")
	net.WriteString("")
	net.SendToServer()
	ARCBank_Admin_Accounts_CallBack = callback
	ARCBank_Admin_Accounts_IsBusy = true
	ARCBank_Admin_Accounts_Chunks = ""
	ARCBank_Admin_Accounts_Progress = 0
end
net.Receive( "arcbank_comm_admin_accounts", function(length)
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	local part = net.ReadUInt(32)
	local whole = net.ReadUInt(32)
	local str = net.ReadString()
	if succ == 0 then
		if part != ARCBank_Admin_Accounts_Progress then
			MsgN("ARCBank: Chuck Mismatch Error. Possibly due to lag.")
			ARCBank_Admin_Accounts_CallBack(ARCBANK_ERROR_CHUNK_MISMATCH,part/whole)
			ARCBank_Admin_Accounts_CallBack = nil
			ARCBank_Admin_Accounts_IsBusy = false
		else
			ARCBank_Admin_Accounts_Chunks = ARCBank_Admin_Accounts_Chunks .. str
			if part == whole then
				local tab = util.JSONToTable(ARCBank_Admin_Accounts_Chunks)
				if !tab then
					ARCBank_Admin_Accounts_CallBack(ARCBANK_ERROR_DOWNLOAD_FAILED,1)
				else
					ARCBank_Admin_Accounts_CallBack(tab,1)
				end
				ARCBank_Admin_Accounts_CallBack = nil
				ARCBank_Admin_Accounts_IsBusy = false
			else
				net.Start("arcbank_comm_admin_accounts")
				net.WriteString("RECIEVED DUH FOOKING CHUNK ||||"..tostring(part).."/"..tostring(whole))
				net.SendToServer()
				ARCBank_Admin_Accounts_Progress = ARCBank_Admin_Accounts_Progress + 1
				ARCBank_Admin_Accounts_CallBack(ARCBANK_ERROR_DOWNLOADING,part/whole)
			end
		end
	else
		ARCBank_Admin_Accounts_CallBack(succ,0)
		ARCBank_Admin_Accounts_CallBack = nil
		ARCBank_Admin_Accounts_IsBusy = false
	end
end)


local ARCBank_Secret_IsBusy = false
local ARCBank_Secret_CallBack
function ARCBank.Secret(num,nnum,entity,callback)
	if ARCBank_Secret_IsBusy then callback(false) return end
	if !entity.ARCBank_IsAValidDevice then callback(false) return end -- Kind of useless doing it, anyone can just net_start a secret.
	ARCBank_Secret_CallBack = callback
	ARCBank_Secret_IsBusy = true
	net.Start("arcbank_comm_secret")
	net.WriteEntity(entity)
	net.WriteInt(num,8)
	net.WriteInt(nnum,32)
	net.SendToServer()
end

net.Receive( "arcbank_comm_secret", function(length)
	ARCBank_Secret_CallBack(tobool(net.ReadBit()),net.ReadEntity())
	ARCBank_Secret_IsBusy = false
	ARCBank_Secret_CallBack = nil
end)

net.Receive( "arcbank_comm_atmspawn", function(length)
	local count = net.ReadUInt(32)
	MainPanel = vgui.Create( "DFrame" )
	MainPanel:SetPos( ScrW()/2 - 110, ScrH()/2 - 30)
	MainPanel:SetSize( 220, 60 )
	MainPanel:SetTitle( "atm_spawn" )
	MainPanel:SetVisible( true )
	MainPanel:SetDraggable( true )
	MainPanel:ShowCloseButton( true )
	MainPanel:MakePopup()
	local DComboBox = vgui.Create( "DComboBox" ,MainPanel)
	DComboBox:SetPos( 10, 30 )
	DComboBox:SetSize( 200, 20 )
	DComboBox:SetValue( ARCBank.Msgs.Commands["atm_spawn"] )
	for i=1,count do
		DComboBox:AddChoice( net.ReadString() )
	end
	DComboBox.OnSelect = function( panel, index, value )
		net.Start("arcbank_comm_atmspawn")
		net.WriteString(value)
		net.SendToServer()
		MainPanel:Remove()
	end
end)
ARCBank.Settings = {}
net.Receive( "arcbank_comm_client_settings", function(length)
	ARCBank.Settings = util.JSONToTable(net.ReadString())
end)

net.Receive( "arcbank_comm_client_settings_changed", function(length)
	local typ = net.ReadUInt(16)
	local stn = net.ReadString()
	local val
	if typ == TYPE_NUMBER then
		val = net.ReadDouble()
	elseif typ == TYPE_STRING then
		val = net.ReadString()
	elseif typ == TYPE_BOOL then
		val = tobool(net.ReadBit())
	elseif typ == TYPE_TABLE then
		net.ReadTable()
	else
		error("Server attempted to send unknown setting type. (wat)")
	end
	ARCBank.Settings[stn] = val
end)


net.Receive( "arcatmhack_gui", function(length)
	local weapon = LocalPlayer():GetActiveWeapon()
	if (!weapon.ARCBank_IsHacker) then return end
	local setting = net.ReadTable()
	weapon.hacktime = math.Round((((setting[1]/200)^2+28)*(1+ARCLib.BoolToNumber(setting[2])*3))/ARCBank.Settings["atm_hack_time_rate"])
	weapon.hacktimeoff = math.Round(weapon.hacktime^0.725)
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetPos( surface.ScreenWidth()/2-130,surface.ScreenHeight()/2-100 )
	DermaPanel:SetSize( 260, 200 )
	DermaPanel:SetTitle( "ATM Hacking Unit Settings" )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( false )
	DermaPanel:MakePopup()
	local NumLabel2 = vgui.Create( "DLabel", DermaPanel )
	NumLabel2:SetPos( 10, 30 )
	NumLabel2:SetText( ARCBank.Msgs.Hack.Money )
	NumLabel2:SizeToContents()
	local HackTimeL = vgui.Create( "DLabel", DermaPanel )
	HackTimeL:SetPos( 10, 138 )
	HackTimeL:SetText( ARCBank.Msgs.Hack.ETA..ARCLib.TimeString(weapon.hacktime,ARCBank.Msgs.Time).."\n"..ARCBank.Msgs.Hack.GiveOrTake..ARCLib.TimeString(weapon.hacktimeoff,ARCBank.Msgs.Time) )
	HackTimeL:SizeToContents()

	local StealthCheckbox = vgui.Create( "DCheckBoxLabel", DermaPanel ) // Create the checkbox
	StealthCheckbox:SetPos( 10, 75 )                        // Set the position
	StealthCheckbox:SetText( ARCBank.Msgs.Hack.StealthMode )                   // Set the text next to the box
	StealthCheckbox:SetValue( ARCLib.BoolToNumber(setting[2]) )             // Initial value ( will determine whether the box is ticked too )
	StealthCheckbox:SizeToContents()                      // Make its size the same as the contents

	local About = vgui.Create( "DLabel", DermaPanel )
	About:SetText( ARCBank.Msgs.Hack.Descript )
	About:SetPos( 10, 96 )
	About:SetSize( 240, 40 )
	About:SetWrap(true)
	--About:SizeToContents()   
	local NumSlider2 = vgui.Create( "Slider", DermaPanel )
	NumSlider2:SetPos( 10, 40 )
	NumSlider2:SetWide( 260 )
	NumSlider2:SetMin(ARCBank.Settings["hack_min"])
	NumSlider2:SetMax(ARCBank.Settings["hack_max"])
	NumSlider2:SetDecimals(0)
	NumSlider2:SetValue( setting[1] )
	
	NumSlider2.OnValueChanged = function( panel, value )
		if value%25 != 0 then
			NumSlider2:SetValue( math.Clamp(math.Round(value/25)*25,0,ARCBank.Settings["hack_max"]) )
		end
		--math.Clamp(NumSlider2:GetValue(),0,setting[3])
		weapon.hacktime = math.Round((((math.Round(value/25)*25)/200)^2+28)*(1+ARCLib.BoolToNumber(StealthCheckbox:GetChecked())*3)/ARCBank.Settings["atm_hack_time_rate"])
		weapon.hacktimeoff = math.Round(weapon.hacktime^0.725)
		HackTimeL:SetText( ARCBank.Msgs.Hack.ETA..ARCLib.TimeString(weapon.hacktime,ARCBank.Msgs.Time).."\n"..ARCBank.Msgs.Hack.GiveOrTake..ARCLib.TimeString(weapon.hacktimeoff,ARCBank.Msgs.Time) )
		HackTimeL:SizeToContents()
	end
	StealthCheckbox.OnChange = function( panel, value )
		NumSlider2:SetValue( math.Clamp(math.Round(NumSlider2:GetValue()/25)*25,0,ARCBank.Settings["hack_max"]) )
		weapon.hacktime = math.Round((((math.Round(NumSlider2:GetValue()/25)*25)/200)^2+28)*(1+ARCLib.BoolToNumber(value)*3)/ARCBank.Settings["atm_hack_time_rate"])
		weapon.hacktimeoff = math.Round(weapon.hacktime^0.725)
		HackTimeL:SetText( ARCBank.Msgs.Hack.ETA..ARCLib.TimeString(weapon.hacktime,ARCBank.Msgs.Time).."\n"..ARCBank.Msgs.Hack.GiveOrTake..ARCLib.TimeString(weapon.hacktimeoff,ARCBank.Msgs.Time) )
		HackTimeL:SizeToContents()
	end
	local OkButton = vgui.Create( "DButton", DermaPanel )
	OkButton:SetText( "OK" )
	OkButton:SetPos( 10, 170 )
	OkButton:SetSize( 240, 20 )
	OkButton.DoClick = function()
		DermaPanel:Remove()
		net.Start("arcatmhack_gui")
		net.WriteEntity(weapon)
		net.WriteTable({math.Clamp(NumSlider2:GetValue(),0,ARCBank.Settings["hack_max"]),StealthCheckbox:GetChecked()})
		net.SendToServer()
	end
end)


