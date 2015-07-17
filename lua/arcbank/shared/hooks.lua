-- hooks.lua - Hooks

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false

if CLIENT then
	hook.Add( "CalcView", "ARCBank ATMCalcView",function( ply, pos, angles, fov ) --Good
		if ply.ARCBank_UsingATM && IsValid(ply.ARCBank_ATM) --[[&& LocalPlayer().ARCBank_ATM.WaitDelay < math.huge ]]&& ply.ARCBank_ATM.MoneyMsg == 0 && ply.ARCBank_FullScreen && IsValid(ply.ARCBank_ATM) then
			local view = {}
	--    view.origin = pos-( angles:Forward()*100 )
	--    view.angles = angles
	--    view.fov = fov
			view.origin = ply.ARCBank_ATM:GetPos() + (ply.ARCBank_ATM:GetAngles():Up() * 15) + (ply.ARCBank_ATM:GetAngles():Forward() * 14.5) + (ply.ARCBank_ATM:GetAngles():Right() * -0.015 )
			local aim = view.origin + (ply.ARCBank_ATM:GetAngles():Up() * -1.8 ) + (ply.ARCBank_ATM:GetAngles():Forward() * -3.2)
			view.angles = (aim - view.origin):Angle()
			ply:SetEyeAngles( ( ply.ARCBank_ATM:LocalToWorld(ply.ARCBank_ATM.ATMType.Screen) - ply:GetShootPos() ):Angle() )
			view.fov = fov
			
			return view
		end
	end)
	hook.Add( "CalcViewModelView", "ARCBank ATMCalcViewModel",function( wep, vm, oldpos, oldang, pos, ang ) --Good
		local ply = LocalPlayer()
		if ply.ARCBank_UsingATM && IsValid(ply.ARCBank_ATM) --[[&& LocalPlayer().ARCBank_ATM.WaitDelay < math.huge ]]&& ply.ARCBank_ATM.MoneyMsg == 0 && ply.ARCBank_FullScreen && IsValid(ply.ARCBank_ATM) then
			return Vector(0,0,1337),ang
		end
	end)
else

	hook.Add( "CanTool", "ARCBank Tool", function( ply, tr, tool )
		if IsValid(tr.Entity) then -- Overrides shitty FPP
			if tr.Entity.IsAFuckingATM && tr.Entity.ARCBank_MapEntity then return false end 
			for k, v in pairs(constraint.GetAllConstrainedEntities(tr.Entity)) do
				if v:GetClass() == "sent_arc_pinmachine" && v._Owner == ply then -- Overrides shitty FPP
					return true
				end
			end
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

	hook.Add( "PlayerUse", "ARCBank NoUse", function( ply, ent ) 
		if ent != NULL && ent:IsValid() && !ent.IsAFuckingATM && table.HasValue(ARCBank.Disk.NommedCards,ply:SteamID()) then
			ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.AtmUse )
			return false
		end 
		if ent.IsAFuckingATM then return true end 
	end)

	hook.Add( "GravGunPunt", "ARCBank PuntHacker", function( ply, ent ) if ent:GetClass() == "sent_arc_atmhack" then ent:TakeDamage( 100, ply, ply:GetActiveWeapon() ) end end)
	hook.Add( "ARCLoad_OnPlayerLoaded", "ARCBank PlyAuth", function( ply ) 
		if IsValid(ply) && ply:IsPlayer() then
			if table.HasValue(ARCBank.Disk.NommedCards,ply:SteamID()) then
				ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.Eatcard1 )
			end
			ARCBank.UpdateLang(ARCBank.Settings["language"])
			if ARCBank.Settings["atm_darkmode_default"] then
				if !table.HasValue(ARCBank.Disk.EmoPlayers,ply:SteamID()) && table.HasValue(ARCBank.Disk.BlindPlayers,ply:SteamID()) then
					ply:SendLua("ARCBank.ATM_DarkTheme = false")
				else
					ply:SendLua("ARCBank.ATM_DarkTheme = true")
				end
			else
				ply:SendLua("ARCBank.ATM_DarkTheme = "..tostring(table.HasValue(ARCBank.Disk.EmoPlayers,ply:SteamID())))
			end
			ply:SendLua("LocalPlayer().ARCBank_FullScreen = "..tostring(table.HasValue(ARCBank.Disk.OldPlayers,ply:SteamID())))
			net.Start("arcbank_comm_client_settings")
			net.WriteString(util.TableToJSON(ARCBank.Settings))
			net.Send(ply)
			for k,atm in pairs(ents.FindByClass("sent_arc_atm")) do
				net.Start("ARCBank CustomATM")
				net.WriteEntity(atm)
				net.WriteString(util.TableToJSON(atm.ATMType))
				net.Send(ply)
			end
			
		end
		timer.Simple(1,function()
			if IsValid(ply) && ply:IsPlayer() && table.HasValue(ARCBank.Disk.NommedCards,ply:SteamID()) then
				ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.Eatcard2 )
				ply:Give("weapon_arc_atmcard")
				table.RemoveByValue(ARCBank.Disk.NommedCards,ply:SteamID())
			end
		end)
	end)
		

	hook.Add( "PlayerGetSalary", "ARCBank PaydayATM DRP2.4", function(ply, amount)
		if amount == 0 then return end
		if ARCBank.Settings["use_bank_for_payday"] then
			ARCBank.AtmFunc(ply,amount,"",function(errcode)
				if errcode == 0 then
				
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.Paycheck,"ARCBank",ARCBank.Settings.name),NOTIFY_HINT,4,false)
				elseif errcode != ARCBANK_ERROR_NIL_ACCOUNT then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.PaycheckFail,"ARCBank",ARCBank.Settings.name).." ("..ARCBANK_ERRORSTRINGS[errcode]..")",NOTIFY_ERROR,4,true)
				end
			end)
		end
	end)

	hook.Add( "playerGetSalary", "ARCBank PaydayATM", function(ply, amount)
		if amount == 0 then return end
		if ARCBank.Settings["use_bank_for_payday"] then
			ARCBank.AtmFunc(ply,amount,"",function(errcode)
				if errcode == 0 then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.Paycheck,"ARCBank",ARCBank.Settings.name),NOTIFY_HINT,4,false)
				elseif errcode != ARCBANK_ERROR_NIL_ACCOUNT then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.PaycheckFail,"ARCBank",ARCBank.Settings.name).." ("..ARCBANK_ERRORSTRINGS[errcode]..")",NOTIFY_ERROR,4,true)
				end
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
		local f = ARCBank.Dir.."/accounts_unused/"..string.lower(string.gsub(ply:SteamID(), "[^_%w]", "_"))..".txt"
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

	hook.Add( "PreCleanupMap", "ARCBank PreCleanupATM", function()
		for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
			oldatms.ARCBank_MapEntity = false
			--oldatms:Remove()
		end
	end )

	hook.Add( "PostCleanupMap", "ARCBank PostCleanupATM", function() timer.Simple(1,function() ARCBank.SpawnATMs() end ) end )
	]]

	hook.Add( "ARCLoad_OnLoaded", "ARCBank SpawnATMs", function(loaded) ARCBank.SpawnATMs() end )
	hook.Add( "ShutDown", "ARCBank Shutdown", function()
		for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
			oldatms.ARCBank_MapEntity = false
			--oldatms:Remove()
		end
		ARCBank.SaveDisk()
	end)

end

