-- xtras.lua - Non-critical enhancment functions

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014,2015 Aritz Beobide-Cardinal All rights reserved.

function ARCBank.CapAccountRank(ply) -- %%CONFIRMATION_HASH%%
	if !IsValid(ply) || !ply:IsPlayer() then
		for k,v in pairs(player.GetHumans()) do
			ARCBank.CapAccountRank(v)
		end
	else
		ARCBank.ReadAccountFile(ARCBank.GetAccountID(ARCBank.GetPlayerID(ply)),false,function(accdata)
			if (accdata) then
				local maxrank = ARCBank.MaxAccountRank(ply,false)
				if maxrank == ARCBANK_PERSONALACCOUNTS_ then
					maxrank = ARCBANK_PERSONALACCOUNTS_STANDARD
				end
				if accdata.rank > maxrank then
					accdata.rank = maxrank
					ARCBank.WriteAccountFile(accdata,function(wop) end)
				end
			end
		end)
		ARCBank.GroupAccountOwner(ply,function(err,dat)
			if err == ARCBANK_ERROR_NONE then
				local maxrank = ARCBank.MaxAccountRank(ply,true)
				--MsgN(tostring(ply).."'s max rank: "..maxrank)
				if maxrank == ARCBANK_GROUPACCOUNTS_ then
					maxrank = ARCBANK_GROUPACCOUNTS_STANDARD
				end
				for i=1,#dat do
					ARCBank.ReadAccountFile(ARCBank.GetAccountID(dat[i]),true,function(accdata)
						if (accdata) then
							if accdata.rank > maxrank then
								accdata.rank = maxrank
								ARCBank.WriteAccountFile(accdata,function(wop) end)
							end
						end
					end)
				end
			end
		end)
	end
end