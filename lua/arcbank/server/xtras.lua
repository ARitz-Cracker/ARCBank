-- xtras.lua - Non-critical enhancment functions

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.

function ARCBank.CapAccountRank(ply)
	if !IsValid(ply) then
		for k,v in ipairs(player.GetHumans()) do
			ARCBank.CapAccountRank(v)
		end
		return
	end
	ARCBank.GetOwnedAccounts(ply,function(err,data)
		if err != ARCBANK_ERROR_NONE then return end
		for i=1,#data do
			ARCBank.ReadAccountProperties(data[i],function(err,data)
				if err != ARCBANK_ERROR_NONE then return end
				local isgroup = data.rank > ARCBANK_GROUPACCOUNTS_
				local maxrank = ARCBank.MaxAccountRank(ply,isgroup)
				if data.rank > maxrank then
					ARCBank.WriteAccountProperties(data[i],nil,nil,maxrank,function(err)
						if err == ARCBANK_ERROR_NONE then
							ARCBank.WriteTransaction(data[i],nil,ply,nil,0,nil,ARCBANK_TRANSACTION_DOWNGRADE,nil,NULLFUNC)
						end
					end)
				end
			end)
		end
	end)
end