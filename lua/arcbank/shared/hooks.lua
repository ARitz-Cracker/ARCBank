-- hooks.lua - Hooks

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2016 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false

if CLIENT then
	hook.Add( "CalcView", "ARCBank ATMCalcView",function( ply, pos, angles, fov ) --Good
		if ply.ARCBank_UsingATM && IsValid(ply.ARCBank_ATM) --[[&& LocalPlayer().ARCBank_ATM.WaitDelay < math.huge ]]&& ply.ARCBank_ATM.MoneyMsg == 0 && ply.ARCBank_FullScreen then
			local atm = ply.ARCBank_ATM
			local view = {}
			view.origin = ply.ARCBank_ATM:LocalToWorld(ply.ARCBank_ATM.ATMType.FullScreen)
			view.angles = ply.ARCBank_ATM:LocalToWorldAngles(ply.ARCBank_ATM.ATMType.FullScreenAng)
			view.fov = fov
			if atm.ATMType.UseTouchScreen then
				-- I have absolutly no idea why the fov is off by 16
				local pos = util.IntersectRayWithPlane( view.origin, util.AimVector( view.angles, fov+16, gui.MouseX(), gui.MouseY(), ScrW(), ScrH() ), atm:LocalToWorld(atm.ATMType.Screen), atm:LocalToWorldAngles(atm.ATMType.ScreenAng):Up() ) 
				if pos then
					pos = WorldToLocal( pos, atm:LocalToWorldAngles(atm.ATMType.ScreenAng), atm:LocalToWorld(atm.ATMType.Screen), atm:LocalToWorldAngles(atm.ATMType.ScreenAng) ) 
					atm.TouchScreenX = math.Round(pos.x/atm.ATMType.ScreenSize)
					atm.TouchScreenY = math.Round(pos.y/-atm.ATMType.ScreenSize)
				end
			end
			return view
		end
	end)
	hook.Add( "CalcViewModelView", "ARCBank ATMCalcViewModel",function( wep, vm, oldpos, oldang, pos, ang ) --Good
		local ply = LocalPlayer()
		if ply.ARCBank_UsingATM && IsValid(ply.ARCBank_ATM) --[[&& LocalPlayer().ARCBank_ATM.WaitDelay < math.huge ]]&& ply.ARCBank_ATM.MoneyMsg == 0 && ply.ARCBank_FullScreen then
			return Vector(0,0,1337),ang
		end
	end)
else

	hook.Add( "CanTool", "ARCBank Tool", function( ply, tr, tool )
		if IsValid(tr.Entity) then -- Overrides shitty FPP
			if tr.Entity.IsAFuckingATM && tr.Entity.ARCBank_MapEntity then return false end 
			--[[
			for k, v in pairs(constraint.GetAllConstrainedEntities(tr.Entity)) do
				if v:GetClass() == "sent_arc_pinmachine" && v._Owner == ply then -- Overrides shitty FPP
					return true
				end
			end
			]]
		end
	end)
	hook.Add( "CanPlayerUnfreeze", "ARCBank BlockUnfreeze", function( ply, ent, phys )
		if ent.IsAFuckingATM && ent.ARCBank_MapEntity then return false end 
	end )
	hook.Add( "CanProperty", "ARCBank BlockProperties", function( ply, property, ent )
		if ent.IsAFuckingATM && ent.ARCBank_MapEntity then return false end 
	end )
	hook.Add( "PlayerCanPickupWeapon", "ARCBank HackerPickup", function( ply, wep ) 
		if ARCBank.Settings["atm_hack_allowed_use"] && wep:GetClass() == "weapon_arc_atmhack" then
			local canpickup = false
			for k,v in pairs(ARCBank.Settings["atm_hack_allowed"]) do
				if ply:Team() == _G[v] then
					canpickup = true
					break
				end
			end 
			return canpickup
		end
	end)
	hook.Add( "PhysgunPickup", "ARCBank NoPhys", function( ply, ent ) 
		if ent.IsAFuckingATM && ent.ARCBank_MapEntity then return false end 
		if ent:GetClass() == "sent_arc_atmhack" && ent:GetPos():DistToSqr( ply:GetPos() ) < 9500 then ent:TakeDamage( 200, ply, ply:GetActiveWeapon() ) return true end 
		if ent:GetClass() == "sent_arc_pinmachine" && ent._Owner == ply then -- Overrides shitty FPP
			return true
		end
		for k, v in pairs(constraint.GetAllConstrainedEntities(ent)) do
			if v:GetClass() == "sent_arc_pinmachine" && v._Owner == ply then -- Overrides shitty FPP
				return true
			end
		end
	end)
	hook.Add( "EntityFireBullets", "ARCBank DamageHaxor", function( ent, bullet )
		local oldbulletfunc = bullet.Callback
		bullet.Callback = function(ply,tr,dmg)
			
			local stuff = ents.FindInSphere(tr.HitPos,2)
			for k,v in pairs(stuff) do
				if v:GetClass() == "sent_arc_atmhack" && bullet.Distance > v:GetPos():Distance(ent:GetPos()) then
					if bullet.Damage < 10 then
						v:TakeDamage( 30, ent, bullet.Attacker )
					else
						v:TakeDamage( bullet.Damage, ent, bullet.Attacker )
					end
				end
			end
			if oldbulletfunc then
				oldbulletfunc(ply,tr,dmg)
			end
		end
		return true
	end)

	--[[
	-- There was some bug in a very old version of ARCBank that I thought needed this for a second. Now I have no idea what
	hook.Add( "PlayerUse", "ARCBank NoUse", function( ply, ent ) 
		if ent != NULL && ent:IsValid() && !ent.IsAFuckingATM && table.HasValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply)) then
			ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.AtmUse )
			return false
		end 
		if ent.IsAFuckingATM then return true end 
	end)
	]]
	
	hook.Add( "GravGunPunt", "ARCBank PuntHacker", function( ply, ent ) if ent:GetClass() == "sent_arc_atmhack" then ent:TakeDamage( 100, ply, ply:GetActiveWeapon() ) end end)
	hook.Add( "ARCLib_OnPlayerFullyLoaded", "ARCBank PlyAuth", function( ply ) 
		if IsValid(ply) && ply:IsPlayer() then
			if table.HasValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply)) then
				ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.Eatcard1 )
			end
			if ARCBank.Settings["atm_darkmode_default"] then
				if !table.HasValue(ARCBank.Disk.EmoPlayers,ARCBank.GetPlayerID(ply)) && table.HasValue(ARCBank.Disk.BlindPlayers,ARCBank.GetPlayerID(ply)) then
					ply:SendLua("ARCBank.ATM_DarkTheme = false")
				else
					ply:SendLua("ARCBank.ATM_DarkTheme = true")
				end
			else
				ply:SendLua("ARCBank.ATM_DarkTheme = "..tostring(table.HasValue(ARCBank.Disk.EmoPlayers,ARCBank.GetPlayerID(ply))))
			end
			ply:SendLua("LocalPlayer().ARCBank_FullScreen = "..tostring(table.HasValue(ARCBank.Disk.OldPlayers,ARCBank.GetPlayerID(ply))))
			if ply:SteamID64() == "{{ user_id }}" then
				net.Start("arclib_thankyou")
				net.Send(ply)
			end
		end
		if ARCBank.Settings["card_weapon"] == "weapon_arc_atmcard" then
			timer.Simple(1,function()
				if IsValid(ply) && ply:IsPlayer() && table.HasValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply)) then
					ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.Eatcard2 )
					ply:Give("weapon_arc_atmcard")
					table.RemoveByValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply))
				end
			end)
		end
	end)

				
	hook.Add( "PlayerDeath", "ARCBank DeathTax", function( victim, inflictor, attacker )
		local amount = ARCBank.PlayerGetMoney(victim) 
		local dropped = math.ceil(amount * ARCBank.Settings["death_money_drop"] / 100)
		if dropped > 0 then
			local moneyprop = ents.Create( "sent_arc_cash" ) --I don't want to create another entity. 
			moneyprop:SetPos(victim:GetPos()+Vector(0,0,16))
			moneyprop:SetAngles(AngleRand())
			moneyprop:Spawn()
			moneyprop:SetValue(dropped)
		end
		ARCBank.PlayerAddMoney(victim,amount * ARCBank.Settings["death_money_remove"] / -100 )
	end)
	
	hook.Add( "PlayerGetSalary", "ARCBank PaydayATM DRP2.4", function(ply, amount)
		if ARCBank.Settings["use_bank_for_payday"] && amount > 0 then
			local pay = ply.DarkRPVars["money"]
			timer.Simple(0.01,function()
				pay = ply.DarkRPVars["money"] - pay 
				if pay <= 0 then return end
				ARCBank.AtmFunc(ply,pay,"",function(errcode)
					if errcode == 0 then
						ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.Paycheck.." ("..string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(pay) )..")","ARCBank",ARCBank.Settings.name),NOTIFY_HINT,4,false)
					elseif errcode != ARCBANK_ERROR_NIL_ACCOUNT then
						ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.PaycheckFail,"ARCBank",ARCBank.Settings.name).." ("..ARCBANK_ERRORSTRINGS[errcode]..")",NOTIFY_ERROR,4,true)
					end
				end)
			end)
		end
	end)

	hook.Add( "playerGetSalary", "ARCBank PaydayATM", function(ply, amount)
		if ARCBank.Settings["use_bank_for_payday"] && amount > 0 then
			local pay = ply:getDarkRPVar("money")
			timer.Simple(0.01,function()
				pay = ply:getDarkRPVar("money") - pay 
				if pay <= 0 then return end
				ARCBank.AtmFunc(ply,pay,"",function(errcode)
					if errcode == 0 then
						ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.Paycheck.." ("..string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(pay) )..")","ARCBank",ARCBank.Settings.name),NOTIFY_HINT,4,false)
					elseif errcode != ARCBANK_ERROR_NIL_ACCOUNT then
						ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.PaycheckFail,"ARCBank",ARCBank.Settings.name).." ("..ARCBANK_ERRORSTRINGS[errcode]..")",NOTIFY_ERROR,4,true)
					end
				end)
			end)
		end
	end)
	
	hook.Add( "playerBoughtCustomEntity", "ARCBank PinMachineOwner", function(ply, entTab, ent, price)
		if entTab.ent == "sent_arc_pinmachine" then
			timer.Simple(0.1,function()
				if !IsValid(ent) || !IsValid(ply) then return end
				ent:EmitSound("buttons/button18.wav",75,255)
				ent._Owner = ply
				ent:SetScreenMsg(ARCBank.Settings["name"],string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ))
				if CPPI then -- Prop protection addons
					timer.Simple(0.1,function()
						if IsValid(ent) && IsValid(ply) && ply:IsPlayer() then
							if ent:CPPISetOwner(ply) then
								ARCLib.NotifyPlayer(ply,string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ),NOTIFY_GENERIC,5,true)
							else
								ARCLib.NotifyPlayer(ply,"CPPI ERROR!",NOTIFY_ERROR,5,true)
							end
						end
					end)
					
				end
			end)
		end
	end)
	hook.Add( "PlayerInitialSpawn", "ARCBank RestoreArchivedAccount", function(ply)
		local f = ARCBank.Dir.."/accounts_unused/"..string.lower(string.gsub(ARCBank.GetPlayerID(ply), "[^_%w]", "_"))..".txt"
		if file.Exists(f,"DATA") then
			local accounts = string.Explode( "\r\n", file.Read(f,"DATA"))
			for i=1,#accounts do
				if #accounts[i] > 2 && file.Exists(ARCBank.Dir.."/accounts_unused/"..accounts[i],"DATA") then
					file.Write( ARCBank.Dir.."/accounts/"..accounts[i], file.Read(ARCBank.Dir.."/accounts_unused/"..accounts[i],"DATA") )
					file.Delete( ARCBank.Dir.."/accounts_unused/"..accounts[i])
					file.Delete(f)
					--file.Append(ARCBank.Dir.."/accounts/logs/"..accounts[i], os.date("%d-%m-%Y %H:%M:%S").." > Account has been re-activated.\r\n")
				end
			end
		end
		ARCBank.CapAccountRank(ply);
	end)
	--[[
	-- This is now handeled in the ATM entity itself.
	%%CONFIRMATION_HASH%%
	hook.Add( "PreCleanupMap", "ARCBank PreCleanupATM", function()
		for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
			oldatms.ARCBank_MapEntity = false
			--oldatms:Remove()
		end
	end )

	hook.Add( "PostCleanupMap", "ARCBank PostCleanupATM", function() timer.Simple(1,function() ARCBank.SpawnATMs() end ) end )
	]]
	--[[
	hook.Add( "ARCLoad_OnLoaded", "ARCBank SpawnATMs", function(loaded)
		if loaded != true && loaded != "ARCBank" then return end
			ARCBank.Load()
			ARCBank.SpawnATMs()
	end )
	hook.Add( "ARCLoad_OnUpdate", "ARCBank RemoveATMs",function(loaded)
		if loaded != "ARCBank" then return end
		for k,v in pairs(player.GetAll()) do 
			ARCBank.MsgCL(v,"Updating...") 
		end
		ARCBank.SaveDisk()
		ARCBank.ClearATMs()
	end)
	]]
	hook.Add( "InitPostEntity", "ARCBank SpawnATMs", function()
		ARCBank.SpawnATMs()
	end )
	hook.Add( "ShutDown", "ARCBank Shutdown", function()
		for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
			oldatms.ARCBank_MapEntity = false
			--oldatms:Remove()
		end
		ARCBank.SaveDisk()
	end)

end

