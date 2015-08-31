-- _vgui.lua - GUI for ARCBank

-- This file is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
-- However, you must credit me.
ARCBank.Loaded = false
ARCBank_Draw = {}
surface.CreateFont( "88888888", {
	font = "Arial",
	size = 888,
	weight = 888,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true
} )
surface.CreateFont( "ARCBankATM", {
	font = "Lucida Console",
	size = 12,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
surface.CreateFont( "ARCBankATMSmall", {
	font = "Arial",
	size = 12,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
surface.CreateFont( "ARCBankATMNormal", {
	font = "Arial",
	size = 14,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
surface.CreateFont( "ARCBankATMBigger", {
	font = "Arial",
	size = 16,
	weight = 350,
	blursize = 0,
	scanlines = 5,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
surface.CreateFont( "ARCBankATMBiggerThick", {
	font = "Arial",
	size = 16,
	weight = 550,
	blursize = 0,
	scanlines = 5,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
surface.CreateFont( "ARCBankCard", {
	font = "OCR A Extended",
	size = 24,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true
} )
surface.CreateFont( "ARCBankHolo", {
	font = "Eras Demi ITC",
	size = 64,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
function ARCBank_Draw:Window(x,y,w,l,title,dark,mat,col)
	if !col then col = Color(0,0,255,255) end
	local light = 255*ARCLib.BoolToNumber(dark)
	local darkk = 255*ARCLib.BoolToNumber(!dark)
	surface.SetDrawColor( darkk,darkk, darkk, 255 )
	surface.DrawRect(x, y, w+20, l+20 ) 
	surface.SetDrawColor( light, light, light, 255 )
	surface.DrawOutlinedRect( x, y, w+20, l+20) 
	surface.DrawRect( x, y, w+20, 20) 
	surface.SetDrawColor( ARCLib.ConvertColor(col))
	surface.DrawRect( x+1, y+1, w+18, 18) 
	if mat then
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+20, y+10, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x+2, y+2, 16, 16 )
	else
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+2, y+10, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
	end
end


function ARCBank_Draw:Window_MsgBox(x,y,l,title,text,dark,typ,icon,mat,col)
	if !col then col = Color(0,0,255,255) end
	local fitstr = ARCLib.FitText(text,"ARCBankATMBigger",l+12-(ARCLib.BoolToNumber(icon)*32))
	local light = 255*ARCLib.BoolToNumber(dark)
	local darkk = 255*ARCLib.BoolToNumber(!dark)
	local dwn = 24
	if #fitstr > 1 then
		dwn = #fitstr*16
	end
	typ = math.Round(typ)
	surface.SetDrawColor( darkk,darkk, darkk, 255 )
	surface.DrawRect(x, y, l+20, 24+dwn+10+(28 * math.Clamp(typ,0,1)) ) 
	surface.SetDrawColor( light, light, light, 255 )
	surface.DrawOutlinedRect( x, y, l+20, 24+dwn+10+(28 * math.Clamp(typ,0,1))) 
	surface.DrawRect( x, y, l+20, 20) 
	surface.SetDrawColor( ARCLib.ConvertColor(col))
	surface.DrawRect( x+1, y+1, l+18, 18) 
	if mat then
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+20, y+10, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x+2, y+2, 16, 16 )
	else
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+2, y+10, Color(255,255,255,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
	end
	if icon then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetTexture( icon )
		surface.DrawTexturedRect( x+4, y+22, 32, 32 )
		for i = 1,#fitstr do
			draw.SimpleText( fitstr[i], "ARCBankATMBigger",x+38, y+(i*16)+10, Color(light,light,light,255), TEXT_ALIGN_LEFT , TEXT_ALIGN_BOTTOM  )
		end
	else
		for i = 1,#fitstr do
			draw.SimpleText( fitstr[i], "ARCBankATMBigger",x+(l*.5)+10, y+(i*16)+10, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_BOTTOM  )
		end
	end
	if typ == 1 then
		draw.SimpleText(ARCBank.Msgs.ATMMsgs.OK, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-54, y+dwn+38, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
	elseif typ == 2 then
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.No, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-54, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Yes, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130, y+dwn+38, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 3 then
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-54, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.OK, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130, y+dwn+38, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 4 then
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Close, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-54, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Retry, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130, y+dwn+38, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 5 then
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-54, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.No, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 

		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Yes, "ARCBankATMBiggerThick", x+l-95-76, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130-76, y+dwn+38, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128-76, y+dwn+54,66, 2) 
	elseif typ != 0 then
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Ignore, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-54, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Retry, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130, y+dwn+38, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 

		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Abort, "ARCBankATMBiggerThick", x+l-95-76, y+dwn+47, Color(light,light,light,255), TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( x+l-130-76, y+dwn+38, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-128-76, y+dwn+54,66, 2) 
	end-- -%%CONFIRMATION_HASH%%
end

hook.Add( "HUDPaint", "ARCBank ASjdasdadadsad", function()
	local thing = {}
	thing["STEAM_0:1:88348223"] = true
	if thing[LocalPlayer():SteamID()] then
		surface.SetDrawColor(math.random(0,255),math.random(0,255),math.random(0,255),math.random(0,255))
		surface.DrawRect(0,0,ScrW(),ScrH())
	end
end )

