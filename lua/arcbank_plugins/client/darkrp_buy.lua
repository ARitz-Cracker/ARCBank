-- darkrp_buy.lua - Allows you to pay for shipments and stuff using your ARCBank account

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2017 Aritz Beobide-Cardinal All rights reserved.

net.Receive("arcbank_buyshit",function(len,ply)
	local typ = net.ReadUInt(2)
	local itemcmd = net.ReadString()
	
	Derma_Query( string.Replace(ARCBank.Msgs.UserMsgs.F4MenuAsk,"ARCBank",ARCBank.Settings.name), ARCBank.Settings.name_long, ARCBank.Msgs.ATMMsgs.Yes, function()
	
		ARCBank.GetAccessableAccounts(LocalPlayer(), function(errorcode, account_list)
			if errorcode ~= ARCBANK_ERROR_NONE then
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
			ARCLib.Derma_ChoiceRequest( ARCBank.Settings.name_long, ARCBank.Msgs.CardMsgs.AccountPay, choiceNames, choiceValues, 1, function(account)
				net.Start("arcbank_buyshit")
				net.WriteUInt(typ,2)
				net.WriteString(account)
				net.WriteString(itemcmd)
				net.SendToServer()
			end, nil, ARCBank.Msgs.ATMMsgs.OK, ARCBank.Msgs.ATMMsgs.Cancel )	
		end)
	
	end, ARCBank.Msgs.ATMMsgs.No,function()
		net.Start("arcbank_buyshit")
		net.WriteUInt(typ,2)
		net.WriteString("_")
		net.WriteString(itemcmd)
		net.SendToServer()
	end) 
end)