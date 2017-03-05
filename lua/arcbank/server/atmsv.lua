-- atmsv.lua - ATM Spanwer for ARCBank

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2016-2017 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false
function ARCBank.SpawnATMs()
	local shit = file.Read(ARCBank.Dir.."/saved_atms/"..string.lower(game.GetMap())..".txt", "DATA" )
	if !shit then
		ARCBank.Msg("Cannot spawn ATMs. No file associated with this map.")
		return false
	end
	local atmdata = util.JSONToTable(shit)
	if !atmdata then
		ARCBank.Msg("Cannot spawn ATMs. Corrupt file associated with this map.")
		return false
	end
	for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
		oldatms.ARCBank_MapEntity = false
		oldatms:Remove()
	end
	ARCBank.Msg("Spawning Map ATMs...")
	for i=1,atmdata.atmcount do
			local shizniggle = ents.Create("sent_arc_atm")
			if !IsValid(shizniggle) then
				atmdata.atmcount = 1
				ARCBank.Msg("ATMs failed to spawn.")
			return false end
			if atmdata.pos[i] && atmdata.angles[i] then
				shizniggle:SetPos(atmdata.pos[i]+Vector(0,0,ARCLib.BoolToNumber(!atmdata.NewATMModel)*8.6))
				shizniggle:SetAngles(atmdata.angles[i])
				shizniggle:SetPos(shizniggle:GetPos()+(shizniggle:GetRight()*ARCLib.BoolToNumber(!atmdata.NewATMModel)*-4.1)+(shizniggle:GetForward()*ARCLib.BoolToNumber(!atmdata.NewATMModel)*19))
				if atmdata.atmtype then
					shizniggle.ARCBank_InitSpawnType = atmdata.atmtype[i]
				end
				shizniggle:Spawn()
				shizniggle:Activate()
			else
				shizniggle:Remove()
				atmdata.atmcount = 1
				ARCBank.Msg("Corrupt File")
				return false 
			end
			local phys = shizniggle:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion( false )
			end
			shizniggle.ARCBank_MapEntity = true
			shizniggle.ARitzDDProtected = true
	end
	return true
end
function ARCBank.SaveATMs()
	ARCBank.Msg("Saving ATMs...")
	local atmdata = {}
	atmdata.angles = {}
	atmdata.pos = {}
	atmdata.atmtype = {}
	local atms = ents.FindByClass("sent_arc_atm")
	atmdata.atmcount = table.maxn(atms)
	atmdata.NewATMModel = true
	if atmdata.atmcount <= 0 then
		ARCBank.Msg("No ATMs to save!")
		return false
	end
	for i=1,atmdata.atmcount do
		local phys = atms[i]:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion( false )
		end
		atms[i].ARCBank_MapEntity = true
		atms[i].ARitzDDProtected = true
		atmdata.pos[i] = atms[i]:GetPos()
		atmdata.angles[i] = atms[i]:GetAngles()
		atmdata.atmtype[i] = atms[i]:GetATMType()
	end
	PrintTable(atmdata)
	local savepos = ARCBank.Dir.."/saved_atms/"..string.lower(game.GetMap())..".txt"
	file.Write(savepos,util.TableToJSON(atmdata))
	if file.Exists(savepos,"DATA") then
		ARCBank.Msg("ATMs Saved in: "..savepos)
		return true
	else
		ARCBank.Msg("Error while saving map.")
		return false
	end
end
function ARCBank.UnSaveATMs()
	ARCBank.Msg("UnSaving ATMs...")
	local atms = ents.FindByClass("sent_arc_atm")
	if table.maxn(atms) <= 0 then
		ARCBank.Msg("No ATMs to Unsave!")
		return false
	end
	for i=1,table.maxn(atms) do
		local phys = atms[i]:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion( true )
		end
		atms[i].ARCBank_MapEntity = false
		atms[i].ARitzDDProtected = false
	end
	local savepos = ARCBank.Dir.."/saved_atms/"..string.lower(game.GetMap())..".txt"
	file.Delete(savepos)
	return true
end
function ARCBank.ClearATMs()
	for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
		oldatms.ARCBank_MapEntity = false
		oldatms:Remove()
	end
	ARCBank.Msg("All ATMs Removed.")
end

