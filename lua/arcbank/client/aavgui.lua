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
surface.CreateFont( "ARCBankHacker", {
	font = "Lucida Console",
	size = 24,
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
surface.CreateFont( "ARCBankATMConsole", {
	font = "Consolas",
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
	local txtcol = color_white
	if col.r + col.g + col.b > 450 then
		txtcol = color_black
	end
	surface.SetDrawColor( darkk,darkk, darkk, 255 )
	surface.DrawRect(x, y, w+20, l+20 ) 
	surface.SetDrawColor( light, light, light, 255 )
	surface.DrawOutlinedRect( x, y, w+20, l+20) 
	surface.DrawRect( x, y, w+20, 20) 
	surface.SetDrawColor( ARCLib.ConvertColor(col))
	surface.DrawRect( x+1, y+1, w+18, 18) 
	if mat then
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+20, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x+2, y+2, 16, 16 )
	else
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+2, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
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
	
	local txtcol = color_white
	if col.r + col.g + col.b > 450 then
		txtcol = color_black
	end
	
	local stxtcol = color_black
	if dark then
		stxtcol = color_white
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
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+20, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x+2, y+2, 16, 16 )
	else
		draw.SimpleText( title, "ARCBankATMBiggerThick", x+2, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
	end
	if icon then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( icon )
		surface.DrawTexturedRect( x+4, y+22, 32, 32 )
		for i = 1,#fitstr do
			draw.SimpleText( fitstr[i], "ARCBankATMBigger",x+38, y+(i*16)+10, stxtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		end
	else
		for i = 1,#fitstr do
			draw.SimpleText( fitstr[i], "ARCBankATMBigger",x+(l*.5)+10, y+(i*16)+10, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_TOP  )
		end
	end
	local ypos,greenpos,redpos,yellowpos
	if typ == 1 then
		ypos = y+dwn+38
		greenpos = x+l-54
		
		draw.SimpleText(ARCBank.Msgs.ATMMsgs.OK, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
	elseif typ == 2 then
		ypos = y+dwn+38
		redpos = x+l-54
		greenpos = x+l-130
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.No, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Yes, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 3 then
		ypos = y+dwn+38
		redpos = x+l-54
		greenpos = x+l-130
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.OK, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 4 then
		ypos = y+dwn+38
		redpos = x+l-54
		greenpos = x+l-130
	
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Retry, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 5 then
		ypos = y+dwn+38
		yellowpos = x+l-54
		redpos = x+l-130
		greenpos = x+l-130-76
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( yellowpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.No, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect(redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 

		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Yes, "ARCBankATMBiggerThick", x+l-95-76, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128-76, y+dwn+54,66, 2) 
	elseif typ != 0 then
		ypos = y+dwn+38
		yellowpos = x+l-54
		greenpos = x+l-130
		redpos = x+l-130-76
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Ignore, "ARCBankATMBiggerThick", x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( yellowpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Retry, "ARCBankATMBiggerThick", x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 

		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Abort, "ARCBankATMBiggerThick", x+l-95-76, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-128-76, y+dwn+54,66, 2) 
	end
	return ypos,greenpos,redpos,yellowpos
end


