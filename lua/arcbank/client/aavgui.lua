-- _vgui.lua - GUI for ARCBank

-- This file is under a Creative Commons Attribution 4.0 International Licence
-- http://creativecommons.org/licenses/by/4.0/
-- You can mess around with it, mod it to your liking, and even redistribute it.
-- However, you must credit me.
ARCBank.Loaded = false
ARCBank_Draw = {}
surface.CreateFont( "88888888", {
	font = "Arial",
	extended = true,
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
	extended = true,
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
	extended = true,
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
surface.CreateFont( "ARCBankATMConsole", {
	font = "Consolas",
	extended = true,
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


local LangFontProperties = {
	ARCBankATMSmall = {
		font = "Arial",
		extended = true,
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
	},

	ARCBankATMNormal = {
		font = "Arial",
		extended = true,
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
	},
	ARCBankATMBigger = {
		font = "Arial",
		extended = true,
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
	},
	
	ARCBankATMBiggerThick = {
		font = "Arial",
		size = 16,
		extended = true,
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
	},

	ARCBankHolo = {
		font = "Eras Demi ITC",
		extended = true,
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
	}
}
local LangFonts = {}
for k,v in pairs(LangFontProperties) do
	LangFonts[k] = {}
	local font = k
	surface.CreateFont(font,v)
	
	v.font = "Dotum"
	font = k.."_ko_kr"
	surface.CreateFont(font,v)
	LangFonts[k]["ko_kr"] = font
end
function ARCBank_Draw.Font(font)
	if not LangFonts[font] then return font end
	return LangFonts[font][ARCBank.Settings.language] or font
end

surface.CreateFont( "ARCBankCard", {
	font = "OCR A Extended",
	extended = true,
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

function ARCBank_Draw.Window(x,y,w,l,title,dark,mat,col)
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
		draw.SimpleText( title, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+20, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x+2, y+2, 16, 16 )
	else
		draw.SimpleText( title, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+2, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
	end
end


function ARCBank_Draw.Window_MsgBox(x,y,l,title,text,dark,typ,icon,mat,col)
	if !col then col = Color(0,0,255,255) end
	local fitstr = ARCLib.FitText(text,ARCBank_Draw.Font("ARCBankATMBigger"),l+12-(ARCLib.BoolToNumber(icon)*32))
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
		draw.SimpleText( title, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+20, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x+2, y+2, 16, 16 )
	else
		draw.SimpleText( title, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+2, y+10, txtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_CENTER  ) 
	end
	if icon then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( icon )
		surface.DrawTexturedRect( x+4, y+22, 32, 32 )
		for i = 1,#fitstr do
			draw.SimpleText( fitstr[i], ARCBank_Draw.Font("ARCBankATMBigger"),x+38, y+(i*16)+10, stxtcol, TEXT_ALIGN_LEFT , TEXT_ALIGN_TOP  )
		end
	else
		for i = 1,#fitstr do
			draw.SimpleText( fitstr[i], ARCBank_Draw.Font("ARCBankATMBigger"),x+(l*.5)+10, y+(i*16)+10, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_TOP  )
		end
	end
	local ypos,greenpos,redpos,yellowpos
	if typ == 1 then
		ypos = y+dwn+38
		greenpos = x+l-54
		
		draw.SimpleText(ARCBank.Msgs.ATMMsgs.OK, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
	elseif typ == 2 then
		ypos = y+dwn+38
		redpos = x+l-54
		greenpos = x+l-130
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.No, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Yes, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 3 then
		ypos = y+dwn+38
		redpos = x+l-54
		greenpos = x+l-130
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.OK, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 4 then
		ypos = y+dwn+38
		redpos = x+l-54
		greenpos = x+l-130
	
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Retry, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 
	elseif typ == 5 then
		ypos = y+dwn+38
		yellowpos = x+l-54
		redpos = x+l-130
		greenpos = x+l-130-76
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Cancel, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( yellowpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.No, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect(redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 

		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Yes, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95-76, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128-76, y+dwn+54,66, 2) 
	elseif typ != 0 then
		ypos = y+dwn+38
		yellowpos = x+l-54
		greenpos = x+l-130
		redpos = x+l-130-76
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Ignore, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-19, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( yellowpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 255, 0, 255 )
		surface.DrawRect( x+l-52, y+dwn+54,66, 2) 
		
		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Retry, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( greenpos, ypos, 70, 20)
		surface.SetDrawColor( 0, 255, 0, 255 )
		surface.DrawRect( x+l-128, y+dwn+54,66, 2) 

		draw.SimpleText( ARCBank.Msgs.ATMMsgs.Abort, ARCBank_Draw.Font("ARCBankATMBiggerThick"), x+l-95-76, y+dwn+47, stxtcol, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER  ) 
		surface.SetDrawColor( light, light, light, 255 )
		surface.DrawOutlinedRect( redpos, ypos, 70, 20)
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawRect( x+l-128-76, y+dwn+54,66, 2) 
	end
	return ypos,greenpos,redpos,yellowpos
end


