--default_lang.lua - default language

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014 Aritz Beobide-Cardinal All rights reserved.

ARCBank.Msgs = ARCBank.Msgs or {}
ARCBank.Msgs.Time = ARCBank.Msgs.Time or {}
ARCBank.Msgs.ATMMsgs = ARCBank.Msgs.ATMMsgs or {}
ARCBank.Msgs.CardMsgs = ARCBank.Msgs.CardMsgs or {}
ARCBank.Msgs.UserMsgs = ARCBank.Msgs.UserMsgs or {}
ARCBank.Msgs.Hack = ARCBank.Msgs.Hack or {}
ARCBank.Msgs.AdminMenu = ARCBank.Msgs.AdminMenu or {}
ARCBank.Msgs.AccountRank = ARCBank.Msgs.AccountRank or {}
ARCBank.Msgs.Commands = ARCBank.Msgs.Commands or {}
ARCBank.Msgs.CommandOutput = ARCBank.Msgs.CommandOutput or {}
ARCBank.Msgs.Items = ARCBank.Msgs.Items or {}
ARCBank.Msgs.ATMCreator = ARCBank.Msgs.ATMCreator or {}
ARCBank.Msgs.LogMsgs = ARCBank.Msgs.LogMsgs or {}


ARCBANK_ERRORSTRINGS = ARCBANK_ERRORSTRINGS or {}
ARCBank.SettingsDesc = ARCBank.SettingsDesc or {}

--[[
 ____   ___    _   _  ___ _____   _____ ____ ___ _____   _____ _   _ _____   _    _   _   _      _____ ___ _     _____ _ 
|  _ \ / _ \  | \ | |/ _ \_   _| | ____|  _ \_ _|_   _| |_   _| | | | ____| | |  | | | | / \    |  ___|_ _| |   | ____| |
| | | | | | | |  \| | | | || |   |  _| | | | | |  | |     | | | |_| |  _|   | |  | | | |/ _ \   | |_   | || |   |  _| | |
| |_| | |_| | | |\  | |_| || |   | |___| |_| | |  | |     | | |  _  | |___  | |__| |_| / ___ \  |  _|  | || |___| |___|_|
|____/ \___/  |_| \_|\___/ |_|   |_____|____/___| |_|     |_| |_| |_|_____| |_____\___/_/   \_\ |_|   |___|_____|_____(_)

 ____   ___    _   _  ___ _____   _____ ____ ___ _____   _____ _   _ _____   _    _   _   _      _____ ___ _     _____ _ 
|  _ \ / _ \  | \ | |/ _ \_   _| | ____|  _ \_ _|_   _| |_   _| | | | ____| | |  | | | | / \    |  ___|_ _| |   | ____| |
| | | | | | | |  \| | | | || |   |  _| | | | | |  | |     | | | |_| |  _|   | |  | | | |/ _ \   | |_   | || |   |  _| | |
| |_| | |_| | | |\  | |_| || |   | |___| |_| | |  | |     | | |  _  | |___  | |__| |_| / ___ \  |  _|  | || |___| |___|_|
|____/ \___/  |_| \_|\___/ |_|   |_____|____/___| |_|     |_| |_| |_|_____| |_____\___/_/   \_\ |_|   |___|_____|_____(_)
                                                                                                                         

 ____   ___    _   _  ___ _____   _____ ____ ___ _____   _____ _   _ _____   _    _   _   _      _____ ___ _     _____ _ 
|  _ \ / _ \  | \ | |/ _ \_   _| | ____|  _ \_ _|_   _| |_   _| | | | ____| | |  | | | | / \    |  ___|_ _| |   | ____| |
| | | | | | | |  \| | | | || |   |  _| | | | | |  | |     | | | |_| |  _|   | |  | | | |/ _ \   | |_   | || |   |  _| | |
| |_| | |_| | | |\  | |_| || |   | |___| |_| | |  | |     | | |  _  | |___  | |__| |_| / ___ \  |  _|  | || |___| |___|_|
|____/ \___/  |_| \_|\___/ |_|   |_____|____/___| |_|     |_| |_| |_|_____| |_____\___/_/   \_\ |_|   |___|_____|_____(_)
                                                                                                                         
																														 
These are the default values in order to prevent you from screwing it up!

For a tutorial on how to create your own custom language, READ THE README!

There's even a command that lets you select from a range of pre-loaded languages!

type "arcbank settings language (lang)" in console
(lang) can be the following:
en -- English
fr -- French
ger -- German
pt_br -- Brazilian Portuguese
sp -- Spanish
]]

ARCBANK_ERRORSTRINGS[-2] = "Downloading..."
ARCBANK_ERRORSTRINGS[-1] = "Operation Aborted"
ARCBANK_ERRORSTRINGS[0] = "Completed Successfully"

ARCBANK_ERRORSTRINGS[4] = "Your wallet doesn't have enough cash!"
ARCBANK_ERRORSTRINGS[3] = "The account doesn't have enough money!"
ARCBANK_ERRORSTRINGS[2] = "You do not have access to this operation!"
ARCBANK_ERRORSTRINGS[1] = "Account doesn't exist!"

ARCBANK_ERRORSTRINGS[5] = "You do not have access to any group accounts. :("
ARCBANK_ERRORSTRINGS[6] = "The player you tried to select doesn't exist or is invalid."
ARCBANK_ERRORSTRINGS[7] = "The player you tried to add to the group is already a member!"
ARCBANK_ERRORSTRINGS[8] = "An account cannot have more than 100 Trillion Credits"
ARCBANK_ERRORSTRINGS[9] = "You can't do this while you're in debt!"
ARCBANK_ERRORSTRINGS[10] = "System is busy. Try again later."
ARCBANK_ERRORSTRINGS[11] = "Server took too long to respond."
ARCBANK_ERRORSTRINGS[12] = "Failure accessing database."
ARCBANK_ERRORSTRINGS[13] = "Incorrect PIN."
ARCBANK_ERRORSTRINGS[14] = "Download failed. Miscommunication error."
ARCBANK_ERRORSTRINGS[15] = "Server took too long to send data."
ARCBANK_ERRORSTRINGS[16] = "Failure writing to database."
ARCBANK_ERRORSTRINGS[17] = "Fuck you, you SUP3R L33T H4X0R!"
ARCBANK_ERRORSTRINGS[18] = "Download failed. Data is corrupted."

ARCBANK_ERRORSTRINGS[32] = "Account with the same or a similar name already exists."
ARCBANK_ERRORSTRINGS[33] = "Account name is too long."
ARCBANK_ERRORSTRINGS[34] = "Invalid account name"
ARCBANK_ERRORSTRINGS[35] = "You don't have a high enough player rank."
ARCBANK_ERRORSTRINGS[36] = "Cannot create/upgrade account. Invalid account rank."


ARCBANK_ERRORSTRINGS[37] = "You've reached the limit of accounts you can have."
ARCBANK_ERRORSTRINGS[38] = "There are too many players in this group."
ARCBANK_ERRORSTRINGS[39] = "You cannot close a personal account."
ARCBANK_ERRORSTRINGS[-127] = "The ARCBank system failed to load."
ARCBANK_ERRORSTRINGS[-128] = "Unknown Error. Try again."

ARCBank.Msgs.LogMsgs.Interest = "Added %VALUE% interest to account."
ARCBank.Msgs.LogMsgs.AddUser = "Added (%PLAYER%) to group."
ARCBank.Msgs.LogMsgs.RemoveUser = "Removed (%PLAYER%) from group."
ARCBank.Msgs.LogMsgs.AddMoney = "(%PLAYER%) added %VALUE% to the account. "
ARCBank.Msgs.LogMsgs.RemoveMoney = "(%PLAYER%) subtracted %VALUE% from the account. "
ARCBank.Msgs.LogMsgs.GiveMoney = "(%PLAYER1%) gave %VALUE% to (%PLAYER2%) (From this account to %ACCOUNT%)"
ARCBank.Msgs.LogMsgs.TakeMoney = "(%PLAYER1%) gave %VALUE% to (%PLAYER2%) (From %ACCOUNT% to this account)"

ARCBank.Msgs.ATMCreator.Options = "This is option #%OPTION% (Button #%BUTTON%)","ARCBankATMNormal"
ARCBank.Msgs.ATMCreator.MsgBox = "Error: Your custom ATM is too awesome!"
ARCBank.Msgs.ATMCreator.EnterName = "No name specified."
ARCBank.Msgs.ATMCreator.EnterModel = "The specified ATM doesn't exist. In order for you to create one with that name, you must specify a valid model. (arcbank create_atm my_atm path/to/model.mdl"
ARCBank.Msgs.ATMCreator.SavedFile = "Custom ATM has been saved as %FILENAME% on the server."
ARCBank.Msgs.ATMCreator.Name = "ARCBank ATM Creator"
ARCBank.Msgs.ATMCreator.SaveTitle = "Save the custom atm!"
ARCBank.Msgs.ATMCreator.SaveAs = "Save as..."
ARCBank.Msgs.ATMCreator.Save = "Save"
ARCBank.Msgs.ATMCreator.NoSave = "Don't save"
ARCBank.Msgs.ATMCreator.SoundExplination = "When playing the %SOUNDNAME%, a random sound will play from the specified list. If your sound doesn't seem to be playing in 3D ingame, you will have to add a \"^\" before your sound. For example: ^arcbank/atm-spit-out.wav"
ARCBank.Msgs.ATMCreator.HackedExplination = "While recovering from a hack, the welcome screen will choose a random texture from the following list every 0.1ish seconds."
ARCBank.Msgs.ATMCreator.PositionX = "X Position"
ARCBank.Msgs.ATMCreator.PositionY = "Y Position"
ARCBank.Msgs.ATMCreator.PositionZ = "Z Position"
ARCBank.Msgs.ATMCreator.AngleP = "Pitch Angle"
ARCBank.Msgs.ATMCreator.AngleY = "Yaw Angle"
ARCBank.Msgs.ATMCreator.AngleR = "Roll Angle"
ARCBank.Msgs.ATMCreator.SpeedF = "Speed Forward"
ARCBank.Msgs.ATMCreator.SpeedR = "Speed Right"
ARCBank.Msgs.ATMCreator.SpeedU = "Speed Up"
ARCBank.Msgs.ATMCreator.ScreenSize = "Size"
ARCBank.Msgs.ATMCreator.ScreenWide = "Width"
ARCBank.Msgs.ATMCreator.ScreenHeight = "Height"
ARCBank.Msgs.ATMCreator.Fill = "Fill"
ARCBank.Msgs.ATMCreator.UseLight = "Use Light"
ARCBank.Msgs.ATMCreator.BGColour = "Background Colour"
ARCBank.Msgs.ATMCreator.FGColour = "Foreground Colour"
ARCBank.Msgs.ATMCreator.DarkMode = "Dark Mode"
ARCBank.Msgs.ATMCreator.ShowMenu = "Show Menu"
ARCBank.Msgs.ATMCreator.MessageBox = "Message Box"
ARCBank.Msgs.ATMCreator.Hacked = "Hacked"
ARCBank.Msgs.ATMCreator.WelScrMat = "Welcome screen material (Press ENTER to apply)"
ARCBank.Msgs.ATMCreator.HckWelScr = "Hacked welcome screen"
ARCBank.Msgs.ATMCreator.IntrTouch = "Interface type: Touchscreen"
ARCBank.Msgs.ATMCreator.IntrButt = "Interface type: Buttons"
ARCBank.Msgs.ATMCreator.Butt = "Button #%NUM%"
ARCBank.Msgs.ATMCreator.MonHit = "Money Hit Box"
ARCBank.Msgs.ATMCreator.MonL = "Money Length"
ARCBank.Msgs.ATMCreator.MonW = "Money Width"
ARCBank.Msgs.ATMCreator.MonH = "Money Height"
ARCBank.Msgs.ATMCreator.ATMPre = "ATM Preview"
ARCBank.Msgs.ATMCreator.ButtonAim = "Place the button where you're aiming"
ARCBank.Msgs.ATMCreator.ScreenRef = "Screen Reference"
ARCBank.Msgs.ATMCreator.ATMButtons = "ATM Buttons"
ARCBank.Msgs.ATMCreator.SkinSwitch = "Skin to switch to:"
ARCBank.Msgs.ATMCreator.ModelSwitch = "Change model to:"
ARCBank.Msgs.ATMCreator.AnimName = "Animation Name:"
ARCBank.Msgs.ATMCreator.AnimLen = "Animation Length:"
ARCBank.Msgs.ATMCreator.UseModel = "Use model (Disables the options below)"
ARCBank.Msgs.ATMCreator.MoneyModel = "Money Model:"
ARCBank.Msgs.ATMCreator.CardModel = "Card Model:"
ARCBank.Msgs.ATMCreator.DepostStartSound = "Play Deposit Starting Sound (Click to here to change sound)"
ARCBank.Msgs.ATMCreator.PauseSeconds = "Pause for the following amount of seconds:"
ARCBank.Msgs.ATMCreator.PauseSecondsShort = "Pause (seconds):"
ARCBank.Msgs.ATMCreator.ATMOpenAnim = "ATM Open Animation (Click to here to change animation)"
ARCBank.Msgs.ATMCreator.DepositSoundLoop = "Play waiting for deposit sound loop (Click here to change sound)"
ARCBank.Msgs.ATMCreator.IfDepostFail = "***If the deposit fails***"
ARCBank.Msgs.ATMCreator.IfDepostSucceeds = "***If the deposit succeeds***"
ARCBank.Msgs.ATMCreator.DepositFailedSound = "Play deposit failed sound"
ARCBank.Msgs.ATMCreator.DepositSound = "Play deposit sound"
ARCBank.Msgs.ATMCreator.DepostAnimaion = "Deposit animation"
ARCBank.Msgs.ATMCreator.CloseAnimation = "ATM Close Animation (Click to here to change animation)"
ARCBank.Msgs.ATMCreator.DepositFailQuestion = "Should the deposit fail?"
ARCBank.Msgs.ATMCreator.WithdrawStartSound = "Play Withdraw Starting Sound (Click to here to change sound)"
ARCBank.Msgs.ATMCreator.WithdrawAnimation = "Withdraw animation (Click to here to change animation)"
ARCBank.Msgs.ATMCreator.WaitUser = "***Wait until user takes out the cash***"
ARCBank.Msgs.ATMCreator.AnimTest = "Test Animation"
ARCBank.Msgs.ATMCreator.EditCardInAnim = "Edit card insert animation"
ARCBank.Msgs.ATMCreator.EditCardInSound = "Edit card insert sound"
ARCBank.Msgs.ATMCreator.EditCardOutAnim = "Edit card remove animation"
ARCBank.Msgs.ATMCreator.EditCardOutSound = "Edit card remove sound"
ARCBank.Msgs.ATMCreator.ATMCloseSound = "ATM close sound"
ARCBank.Msgs.ATMCreator.BtnPrsClnt = "Button press sound (client side)"
ARCBank.Msgs.ATMCreator.BtnPrsServ = "Button press sound (server side)"
ARCBank.Msgs.ATMCreator.BeepSound = "Request money sound"
ARCBank.Msgs.ATMCreator.ErrSound = "Error sound"
ARCBank.Msgs.ATMCreator.BeepNoSound = "Invalid selection sound"
ARCBank.Msgs.ATMCreator.ScreenPlacement = "Screen Placement"
ARCBank.Msgs.ATMCreator.ScreenDisplay = "Screen Display"
ARCBank.Msgs.ATMCreator.ButtonsPlacement = "Buttons Placement"
ARCBank.Msgs.ATMCreator.DepositAnim = "Deposit animation"
ARCBank.Msgs.ATMCreator.WithdrawAnim = "Withdraw animation"
ARCBank.Msgs.ATMCreator.MoneyLight = "Money light"
ARCBank.Msgs.ATMCreator.CardAnim = "Card animation"
ARCBank.Msgs.ATMCreator.CardLight = "Card light"
ARCBank.Msgs.ATMCreator.SoundsOther = "Other Sounds"


ARCBank.Msgs.CommandOutput.SysReset = "System reset required!"
ARCBank.Msgs.CommandOutput.SysSetting = "%SETTING% has been changed to %VALUE%"
ARCBank.Msgs.CommandOutput.admin = "You must be an admin to use this command!"
ARCBank.Msgs.CommandOutput.superadmin = "You must be an superadmin to use this command!"
ARCBank.Msgs.CommandOutput.SettingsSaved = "Settings have been saved!"
ARCBank.Msgs.CommandOutput.SettingsError = "Error saving settings."
ARCBank.Msgs.CommandOutput.ATMSaved = "ATMs saved onto map!"
ARCBank.Msgs.CommandOutput.ATMError = "An error occurred while saving the ATMs onto the map."
ARCBank.Msgs.CommandOutput.ATMDSaved = "ATMs detached from map!"
ARCBank.Msgs.CommandOutput.ATMDError = "An error occurred while detaching ATMs from map."
ARCBank.Msgs.CommandOutput.ATMRespawn = "ATMs re-spawned!"
ARCBank.Msgs.CommandOutput.ATMRError = "No ATMs associated with this map. (Non-existent/Currupt file)"
ARCBank.Msgs.CommandOutput.ResetYes = "System reset!"
ARCBank.Msgs.CommandOutput.ResetNo = "Error. Check server console for details. Or look at the latest system log located in garrysmod/data/_arcbank on the server."
ARCBank.Msgs.CommandOutput.MySQL1 = "A MySQL Error occured. Tell your server owner to check the logs."
ARCBank.Msgs.CommandOutput.MySQL2 = "The logs can be found in garrysmod/data/_arcbank on the server."
ARCBank.Msgs.CommandOutput.MySQL3 = "ARCBank will re-activate in 10 seconds."
ARCBank.Msgs.CommandOutput.MySQL4 = "ARCBank failed to restart. Contact your server owner."
ARCBank.Msgs.CommandOutput.MySQLCopy = "Copying all accounts to MySQL database. This might take a while..."
ARCBank.Msgs.CommandOutput.MySQLCopyFrom = "Copying all accounts from MySQL database. The server might freeze for a bit."

ARCBank.Msgs.ATMMsgs.NetworkErrorTitle = "ARCBank - Server Error"
ARCBank.Msgs.ATMMsgs.NetworkError = "The ARCBank System isn't running or isn't set up properly. Contact the server owner."
ARCBank.Msgs.ATMMsgs.HackingError = "I'm out-of-service :(\nINVALID_MEMORY_OPERATION\nPlease visit a different terminal."

ARCBank.Msgs.Items.Hacker = "ATM Hacking Unit"
ARCBank.Msgs.Items.Card = "Keycard"
ARCBank.Msgs.Items.PinMachine = "Card Machine"

ARCBank.Msgs.ATMMsgs.Welcome = "Welcome"
ARCBank.Msgs.ATMMsgs.Loading = "Loading..."
ARCBank.Msgs.ATMMsgs.Waiting = "Waiting..."
ARCBank.Msgs.ATMMsgs.LoadingMsg = "Please Wait..."
ARCBank.Msgs.ATMMsgs.TakeCash = "Please take your cash."
ARCBank.Msgs.ATMMsgs.GiveCash = "Please insert your cash."
ARCBank.Msgs.ATMMsgs.Yes = "Yes"
ARCBank.Msgs.ATMMsgs.No = "No"
ARCBank.Msgs.ATMMsgs.OK = "OK"
ARCBank.Msgs.ATMMsgs.Cancel = "Cancel"
ARCBank.Msgs.ATMMsgs.Close = "Close"
ARCBank.Msgs.ATMMsgs.Abort = "Abort"
ARCBank.Msgs.ATMMsgs.Retry = "Retry"
ARCBank.Msgs.ATMMsgs.Ignore = "Ignore"

ARCBank.Msgs.ATMMsgs.Keypad = "Enter using the keypad:"
ARCBank.Msgs.ATMMsgs.Enter = "Press \"ENTER\" to Continue"
ARCBank.Msgs.ATMMsgs.File = "Text File - Page %PAGE%"
ARCBank.Msgs.ATMMsgs.FileNext = "Next Page"
ARCBank.Msgs.ATMMsgs.FilePrev = "Previous Page"
ARCBank.Msgs.ATMMsgs.FileClose = "Press \"CANCEL\" to Close"
ARCBank.Msgs.ATMMsgs.PersonalInformation = "Personal Account Information"
ARCBank.Msgs.ATMMsgs.PersonalUpgrade = "Upgrade/Create Personal Account"
ARCBank.Msgs.ATMMsgs.GroupInformation = "Group Account Information"
ARCBank.Msgs.ATMMsgs.GroupUpgrade = "Upgrade/Create Group Account"
ARCBank.Msgs.ATMMsgs.Fullscreen = "Toggle Full-screen Mode"
ARCBank.Msgs.ATMMsgs.DarkMode = "Toggle Dark Mode"
ARCBank.Msgs.ATMMsgs.Exit = "Exit"
ARCBank.Msgs.ATMMsgs.Back = "Back"
ARCBank.Msgs.ATMMsgs.More = "More"
ARCBank.Msgs.ATMMsgs.Deposit = "Cash Deposit"
ARCBank.Msgs.ATMMsgs.Withdrawal = "Cash Withdrawal"
ARCBank.Msgs.ATMMsgs.Transfer = "Transfer Funds"
ARCBank.Msgs.ATMMsgs.ViewLog = "View Log"
ARCBank.Msgs.ATMMsgs.OtherNumber = "Other Amount"
ARCBank.Msgs.ATMMsgs.MainMenu = "Welcome, %PLAYERNAME%. How may I help you?"
ARCBank.Msgs.ATMMsgs.Balance = "Balance: "
ARCBank.Msgs.ATMMsgs.MaximumCash = "A wasted life"
ARCBank.Msgs.ATMMsgs.ChooseAccount = "Please choose an account"
ARCBank.Msgs.ATMMsgs.ChoosePlayer = "Please choose a player"

ARCBank.Msgs.ATMMsgs.SIDAsk = "Does the Steam ID start with STEAM_0:1?"
ARCBank.Msgs.ATMMsgs.GiveMoneyAccount = "Choose the account to give the money to."
ARCBank.Msgs.ATMMsgs.PlayerTooFar = "You're too far away from the ATM."
ARCBank.Msgs.ATMMsgs.NumberTooHigh = "You can't use a number higher than %NUM%!"
ARCBank.Msgs.ATMMsgs.CloseAccount = "Close Account"
ARCBank.Msgs.ATMMsgs.AddPlayerGroup = "Add Player to group"
ARCBank.Msgs.ATMMsgs.RemovePlayerGroup = "Remove Player from group"
ARCBank.Msgs.ATMMsgs.CloseNotice = "You're about to close this account. All money in here will be considered as a \"donation\" to ARCBank.\nAre you sure?"
ARCBank.Msgs.ATMMsgs.NoLog = "Log file not found!"

ARCBank.Msgs.ATMMsgs.OpenAccount = "Would you like to open a personal account?"
ARCBank.Msgs.ATMMsgs.UpgradeAccount = "Are you sure you want to upgrade this account?" 

ARCBank.Msgs.ATMMsgs.CreateGroupAccount = "*Create Group Account"
ARCBank.Msgs.ATMMsgs.PersonalAccount = "*Personal Account             "
ARCBank.Msgs.ATMMsgs.OfflinePlayer = "Offline Player"
ARCBank.Msgs.CardMsgs.NoOwner = "No owner is set!"
ARCBank.Msgs.CardMsgs.Owner = "This is owned by %PLAYER%"
ARCBank.Msgs.CardMsgs.InvalidOwner = "You don't own this device!"
ARCBank.Msgs.CardMsgs.NoCard = "This device isn't requesting a card!"
ARCBank.Msgs.CardMsgs.InsertCard = "Customer, please insert your card."
ARCBank.Msgs.CardMsgs.Account = "Which account do you want to use?" 
ARCBank.Msgs.CardMsgs.AccountPay = "Which account do you want to pay with?"
ARCBank.Msgs.CardMsgs.Label = "What's the label of this transaction?"
ARCBank.Msgs.CardMsgs.Charge = "How much do you want to charge?"
ARCBank.Msgs.CardMsgs.NoAccount = "You don't have a personal bank account!"

ARCBank.Msgs.Hack.StealthMode = "Stealth Mode"
ARCBank.Msgs.Hack.Descript = "Hacks multiple accounts and withdraws smaller values from each account. Also makes it harder for cops to detect."
ARCBank.Msgs.Hack.Power = "Hacking Power: "
ARCBank.Msgs.Hack.Chance = "Chance of success: "
ARCBank.Msgs.Hack.NoEnergy = "Not enough Energy"
ARCBank.Msgs.Hack.GoodEnergy = "Optimal Energy"
ARCBank.Msgs.Hack.Money = "Total Amount of money to steal:"
ARCBank.Msgs.Hack.ETA = "Estimated Hack Time: "
ARCBank.Msgs.Hack.GiveOrTake = "Give or Take: "

ARCBank.Msgs.Time.nd = "and"
ARCBank.Msgs.Time.second = "second"
ARCBank.Msgs.Time.seconds = "seconds"
ARCBank.Msgs.Time.minute = "minute"
ARCBank.Msgs.Time.minutes = "minutes"
ARCBank.Msgs.Time.hour = "hour"
ARCBank.Msgs.Time.hours = "hours"
ARCBank.Msgs.Time.day = "day"
ARCBank.Msgs.Time.days = "days"
ARCBank.Msgs.Time.forever = "forever"
ARCBank.Msgs.Time.now = "now"

ARCBank.Msgs.UserMsgs.Hack = "An ATM is being hacked!"
ARCBank.Msgs.UserMsgs.HackNoCops = "There aren't enough law enforcers."
ARCBank.Msgs.UserMsgs.HackNoPlayers = "There aren't people."
ARCBank.Msgs.UserMsgs.Paycheck = "Your paycheck has been sent to your ARCBank account."
ARCBank.Msgs.UserMsgs.PaycheckFail = "There was an error while sending your paycheck to your ARCBank account."

ARCBank.Msgs.UserMsgs.Eatcard1 = "Hello! It seems that your card was eaten by an ATM last time you were on this server."
ARCBank.Msgs.UserMsgs.Eatcard2 = "Here's your card back! Have a good day!"
ARCBank.Msgs.UserMsgs.AtmUse = "Please exit the ATM before doing this."
ARCBank.Msgs.UserMsgs.ATMUsed = "The ATM is already being used by %PLAYER%!"
ARCBank.Msgs.UserMsgs.HackHero = "%HERO% just stopped %IDIOT% from hacking into an ATM and stealing your money! %HERO% is a hero!"
ARCBank.Msgs.UserMsgs.HackIdiot = "OH NO! I AM A NOOB HACKER! %HERO% IS SO MUCH BETTER THAN ME!"
ARCBank.Msgs.UserMsgs.CardNo = "The thing you're looking at doesn't have an ATM slot"
ARCBank.Msgs.UserMsgs.CardAir = "The air doesn't have an ATM slot"
ARCBank.Msgs.UserMsgs.DepositATM = "Use the mouth of the ATM to deposit money. (Press E)"
ARCBank.Msgs.UserMsgs.WithdrawATM = "Use the money to pick it up. (Press E)"

ARCBank.Msgs.AdminMenu.SearchBalance = "Search by Balance"
ARCBank.Msgs.AdminMenu.Bigger = "Greater than"
ARCBank.Msgs.AdminMenu.Same = "Equal to"
ARCBank.Msgs.AdminMenu.Smaller = "Less than"
ARCBank.Msgs.AdminMenu.Accounts = "Bank Accounts"
ARCBank.Msgs.AdminMenu.SearchRank = "Search by Rank"
ARCBank.Msgs.AdminMenu.Settings = "System Settings"
ARCBank.Msgs.AdminMenu.Commands = "Commands"
ARCBank.Msgs.AdminMenu.Owner = "Owner: "
ARCBank.Msgs.AdminMenu.SearchSID = "Search by Steam ID"
ARCBank.Msgs.AdminMenu.ChooseSetting = "Choose a setting"
ARCBank.Msgs.AdminMenu.Name = "Name: "
ARCBank.Msgs.AdminMenu.SearchName = "Search by Name"
ARCBank.Msgs.AdminMenu.Members = "Group Members"
ARCBank.Msgs.AdminMenu.Refresh = "Refresh Data"
ARCBank.Msgs.AdminMenu.GiveTakeMoney = "Give/Take Money"
ARCBank.Msgs.AdminMenu.AccID = "Account ID: "
ARCBank.Msgs.AdminMenu.Results = "%NUM% Results"
ARCBank.Msgs.AdminMenu.Rank = "Rank: "
ARCBank.Msgs.AdminMenu.NoLog = "Click here to select a log"
ARCBank.Msgs.AdminMenu.ServerLogs = "Server Logs"
ARCBank.Msgs.AdminMenu.SaveSettings = "Save settings"
ARCBank.Msgs.AdminMenu.Remove = "Remove"
ARCBank.Msgs.AdminMenu.Add = "Add"
ARCBank.Msgs.AdminMenu.Description = "Description:"
ARCBank.Msgs.AdminMenu.Enable = "Enable"

ARCBank.Msgs.AccountRank[0] = "Personal"
ARCBank.Msgs.AccountRank[1] = "Personal - Basic"
ARCBank.Msgs.AccountRank[2] = "Personal - Bronze"
ARCBank.Msgs.AccountRank[3] = "Personal - Silver"
ARCBank.Msgs.AccountRank[4] = "Personal - Gold"
ARCBank.Msgs.AccountRank[5] = "Group"
ARCBank.Msgs.AccountRank[6] = "Group - Standard"
ARCBank.Msgs.AccountRank[7] = "Group - Premium"
ARCBank.Msgs.Commands["atm_save"] = "Save and freeze all ATMs"
ARCBank.Msgs.Commands["atm_unsave"] = "Unsave and unfreeze all ATMs"
ARCBank.Msgs.Commands["atm_respawn"] = "Respawn frozen ATMs"
ARCBank.Msgs.Commands["atm_spawn"] = "Spawn an ATM where you're looking"



ARCBank.SettingsDesc["name"] = "The displayed \"short\" name of the addon."
ARCBank.SettingsDesc["name_long"] = "The displayed \"long\" name of the addon."
ARCBank.SettingsDesc["card_texture"] = "The texture of the ATM card"
ARCBank.SettingsDesc["atm_hack_time_rate"] = "The hack time rate for hacking devices. The higher number, the faster the hack will take."
ARCBank.SettingsDesc["atm_hack_charge_rate"] = "The recharge rate for hacking devices. The higher number, the faster it will take to recharge."
ARCBank.SettingsDesc["atm_hack_notify"] = "The players on these teams will be notified when an ATM is being hacked. These people are considered cops."
ARCBank.SettingsDesc["atm_hack_min_player"] = "An ATM hack will not be possible unless there are at lest these many players."
ARCBank.SettingsDesc["atm_hack_min_hackerstoppers"] = "An ATM hack will not be possible unless there are these many cops (see atm_hack_notify setting)"
ARCBank.SettingsDesc["atm_hack_radar"] = "Cops will have an icon on their screen showing the location of active hacking devices. (If they aren't using distributed attack mode)"

ARCBank.SettingsDesc["atm_hack_allowed"] = "Players on these teams will be able to use a hacking device."
ARCBank.SettingsDesc["atm_hack_allowed_use"] = "Enable/Disable the atm_hack_allowed setting"

ARCBank.SettingsDesc["language"] = "Which language file to use. (without .txt) they are located in data/_arcbank/languages. Defaults: en fr ger pt_br sp nl ru"
ARCBank.SettingsDesc["use_bank_for_payday"] = "Payday checks will be sent to your Bank account."
ARCBank.SettingsDesc["atm_holo"] = "Floating sign above the ATM"

ARCBank.SettingsDesc["atm_holo_flicker"] = "Should the ATM sign flicker?"
ARCBank.SettingsDesc["atm_holo_rotate"] = "Should the ATM sign rotate?"
ARCBank.SettingsDesc["atm_holo_text"] = "The text on the ATM sign"
ARCBank.SettingsDesc["group_account_limit"] = "A player can only create this many group accounts"
ARCBank.SettingsDesc["starting_cash"] = "Players will start with this amount of money when they open a bank account."
ARCBank.SettingsDesc["perpetual_debt"] = "If a player is in debt, they will gain more debt at their interest rate."
ARCBank.SettingsDesc["autoban_time"] = "A 1337 xXNOSCOPZXx h4x0r will be banned for this many minutes for even thinking of using exploits."
ARCBank.SettingsDesc["debt_limit"] = "How much below 0 an account can get"

ARCBank.SettingsDesc["interest_time"] = "The interval time of the giving of interest. (hours)"

ARCBank.SettingsDesc["hack_max"] = "The maximum amount a player can hack the ATM with an ATM hacker"
ARCBank.SettingsDesc["hack_minimum"] = "The minimum amount a player can hack the ATM with an ATM hacker"

ARCBank.SettingsDesc["interest_enable"] = "The bank will give players interest."

ARCBank.SettingsDesc["standard_interest"] = "The % of interest a standard account will gain when the next 'interest time' comes."
ARCBank.SettingsDesc["bronze_interest"] = "The % of interest a bronze account will gain when the next 'interest time' comes."
ARCBank.SettingsDesc["silver_interest"] = "The % of interest a silver account will gain when the next 'interest time' comes."
ARCBank.SettingsDesc["gold_interest"] = "The % of interest a gold account will gain when the next 'interest time' comes."
ARCBank.SettingsDesc["group_standard_interest"] = "The % of interest a standard group account will gain when the next 'interest time' comes."
ARCBank.SettingsDesc["group_premium_interest"] = "The % of interest a premium group account will gain when the next 'interest time' comes."

ARCBank.SettingsDesc["standard_requirement"] = "The in-game rank(s) the player must be to create a standard account. "
ARCBank.SettingsDesc["bronze_requirement"] = "The in-game rank(s) the player must be to create a bronze account."
ARCBank.SettingsDesc["silver_requirement"] = "The in-game rank(s) the player must be to create a silver account."
ARCBank.SettingsDesc["gold_requirement"] = "The in-game rank(s) the player must be to create a gold account."
ARCBank.SettingsDesc["group_standard_requirement"] = "The in-game rank(s) the player must be to create a group account."
ARCBank.SettingsDesc["group_premium_requirement"] = "The in-game rank(s) the player must be to create a premium group account."
ARCBank.SettingsDesc["everything_requirement"] = "People of these ranks can create any account. THESE SHOULD BE GIVEN OUT TO OWNERS OR SUPERADMINS!"

ARCBank.SettingsDesc["notify_update"] = "Disable this. It's useless now"
ARCBank.SettingsDesc["superadmin_only"] = "Only superadmins can use admin commands"
ARCBank.SettingsDesc["owner_only"] = "Only someone with the \"owner\" usergroup can use admin commands (WARNING! IF YOU DON'T HAVE AN OWNER RANK, DO NOT ENABLE THIS SETTING)"
ARCBank.SettingsDesc["atm_darkmode_default"] = "Dark Mode will be enabled on the ATM by default."

ARCBank.SettingsDesc["card_weapon_slot"] = "weapon_arc_atmcard.Slot"
ARCBank.SettingsDesc["card_weapon_slotpos"] = "weapon_arc_atmcard.SlotPos"
