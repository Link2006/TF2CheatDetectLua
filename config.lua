--DO NOT TOUCH AT THIS 
local Config = Config or {} 

--Configuration settings goes here.
Config.ConfigVersion = "1.1" --THIS VERSION MUST MATCH THE SCRIPT VERSION, This will warn you otherwise.

Config.debugMode = false  --Debug Mode: Disables Votekicks and prints debug messages
Config.allChat = false --Prints chat messages 
Config.SpamMax = 10  --Only print once every X lines
Config.CheaterLogEnabled = true 
Config.SuspPrint = true --Prints suspicious non-chat lines  (Kills, Connections, etc...)
Config.CheaterPrint = false --Set to true to print bot talk (Please keep this off)
Config.TimeStamp = true -- This allows you to enable/disable the timestamp in console.

Config.ChatMessageEnabled = true -- Toggles if we say the message, advertising this script isn't useful anymore.
Config.ChatMessage = "[Bind] Cheat Detector (github.com/Link2006/TF2CheatDetectLua)" --What you want said when pressing the bind;

Config.WarnPlayers = true 
Config.WarnPlayerMsg = "[Bind] {BotCount} bots, Kicking \"{BotName}\" | {BotID} - {BotSteam}..." --replace botname with "ANTI BOT BOT", replace creason with "Banned steamID"

Config.NoBotChat = true 
Config.NoBotMsg = "[Bind] No bots were detected, thank you for your time"

Config.fps_max = 180 --Issues with the script running too fast/too slow? Tweak this !
--NOTES: ABOUT FPS_MAX!
--This variable here should be set to what's your average *highest* FPS (vsync or not) 
--It is used to calculate your wait commands which are relying on a (somewhat) stable frame-rate.
--Example: You usually hit 180 fps, you would set this to 180 (which should make "wait 180" delay stuff by 1 second.

--BlackList/Whitelist support
--Anyone with a matching name (without invisible characters/namesteal bytes) will get kicked 
--Unless their steamIDs is in the whitelist. 

Config.EnableBlackList = true --This will kick anyone that has a name that matches a word in BlackListedNames

Config.NetworkEnabled = false --Enable this to enable auto-updates of certain /data/ files. UNTESTED (NOT WORKING ON WINDOWS?)

--Table of network lists to download, sorry this isn't as intuitive as the rest of the configs.
--To disable them, simply remove the line or comment it out.
-----!!! NOTICE !!!-----
--This must *ONLY* Include SteamID blacklists for now, Rules/Names MUST be updated MANUALLY.
-----!!! NOTICE !!!-----

--FORMAT: 
--"filename" = "update url" -- Setting things to nil will make them load but not update
Config.NetworkLists = {} 
--wgetJane's Big list of bots
Config.NetworkLists["BlackListSteamID.bot_list.txt"] = "https://gist.githubusercontent.com/wgetJane/0bc01bd46d7695362253c5a2fa49f2e9/raw/"
--Milenko's Github is currently offline, 
Config.NetworkLists["BlackListSteamID.milenko.txt"] = "https://raw.githubusercontent.com/incontestableness/milenko/blob/master/catlist.nsv.64" --Is this valid?
--Add your own lists here, 
--FORMAT: Config.NetworkLists[File Name] = Url
-- The url can be set to "nil" to disable attempting auto-updates (will crash if given an invalid URL otherwise)
Config.NetworkLists["BlackListSteamID.custom.txt"] = "nil" --Change this to a real URL to automaticly update 

-----DO NOT TOUCH AT THIS LINE EITHER------
return Config 