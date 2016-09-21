ARCBank.Settings = ARCBank.Settings || {}
function ARCBank.OnSettingChanged(key,val)
	if key == "name_long" || key == "card_weapon_slot" || key == "card_weapon_slotpos" then
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
end


