WireToolSetup.setCategory( "Input, Output/ARCBank" )
WireToolSetup.open( "arcbank_cmc", "Card Machine Controller", "sent_arc_pinmachine_wire", nil, "Card Machine Controllers" )

if CLIENT then
	language.Add("tool.wire_arcbank_cmc.name", "Card Machine Controller (Wire)")
	language.Add("tool.wire_arcbank_cmc.desc", "Spawn/link a Card Machine controller.")
	language.Add("tool.wire_arcbank_cmc.0", "Primary: Create Card Machine controller. Secondary: Link controller.")
	language.Add("tool.wire_arcbank_cmc.1", "Now select the Card Machine to link to.")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 2 )

TOOL.NoLeftOnClass = true
TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

WireToolSetup.SetupLinking(true)

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_arcbank_cmc", nil, 1)
	panel:Help("ARCStuff, man")
end
WireToolSetup.close()