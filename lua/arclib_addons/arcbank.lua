-- This code is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014-2017 Aritz Beobide-Cardinal All rights reserved.


ARCBank = ARCBank or {}
function ARCBank.Msg(msg)
	if ARCBank.Settings && ARCBank.Settings.name then
		Msg(ARCBank.Settings.name..": "..tostring(msg).."\n")
	else
		Msg("ARCBank: "..tostring(msg).."\n")
	end
	if ARCBank.LogFileWritten then
		file.Append(ARCBank.LogFile, os.date("%Y-%m-%d %H:%M:%S").." > "..tostring(msg).."\r\n")
	end
end
ARCBank.Msg("Running...\n ____ ____ _ ___ ___     ____ ____ ____ ____ _  _ ____ ____    ___  ____ _  _ _  _ _ _  _ ____ \n |__| |__/ |  |    /     |    |__/ |__| |    |_/  |___ |__/    |__] |__| |\\ | |_/  | |\\ | | __ \n |  | |  \\ |  |   /__    |___ |  \\ |  | |___ | \\_ |___ |  \\    |__] |  | | \\| | \\_ | | \\| |__] \n")
ARCBank.Msg(table.Random({"I'm going to run out of letters in the alphabet if I keep these patches up!","Product of BlueStone Technological Enterprises Inc. (Even before that company existed)","tbh script enforcer is kinda shit.","I am embarrassed to say that there was a bug from v1.0 to v1.3 that made arguably one of the most important settings useless...","Eh, ARCLoad was a paranoid idiots dream anyway...","Super fukin' Sexy edition!","The most realistic ATM system you'll ever see!","Wohoo! Manual Updates!","...I can never get a vacation...","I love you.","Isn't this amazing?","That's one fiiiine addon you got there!","Update, Update, Update!","You can ACTUALLY use an ATM!","Fixin' Bugs!"}))
ARCBank.Msg("© Copyright 2014-2017 Aritz Beobide-Cardinal (ARitz Cracker) All rights reserved.")


ARCBank.Features = {}
ARCBank.Features["hackapi"] = true

ARCBank.Update = "March 4th 2017"
ARCBank.Version = "1.4.0b"


ARCBank.About = [[
             *** ARitz Cracker Bank ***
    © Copyright Aritz Beobide-Cardinal 2014-2017
                All rights reserved.
				
				
If you're having any trouble, please visit:
www.aritzcracker.ca
	
Coding, Models, and Custom textures by:
 *    Aritz Beobide-Cardinal (ARitz Cracker) (STEAM_0:0:18610144)
	
ATM Model by:
 *    [Whatever his name is this week] (STEAM_0:1:34654275)

Translations:
 *    Go to github.com/ARitz-Cracker/aritzcracker-addon-translations
 *    You can see everyone who helped out with translations by pressing the "contributors" tab!
 
ALPHA Testers:
 *    Noddy (Senior Crayfish)
 *    Dr Fetus
 *    Quinn50
 *    Toogit
 *    Pookie
 *    Shadow
 *    HomelessGoomba
 *    Foohy
 *    Teh Neon
 *    Gm Matsilagi
 *    Ryuken Ishida
 *    Drew dawg 2000
 *    Slashll
 *    UTNerd24

Guinea Pigs
 *    Ventz - Thanks for letting me test future ARCBank updates on your Civil Gamers community.
 
Special Thanks:
 *    Everyone who participated in the public BETA by buying ARCBank before March 31st 2014.
 *    All my great customers, and my future customers.
 *    Noddy (Senior Crayfish) - For inspiring me to create this and place this on CoderHire.
 *    My family - For supporting me.
 *    Snow Lou - I wouldn't be who I am without you.
 *    You - For supporting me by using this addon
	
Originally made for:
Vortex Gaming

]]
-- TRANSACTION TYPES
ARCBANK_TRANSACTION_WITHDRAW_OR_DEPOSIT = 1 -- Withdraw/deposit
ARCBANK_TRANSACTION_TRANSFER = 2 -- Transfer
ARCBANK_TRANSACTION_INTEREST = 4 -- Interest
ARCBANK_TRANSACTION_UPGRADE = 8 -- Upgrade
ARCBANK_TRANSACTION_DOWNGRADE = 16 -- Downgrade
ARCBANK_TRANSACTION_GROUP_ADD = 32 -- Add member
ARCBANK_TRANSACTION_GROUP_REMOVE = 64 -- Remove member
ARCBANK_TRANSACTION_CREATE = 128 -- Create
ARCBANK_TRANSACTION_DELETE = 256 -- Delete
ARCBANK_TRANSACTION_SALARY = 512
ARCBANK_TRANSACTION_OTHER = 32768
ARCBANK_TRANSACTION_EVERYTHING = 65535 -- everything

-- PERMISSIONS
ARCBANK_PERMISSIONS_READ = 1
ARCBANK_PERMISSIONS_READ_LOG = 2
ARCBANK_PERMISSIONS_DEPOSIT = 4
ARCBANK_PERMISSIONS_WITHDRAW = 8
ARCBANK_PERMISSIONS_TRANSFER = 16
ARCBANK_PERMISSIONS_RANK = 32
ARCBANK_PERMISSIONS_MEMBERS = 64
ARCBANK_PERMISSIONS_CREATE = 128
ARCBANK_PERMISSIONS_OTHER = 32768
ARCBANK_PERMISSIONS_EVERYTHING = 65535 -- everything



--TRANSACTION ERRORS
ARCBANK_ERRORSTRINGS = {}
ARCBANK_ERROR_DOWNLOADING = -2
ARCBANK_ERROR_ABORTED = -1
ARCBANK_ERROR_NONE = 0
ARCBANK_NO_ERROR = 0
ARCBANK_ERROR_NIL_ACCOUNT = 1
ARCBANK_ERROR_NO_ACCESS = 2
ARCBANK_ERROR_NO_CASH = 3
ARCBANK_ERROR_NO_CASH_PLAYER = 4
ARCBANK_ERROR_PLAYER_FOREVER_ALONE = 5
ARCBANK_ERROR_NIL_PLAYER = 6
ARCBANK_ERROR_DUPE_PLAYER = 7
ARCBANK_ERROR_TOO_MUCH_CASH = 8
ARCBANK_ERROR_DEBT = 9
ARCBANK_ERROR_BUSY = 10
ARCBANK_ERROR_TIMEOUT = 11
ARCBANK_ERROR_READ_FAILURE = 12
ARCBANK_ERROR_INVALID_PIN = 13
ARCBANK_ERROR_CHUNK_MISMATCH = 14
ARCBANK_ERROR_CHUNK_TIMEOUT = 15
ARCBANK_ERROR_WRITE_FAILURE = 16
ARCBANK_ERROR_EXPLOIT = 17
ARCBANK_ERROR_DOWNLOAD_FAILED = 18
ARCBANK_ERROR_CORRUPT_ACCOUNT = 19
ARCBANK_ERROR_DEADLOCK = 20
ARCBANK_ERROR_ENTITY_NO_ACCESS = 21
ARCBANK_ERROR_LOG_EMPTY = 22

--CREATION ERRORS
ARCBANK_ERROR_NAME_DUPE = 32
ARCBANK_ERROR_NAME_TOO_LONG = 33
ARCBANK_ERROR_INVALID_NAME = 34
ARCBANK_ERROR_UNDERLING = 35
ARCBANK_ERROR_INVALID_RANK = 36
ARCBANK_ERROR_TOO_MANY_ACCOUNTS = 37
ARCBANK_ERROR_TOO_MANY_PLAYERS = 38
ARCBANK_ERROR_DELETE_REFUSED = 39

--OTHER ERRORS
ARCBANK_ERROR_NOT_LOADED = -127
ARCBANK_ERROR_UNKNOWN = -128

ARCBANK_ERRORBITRATE = 8


--ACCOUNTS
ARCBANK_ACCOUNTSTRINGS = {}
ARCBANK_PERSONALACCOUNTS_ = 0
ARCBANK_ACCOUNTSTRINGS[0] = "invalid" --These are internally handled by the ARCBank system, do not edit these.
ARCBANK_PERSONALACCOUNTS_STANDARD = 1
ARCBANK_ACCOUNTSTRINGS[1] = "standard"
ARCBANK_PERSONALACCOUNTS_BRONZE = 2
ARCBANK_ACCOUNTSTRINGS[2] = "bronze"
ARCBANK_PERSONALACCOUNTS_SILVER = 3
ARCBANK_ACCOUNTSTRINGS[3] = "silver"
ARCBANK_PERSONALACCOUNTS_GOLD = 4
ARCBANK_ACCOUNTSTRINGS[4] = "gold"
ARCBANK_GROUPACCOUNTS_ = 5
ARCBANK_ACCOUNTSTRINGS[5] = "group_invalid"
ARCBANK_GROUPACCOUNTS_STANDARD = 6
ARCBANK_ACCOUNTSTRINGS[6] = "group_standard"
ARCBANK_GROUPACCOUNTS_PREMIUM = 7
ARCBANK_ACCOUNTSTRINGS[7] = "group_premium"
ARCBANK_ACCOUNTBITRATE = 4
ARCBank.Msg("Version: "..ARCBank.Version)
ARCBank.Msg("Updated on: "..ARCBank.Update)
if SERVER then
	resource.AddWorkshop( "200318235" )

	function ARCBank.MsgCL(ply,msg)
		--net.Start( "ARCBank_Msg" )
		--net.WriteString( msg )
		if !IsValid(ply) || !ply:IsPlayer() then
			ARCBank.Msg(tostring(msg))
		else
			if ARCBank.Settings && ARCBank.Settings.name then
				ply:PrintMessage( HUD_PRINTTALK, ARCBank.Settings.name..": "..tostring(msg))
			else
				ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..tostring(msg))
			end
			--net.Send(ply)
		end
	end


	--hook.Add( "ARCLoad_OnLoaded", "ARCBank Load", function(loaded) ARCBank.Load() end )

end
return "ARCBank","ARCBank",{"arclib"}