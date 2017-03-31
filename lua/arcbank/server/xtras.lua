-- xtras.lua - Non-critical enhancment functions

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

function ARCBank.OnSettingChanged(key,val)
	if string.StartWith( key, "usergroup_" ) then
		for i=1,#val do
			print(val[i])
			val[i] = string.lower(val[i])
		end
	end
end

function ARCBank.CapAccountRank(ply)
	if not IsValid(ply) then
		ARCBank.FixInvalidAccountRanks(function(err)
			ARCBank.Msg("Account rank fixing progress: "..err)
			for k,v in ipairs(player.GetHumans()) do
				ARCBank.CapAccountRank(v)
			end
		end)
		return
	end
	local user1 = ARCBank.GetPlayerID(ply)
	if not user1 then return end
	ARCBank.ReadOwnedAccounts(user1,function(err,data)
		if err != ARCBANK_ERROR_NONE then return end
		if not IsValid(ply) then return end
		
		for i=1,#data do
			local account = data[i]
			ARCBank.ReadAccountProperties(account,function(err,data)
				if err != ARCBANK_ERROR_NONE then return end
				if not IsValid(ply) then return end
				local isgroup = data.rank > ARCBANK_GROUPACCOUNTS_
				local maxrank = ARCBank.MaxAccountRank(ply,isgroup)
				if maxrank == ARCBANK_PERSONALACCOUNTS_ or maxrank == ARCBANK_GROUPACCOUNTS_ then return end
				if data.rank > maxrank then
					ARCBank.WriteAccountProperties(account,nil,nil,maxrank,function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.WriteTransaction(account,nil,user1,nil,0,nil,ARCBANK_TRANSACTION_DOWNGRADE,"Usergroup Cap",NULLFUNC)
						end
					end)
				end
			end)
		end
	end)
end

function ARCBank.FixInvalidAccountRanks(callback)
	ARCBank.ReadAllAccountProperties(function(err,accounts)
		if err == ARCBANK_ERROR_NONE then
			for i=1,#accounts do
				local accountdata = accounts[i]
				local rank = 0
				if accountdata.rank == ARCBANK_PERSONALACCOUNTS_ then
					rank = ARCBANK_PERSONALACCOUNTS_STANDARD
				elseif accountdata.rank == ARCBANK_GROUPACCOUNTS_ then
					rank = ARCBANK_GROUPACCOUNTS_STANDARD
				end
				if rank > 0 then
					ARCBank.WriteAccountProperties(accountdata.account,nil,nil,rank,callback)
				end
			end
		else
			callback(err)
		end
	end)
end