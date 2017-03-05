-- ATM Creator ARitz Cracker Bank (Serverside)
-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016-2017 Aritz Beobide-Cardinal All rights reserved.
if ARCBank then
	util.AddNetworkString( "ARCBank ATM Creator" )
	util.AddNetworkString( "ARCBank ATM CreatorUse" )
	local ATMCreatorPerson = NULL
	local ATMCreatorProp = NULL
	local ATMCreationTable = {}
	ARCBank.Commands["create_atm"] = {
		command = function(ply,args) 
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			if IsValid(ATMCreatorProp) then
				ARCBank.MsgCL(ply,ARCBank.Msgs.ATMCreator.InUse)
				return
			end
			
			if !args[1] || args[1] == "" then
				ARCBank.MsgCL(ply,ARCBank.Msgs.ATMCreator.NoName)
				return
			else
				if file.Exists(ARCBank.Dir.."/custom_atms/"..args[1]..".txt","DATA") then
					ATMCreationTable = util.JSONToTable(file.Read(ARCBank.Dir.."/custom_atms/"..args[1]..".txt","DATA"))
				else
					if !args[2] || !util.IsValidModel( args[2] ) then
						ARCBank.MsgCL(ply,ARCBank.Msgs.ATMCreator.Invalid)
						return
					else
						ATMCreationTable.Name = string.lower(string.gsub(args[1], "[^_%w]", "_"))
						ATMCreationTable.Model = args[2] 
						ATMCreationTable.ModelOpen = ""
						
						ATMCreationTable.buttons = {}
						for i=0,23 do
							ATMCreationTable.buttons[i] = vector_origin
						end
						ATMCreationTable.UseTouchScreen = false
						
						ATMCreationTable.Screen = vector_origin
						ATMCreationTable.ScreenAng = angle_zero
						ATMCreationTable.ScreenSize = 0.043
						
						ATMCreationTable.UseCardModel = true
						ATMCreationTable.CardModel = "models/arc/card.mdl"
						
						ATMCreationTable.CardInsertAnimationPos = vector_origin
						ATMCreationTable.CardInsertAnimationSpeed = vector_origin
						ATMCreationTable.CardInsertAnimationAng = angle_zero
						
						ATMCreationTable.CardRemoveAnimationPos = vector_origin
						ATMCreationTable.CardRemoveAnimationSpeed = vector_origin
						ATMCreationTable.CardRemoveAnimationAng = angle_zero
						
						ATMCreationTable.CardInsertAnimation = ""
						ATMCreationTable.CardRemoveAnimation = ""
						ATMCreationTable.CardInsertAnimationLength = 3
						ATMCreationTable.CardRemoveAnimationLength = 0.5
						
						ATMCreationTable.UseMoneyModel = true
						ATMCreationTable.MoneyModel = "models/props/cs_assault/money.mdl"
						ATMCreationTable.DepositAnimationPos = vector_origin
						ATMCreationTable.DepositAnimationAng = angle_zero
						ATMCreationTable.DepositAnimationSpeed = vector_origin
						
						ATMCreationTable.WithdrawAnimationPos = vector_origin
						ATMCreationTable.WithdrawAnimationAng = angle_zero
						ATMCreationTable.WithdrawAnimationSpeed = vector_origin
						
						ATMCreationTable.DepositAnimation = ""
						ATMCreationTable.WithdrawAnimationLength = 0.5
						ATMCreationTable.WithdrawAnimation = ""
						ATMCreationTable.DepositAnimationLength = 3.5
						
						ATMCreationTable.MoneyHitBoxPos = vector_origin
						ATMCreationTable.MoneyHitBoxAng = angle_zero
						ATMCreationTable.MoneyHitBoxSize = Vector(5,5,5)
						
						ATMCreationTable.UseMoneylight = true
						ATMCreationTable.Moneylight = vector_origin
						ATMCreationTable.MoneylightAng = angle_zero
						ATMCreationTable.MoneylightSize = 0.3
						ATMCreationTable.MoneylightFill = false
						ATMCreationTable.MoneylightHeight = 10
						ATMCreationTable.MoneylightWidth = 42
						ATMCreationTable.MoneylightColour = Color(218,255,255,255)
						
						ATMCreationTable.UseCardlight = true
						ATMCreationTable.Cardlight = vector_origin
						ATMCreationTable.CardlightAng = angle_zero
						ATMCreationTable.CardlightSize = 0.099
						ATMCreationTable.CardlightFill = false
						ATMCreationTable.CardlightHeight = 8
						ATMCreationTable.CardlightWidth = 39
						ATMCreationTable.CardlightColour = Color(218,255,255,255)
						
						ATMCreationTable.BackgroundColour = Color(64,64,64,255) -- 25, 100, 255, 255 
						ATMCreationTable.ForegroundColour = Color(128,128,128,255) -- 0, 0, 255, 255 
						ATMCreationTable.WelcomeScreen = "arc/atm_base/screen/welcome_new"
						ATMCreationTable.HackedWelcomeScreen = {"arc/atm_base/screen/hacked1","arc/atm_base/screen/hacked2","arc/atm_base/screen/hacked3"}
						ATMCreationTable.Resolutionx = 278
						ATMCreationTable.Resolutiony = 315
						
						ATMCreationTable.CloseAnimation = ""
						ATMCreationTable.OpenAnimationLength = 0.5
						ATMCreationTable.OpenAnimation = ""
						ATMCreationTable.CloseAnimationLength = 0.5
						
						
						ATMCreationTable.CloseSkin = 1
						ATMCreationTable.OpenSkin = 1
						ATMCreationTable.LightSkin = 1
						
						ATMCreationTable.WithdrawSound = {"^arcbank/atm/spit-out.wav"}
						ATMCreationTable.CloseSound = {"^arcbank/atm/close.wav"}
						ATMCreationTable.DepositStartSound = {"^arcbank/atm/eat-duh-cash1.wav"}
						ATMCreationTable.DepositLoopSound = {"^arcbank/atm/eat-duh-cash-loop.wav"}
						ATMCreationTable.DepositDoneSound = {"^arcbank/atm/eat-duh-cashnomnom.wav"}
						ATMCreationTable.DepositFailSound = {"^arcbank/atm/eat-duh-cash-stop.wav"}
						ATMCreationTable.ClientPressSound = {"^arcbank/atm/press1.wav","^arcbank/atm/press2.wav","^arcbank/atm/press3.wav"}
						ATMCreationTable.PressSound = {"^arcbank/atm/beep_short.wav"}
						ATMCreationTable.WaitSound = {"^arcbank/atm/beep.wav"}
						ATMCreationTable.ErrorSound = {"^arcbank/atm/beep_error.wav"}
						ATMCreationTable.PressNoSound = {"^arcbank/atm/press.wav"}
						ATMCreationTable.InsertCardSound = {"^arcbank/atm/cardinsert.wav"}
						ATMCreationTable.WithdrawCardSound = {"^arcbank/atm/cardremove.wav"}
						
						--ATMCreationTable.PauseBeforeWithdrawSound = 0
						ATMCreationTable.PauseBeforeWithdrawAnimation = 6.5
						ATMCreationTable.PauseAfterWithdrawAnimation = 0
						
						ATMCreationTable.PauseBeforeDepositSoundLoop = 3.4
						ATMCreationTable.PauseBeforeDepositAnimation = 0.6
						ATMCreationTable.PauseAfterDepositAnimation = 4.85
						ATMCreationTable.PauseAfterDepositAnimationFail = 2
					end
				end
				
			
				local tr = ply:GetEyeTrace()
				local ang = ply:EyeAngles()
				ang.yaw = ang.yaw + 180 -- Rotate it 180 degrees in my favour
				ang.roll = 0
				ang.pitch = 0
				ATMCreatorProp = ents.Create( "sent_arc_atm_creator_prop" )
				ATMCreatorProp:SetModel(ATMCreationTable.Model)
				ATMCreatorProp:SetPos(tr.HitPos)
				ATMCreatorProp:SetAngles(ang)
				ATMCreatorProp:Spawn()
				ATMCreatorProp:Activate()
				local vFlushPoint = tr.HitPos - ( tr.HitNormal * 512 )	-- Find a point that is definitely out of the object in the direction of the floor
				vFlushPoint = ATMCreatorProp:NearestPoint( vFlushPoint )			-- Find the nearest point inside the object to that point
				vFlushPoint = ATMCreatorProp:GetPos() - vFlushPoint				-- Get the difference
				vFlushPoint = tr.HitPos + vFlushPoint					-- Add it to our target pos
				ATMCreatorProp:SetPos( vFlushPoint )
				ATMCreatorProp.ATMType = ATMCreationTable
				timer.Simple(0.1,function()
					net.Start("ARCBank ATM Creator")
					net.WriteEntity(ATMCreatorProp)
					net.WriteString(util.TableToJSON(ATMCreatorProp.ATMType))
					net.Send(ply)
				end)
				ATMCreatorProp.CreatorPerson = ply
				ATMCreatorPerson = ply
			end
		end, 
		usage = " <name(str)> [model(str)]",
		description = "Creates a custom ATM",
		adminonly = true,
		hidden = false
	}
	hook.Add( "PlayerDisconnected", "ARCBank Remove ATM creator", function( ply ) 
		if ply == ATMCreatorPerson then
			ATMCreatorProp:Remove()
		end
	end)
	net.Receive( "ARCBank ATM Creator", function(length,ply)
		if ply == ATMCreatorPerson then
			ATMCreatorProp.ATMType = util.JSONToTable(net.ReadString())
			ATMCreatorProp.ATMType.Name = string.lower(string.gsub(ATMCreatorProp.ATMType.Name, "[^_%w]", "_"))
			if ATMCreatorProp.ATMType.Name == "default" then
				ARCLib.NotifyPlayer(ply,ARCBank.Msgs.ATMCreator.SavedFileDefault,NOTIFY_ERROR,10,true)
			else
				file.Write(ARCBank.Dir.."/custom_atms/"..ATMCreatorProp.ATMType.Name..".txt",util.TableToJSON(ATMCreatorProp.ATMType))
				ARCLib.NotifyPlayer(ply,ARCLib.PlaceholderReplace(ARCBank.Msgs.ATMCreator.SavedFile,{FILENAME="garrysmod/data/"..ARCBank.Dir.."/custom_atms/"..ATMCreatorProp.ATMType.Name..".txt"}),NOTIFY_GENERIC,10,true)
			end
		end
	end)
	
	util.AddNetworkString("ARCBank ATMCreate Test Card")
	util.AddNetworkString("ARCBank ATMCreate Test")
	net.Receive( "ARCBank ATMCreate Test Card", function(length,ply) -- WORK ON THIS
		local atm = ATMCreatorProp
		if tobool(net.ReadBit()) then
			if atm.ATMType.CardRemoveAnimation != "" then
				atm:ARCLib_SetAnimationTime(atm.ATMType.CardRemoveAnimation,atm.ATMType.CardRemoveAnimationLength)
			end
			atm:EmitSoundTable(atm.ATMType.WithdrawCardSound,65,math.random(95,105))
			
			local atmcard = ents.Create( "prop_physics" )
			atmcard:SetModel( atm.ATMType.CardModel )
			atmcard:SetKeyValue("spawnflags","516")
			atmcard:SetPos( atm:LocalToWorld(atm.ATMType.CardRemoveAnimationPos))
			atmcard:SetAngles( atm:LocalToWorldAngles(atm.ATMType.CardRemoveAnimationAng) )
			atmcard:Spawn()
			atmcard:GetPhysicsObject():EnableCollisions(false)
			atmcard:GetPhysicsObject():EnableGravity(false)
			atmcard:GetPhysicsObject():SetVelocity(atmcard:GetForward()*atm.ATMType.CardRemoveAnimationSpeed.x + atmcard:GetRight()*atm.ATMType.CardRemoveAnimationSpeed.y + atmcard:GetUp()*atm.ATMType.CardRemoveAnimationSpeed.z)
			timer.Simple(atm.ATMType.CardRemoveAnimationLength-0.3,function() atmcard:GetPhysicsObject():SetVelocity(Vector(0,0,0)) end)
			timer.Simple(atm.ATMType.CardRemoveAnimationLength,function() 
			--MsgN(atm:WorldToLocal(atmcard:GetPos()))
			atmcard:Remove() 
			end)
			
		else
			if atm.ATMType.CardInsertAnimation != "" then
				atm:ARCLib_SetAnimationTime(atm.ATMType.CardInsertAnimation,atm.ATMType.CardInsertAnimationLength)
			end
			atm:EmitSoundTable(atm.ATMType.InsertCardSound,65,math.random(95,105))
			
			local atmcard = ents.Create( "prop_physics" )
			atmcard:SetModel( atm.ATMType.CardModel )
			atmcard:SetKeyValue("spawnflags","516")
			atmcard:SetPos( atm:LocalToWorld(atm.ATMType.CardInsertAnimationPos))
			atmcard:SetAngles( atm:LocalToWorldAngles(atm.ATMType.CardInsertAnimationAng) )
			atmcard:Spawn()
			atmcard:GetPhysicsObject():EnableCollisions(false)
			atmcard:GetPhysicsObject():EnableGravity(false)
			atmcard:GetPhysicsObject():SetVelocity(atmcard:GetForward()*atm.ATMType.CardInsertAnimationSpeed.x + atmcard:GetRight()*atm.ATMType.CardInsertAnimationSpeed.y + atmcard:GetUp()*atm.ATMType.CardInsertAnimationSpeed.z)
			timer.Simple(atm.ATMType.CardInsertAnimationLength,function() 
			--MsgN(atm:WorldToLocal(atmcard:GetPos()))
			atmcard:Remove() 
			end)
		
		
		end
	end)
	net.Receive( "ARCBank ATMCreate Test", function(length,ply)
		if ply != ATMCreatorPerson then return end
		local atm = ATMCreatorProp
		atm.TakingMoney = tobool(net.ReadBit())
		atm.fail = tobool(net.ReadBit())
		--MsgN(atm,atm.TakingMoney,atm.fail)
		if atm.TakingMoney then
			
			

			timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation,function() 
				if atm.ATMType.ModelOpen != "" then
					atm:SetModel( atm.ATMType.ModelOpen ) 
					atm:SetSkin(atm.ATMType.OpenSkin)
				end
				if atm.ATMType.OpenAnimation != "" then
					atm:ARCLib_SetAnimationTime(atm.ATMType.OpenAnimation,atm.ATMType.OpenAnimationLength)
				end
			end)
			timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.PauseAfterWithdrawAnimation,function() 
				if atm.ATMType.UseMoneyModel then
					atm.moneyprop = ents.Create( "prop_physics" )
					atm.moneyprop:SetModel( atm.ATMType.MoneyModel )
					atm.moneyprop:SetKeyValue("spawnflags","516")
					atm.moneyprop:SetPos( atm:LocalToWorld(atm.ATMType.WithdrawAnimationPos))
					atm.moneyprop:SetAngles( atm:LocalToWorldAngles(atm.ATMType.WithdrawAnimationAng) )
					atm.moneyprop:Spawn()
					atm.moneyprop:GetPhysicsObject():EnableCollisions(false)
					atm.moneyprop:GetPhysicsObject():EnableGravity(false)
					timer.Simple(atm.ATMType.WithdrawAnimationLength,function() 
						atm.moneyprop:GetPhysicsObject():SetVelocity(Vector(0,0,0)) 
						atm.moneyprop:GetPhysicsObject():EnableMotion( false) 
					end)
					atm.moneyprop:GetPhysicsObject():SetVelocity(atm.moneyprop:GetForward()*atm.ATMType.WithdrawAnimationSpeed.x + atm.moneyprop:GetRight()*atm.ATMType.WithdrawAnimationSpeed.y + atm.moneyprop:GetUp()*atm.ATMType.WithdrawAnimationSpeed.z)
				end
				if atm.ATMType.WithdrawAnimation != "" then
					atm:ARCLib_SetAnimationTime(atm.ATMType.WithdrawAnimation,atm.ATMType.WithdrawAnimationLength)
				end
			end)
			atm:EmitSoundTable(atm.ATMType.WithdrawSound,65,100)
			
			atm.MonehDelay = CurTime() + 8.5
			timer.Simple(atm.ATMType.PauseBeforeWithdrawAnimation + atm.ATMType.WithdrawAnimationLength + 0.5,function()
				net.Start( "ARCATM_COMM_WAITMSG" )
				net.WriteEntity( atm )
				net.WriteUInt(2,2)
				net.Send(ply)
				atm.PlayerNeedsToDoSomething = true
			end)
		else
			--atm.TakingMoney = false
			atm:EmitSoundTable(atm.ATMType.DepositStartSound,65,100)
			if #atm.ATMType.DepositLoopSound > 0 then
				atm.whirsound = CreateSound( atm, table.Random(atm.ATMType.DepositLoopSound)) 
			end			
			atm.MonehDelay = CurTime() + 5
			timer.Simple(atm.ATMType.PauseBeforeDepositAnimation, function() 
				if atm.ATMType.ModelOpen != "" then
					atm:SetModel( atm.ATMType.ModelOpen)
				end
				atm:SetSkin(atm.ATMType.OpenSkin)
				if atm.ATMType.OpenAnimation != "" then
					atm:ARCLib_SetAnimationTime(atm.ATMType.OpenAnimation,atm.ATMType.OpenAnimationLength)
				end
			end)
			timer.Simple(atm.ATMType.PauseBeforeDepositAnimation + atm.ATMType.PauseBeforeDepositSoundLoop,function()
				atm.PlayerNeedsToDoSomething = true
				if #atm.ATMType.DepositLoopSound > 0 then
					atm.whirsound:PlayEx(0.65, 100)
				end
			end)
		end
			
	end)


end

