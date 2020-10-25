--LuaBinaries license: http://luabinaries.sourceforge.net/license.html 

--TODO: Find a way to optionally use socket to update bot_list, if not found then don't bother updating.
--			  If we do find socket, ask if we want to update (on launch only), also store at the top of the file //update time; to print that line when we save it as so to print when asking for update
--			  "Last updated: <date>", do you want to update? [Y/N]


-----------DO NOT TOUCH THIS FILE-----------
-----------DO NOT TOUCH THIS FILE-----------
-----------DO NOT TOUCH THIS FILE-----------
-----------DO NOT TOUCH THIS FILE-----------
-- I've changed how the configs are stored, they are now in a file config.lua, a default file is available on the github 
-- Whenever i'll update the scriipt version, this may cause conflicts if the config has not been bumped up
-----------DO NOT TOUCH THIS FILE-----------
-----------DO NOT TOUCH THIS FILE-----------
-----------DO NOT TOUCH THIS FILE-----------
-----------DO NOT TOUCH THIS FILE-----------


--TODO: Make this **default to disabled**
--Let's see if we have the socket library to download updates live for the /data/ folder...
local sockethttp = nil --For now? 
local socketerr = nil --Not useful unless there's an error 
local function loadsocket()
	sockethttp,socketerr = require('socket.http') --assign
	return sockethttp,socketerr -- if any error
end 
--end of function to check for luasockets

-- This script should only print warnings and status lines
-- Anything that seems to be a chat message followed by empty lines will be considered a cheater/bot.


--CONSTANTS: 
local knownCheatWords = {} --Patterns that holds text to see as suspicious 
local WhiteListSteamIDs = {} --SteamIDs We skip over, includes mine, raspy and a few others with false positive from my script as of testing
local BlackListedNames = {} --Names of bots that we should automaticly kick no matter what 
local BlacklistSteamIDs = {} --SteamIDs of bots that we should kick no matter what (!)
local DBLastUpdate = 0 --filled later by os.time()

local ScriptVersion = "1.1"

--CONFIG LOADING CODE GOES HERE...
print(string.format("Cheater Detector %s\n\n",ScriptVersion))--Space this out 
print("Please bind a key to \"exec lua_nocheat\" to activate the script\n\n")

print("Loading user settings from config.lua...")
if loadfile then 
	local ConfFunc, Err = loadfile("config.lua")
	if not ConfFunc then 
		print("Failed to load config: ",Err)
		error("Restarting...")
	end 
	local Config = ConfFunc() 
	ConfFunc = nil --delete the function
	for k,v in pairs(Config) do 
		_G[k] = v
	end
	Config=nil 
else 
	print("\n\n!!!FATAL ERROR!!!\n\nloadfile function not found, please contact Link2006 with this information:")
	print("_VERSION:",_VERSION)
	print("loadfile:",loadfile)
	print("load:",load)
	print("loadstring:",loadstring)
	print("Press enter to crash out.")
	io.read()
	error("Failed to execute usersettings")
end 
if NetworkEnabled then
	print("Network Enabled, Loading LuaSocket...")
	if not pcall(loadsocket) then 
		print("Unable to find luasocket library, using cached version instead...")
		local _,sErr = pcall(loadsocket)
		if string.find(sErr,"%%1") and string.find(sErr,"Win32") then --Assume it's a win32 error
			print(sErr,"\nEither the lua interpreter or library is not 32-bit,\nPlease use both files as 32-bit.")
		end 
		print() -- >:( ...
	else 
		print("Downloading updates...")
		for BLpath,BLurl  in pairs(NetworkLists) do 
			if BLurl and BLurl ~= "nil" then --String of nil because issues?
				local response,code,headers = sockethttp.request(BLurl)
				if code ~= 200 then --FAILED???
					print("Download failed:",code)
				else 
					local fh = io.open("data/"..BLpath,"w")
					fh:write(response) --:) 
					fh:close() 
				end 
			end 
		end 
	end 
else
	print("Network updater disabled, Using cached versions.")
	print("to enable it please set NetworkEnabled to true")
end 
print("Config Loaded.\n")

--VARIABLES: 
local BotSteam = nil --stores botid, botname is dangerous to store :| 
local BotName = nil --Am i supposed to even do this? is this bad?

local Cheaters = {} 
local prevUser = ""
local prevConLine = ""
local prevCheaterLine = "" 
local NewLineFound = false 
local SpamCount = SpamMax --Increment this every newline, will print the first newline.
local KickCheater = nil
--TODO: Implementation

local KickTable = {} -- TODO: Implement a way to parse if there's more than 1 bot!
--TODO: Make this actually hold more information within KickCheater (maybe {plyname,userid,waitforconnect}?)
local KickWaitName = nil --Holds names of players to wait for, nil if not waiting.

local function TimedPrint(str, ...)
	if TimeStamp then 
		return print("["..os.date("%H:%M:%S",os.time()).."] "..tostring(str),...)  --This is awful but it works :)
	else 
		return print(str,...)
	end 
end 

local function IsWhitelisted(steamid)
	for k,WLSteamID in pairs(WhiteListSteamIDs) do 
		if WLSteamID == steamid then 
			return true 
		end 
	end 
	return false 
end 

local function WaitSec(seconds)
	return math.ceil(fps_max * seconds) -- Returns a number of frames to wait from the seconds input (rounded up due to source wait commands requiring integers)
end 
local function SteamID64toSteam3(steamid)
	if not tonumber(steamid)  then return false,"Invalid SteamID" end --Invalid SteamID or it's a comment
	steamid = tonumber(steamid) --Please don't let Lua use strings directly, it uses floats otherwise :( 
	return ("[U:1:%d]"):format(steamid - 0x110000100000000) --Thanks wget for a faster conversion process
end 
local function Steam3toSteamID64(steamid)
	if not steamid:match("(%[U:1:%d+%])")  then return false,"Invalid SteamID" end --Invalid SteamID or it's a comment
	return tostring(tonumber(steamid:match("%[U:1:(%d+)%]")) + 0x110000100000000) --I have to convert to number before performing the math here, it seems to return 7.656...e+016 instead if i don't; floats suck
	--return ("[U:1:%d]"):format(steamid - 0x110000100000000) --Thanks wget for a faster conversion process
end 

local function UpdateTables() --Okay this is just stupid 
	
	local osclocktest = os.clock() 
	if DBLastUpdate + (5*60) > os.time() then 
		return --It hasn't been 5 minutes yet, do not update...
	else 
		TimedPrint("Loading Tables...")
		DBLastUpdate = os.time() 
	end 
	
	if not io.open("data/KnownCheatWords.txt") or not io.open("data/WhiteListedSteamIDs.txt")  or not io.open("data/BlackListedNames.txt") or not io.open("data/BlackListSteamID.bot_list.txt") or not io.open("data/BlackListSteamID.custom.txt") then 
		TimedPrint("Missing data folder/files, Please make sure the folder exists and the following files are in the folder:")
		TimedPrint("","data/KnownCheatWords.txt")
		TimedPrint("","data/WhiteListedSteamIDs.txt")  
		TimedPrint("","data/BlackListedNames.txt") 
		TimedPrint("","data/BlackListSteamID.bot_list.txt") 
		TimedPrint("","data/BlackListSteamID.custom.txt") 
		error("FAILED TO LOAD DATA FILES")
	end 
	
	--Clear the Tables
	knownCheatWords = {} 
	WhiteListSteamIDs = {} 
	BlackListedNames = {} 
	BlacklistSteamIDs = {} 
	--Reload everything 
	for line in io.lines("data/KnownCheatWords.txt") do 
		table.insert(knownCheatWords,line)
	end 
	for line in io.lines("data/WhiteListedSteamIDs.txt") do 
		if Steam3toSteamID64(line) then --I just want to add comments to Whitelisted please ok thx
			table.insert(WhiteListSteamIDs,line) --TODO: SteamID64 support here too! 
		end 
	end 
	for line in io.lines("data/BlackListedNames.txt") do 
		SteamID64toSteam3()
		table.insert(BlackListedNames,line) 
	end
	for filename,_ in pairs(NetworkLists) do
		print("Loading list: data/"..filename)
		--for line in io.lines("data/BlackListSteamID.bot_list.txt") do 
		--	if SteamID64toSteam3(line) then 
		--		table.insert(BlacklistSteamIDs,SteamID64toSteam3(line))
		--	end 
		--end 
		if io.open("data/"..filename,"r") then --The file exists 
			local HasDupes = false 
			local line_num_custom = 0
			for line in io.lines("data/"..filename) do --"data/BlackListSteamID.custom.txt" | TODO: Ignore if the file doesn't exists? Should exist 
				line_num_custom = line_num_custom + 1
				--PLEASE DONT HAVE DUPES >:(
				if SteamID64toSteam3(line) then 
					local steamid = SteamID64toSteam3(line) 
					local IsDupe = false 
					for k,blsteamid in pairs(BlacklistSteamIDs) do 
						if steamid == blsteamid then 
							--TODO: Remove warning of dupes and simply ignore? 
							--TimedPrint(string.format("WARN: Duplicate SteamID %s found at line %d in %s",line,line_num_custom,"data/"..filename))
							IsDupe = true 
							if not HasDupes then 
								HasDupes = true 
								TimedPrint(string.format("WARN: Duplicate SteamIDs found in %s","data/"..filename))
							end 
							break 
						end 
					end 
					if not IsDupe then 
						table.insert(BlacklistSteamIDs,SteamID64toSteam3(line))
					end 
				elseif line:match("(%[U:1:%d+%])") then 
					local IsDupe = false 
					for k,blsteamid in pairs(BlacklistSteamIDs) do 
						if line == blsteamid then 
							--TimedPrint(string.format("WARN: Duplicate SteamID %s found at line %d in %s",line,line_num_custom,"data"..filename))
							IsDupe = true 
							if not HasDupes then 
								HasDupes = true 
								TimedPrint(string.format("WARN: Duplicate SteamIDs found in %s","data/"..filename))
							end 
							break 
						end 
					end 
					if not IsDupe then 
						table.insert(BlacklistSteamIDs,line)
					end 
				end 
			end
		else 
			print("WARN: File not found:","data/"..filename) --Failed to find the file.
		end 
	end 
	line_num_custom = nil 
	--Call GC to make sure everything is fine! This should also clean up everything else every 5 minutes for sure :)
	if debugMode then 
		TimedPrint(string.format("Update completed: Took %s KnownCheatWords: %d WhiteListedSteamIDs:%d BlacklistNames:%d bot_list:%d",os.clock() - osclocktest,#knownCheatWords,#WhiteListSteamIDs,#BlackListedNames,#BlacklistSteamIDs))
	else 
		TimedPrint(string.format("Updated %d entries in all tables",#knownCheatWords+#WhiteListSteamIDs+#BlackListedNames+#BlacklistSteamIDs)) --Might just remove everything if outside debug mode
	end 
	
	--[[--
	if debugMode then 
		for k,v in pairs(BlacklistSteamIDs) do 
			print(k,v)
		end 
		for k,v in pairs(BlackListedNames) do 
			print(k,v)
		end 
		for k,v in pairs(WhiteListSteamIDs) do 
			print(k,v)
		end 
		for k,v in pairs(knownCheatWords) do 
			print(k,v)
		end 
	end 
	--]]--
	
	osclocktest = nil 
	collectgarbage()
	collectgarbage()
end 

local function AddCheaterToTables(plyname,steamid) 
	if not steamid:match("(%[U:1:%d+%])")  then return false,"Invalid SteamID" end --Invalid SteamID or it's a comment
	for k,blsteamid in pairs(BlacklistSteamIDs) do 
		if steamid == blsteamid then 
			TimedPrint(string.format("WARN: Unexpected duplicate for %s [%s]",steamid,plyname))
			return false,"Already exists." --???
		end 
	end 
	table.insert(BlacklistSteamIDs,steamid) --Add it to the table to ban them too now :)
	local blacklist_fh = io.open("data/BlackListSteamID.custom.txt","a+")
	blacklist_fh:write(string.format("\n//%s\n%s",plyname,steamid))
	blacklist_fh:close()
	TimedPrint(string.format("Added %s to custom list [%s]",steamid,plyname))
end 
--Let's use the actual config to do stuff, no need to create a bind
--TimedPrint(string.format("\tbind pgup \"say [Bind] Cheat Detector %s;wait %d;status;wait %d;exec lua_nocheat\"\n",ScriptVersion,WaitSec(0.5),WaitSec(0.5)))

--My library to grab source engine console output.
local consoleparser = require("consoleparser")
consoleparser.init() --Game select + io.input setup.

if ConfigVersion ~= ScriptVersion then 
	TimedPrint(string.format("!! WARNING !! Config seems out of date, Expected %q but got %q instead.",ScriptVersion,ConfigVersion))
end 

if debugMode then 
	TimedPrint("DEBUG MODE ENABLED, Voting is disabled in this mode.")
end 

--This is used later in RunCommand...
local tf2path = consoleparser.getPath() --This returns the path to the tf2 folder.

--TODO: getCheater(<something>)  (not needed anymore?)
--TODO: Probably make it so it writes the current script version inside the 'say bind'? maybe also say if we detected them or not? 

local BotCount = 0 

local function RunCommand(cmd,step)
		
	--step _LUA_STATUS = when we've done status; 
	--step _LUA_VOTED = when we've done callvote;
	
	local luacfg = io.open(tf2path.."cfg/lua_nocheat.cfg","w")
	if not luacfg then
		TimedPrint("[WARN] Failed to open file!",luacfg)
		return false 
	end 
	--This should just *delete* when we get a nil variable.
	if cmd and step then 
		if step == "_LUA_VOTED" and WarnPlayers then -- I'm lazy so im just adding it here :) 
			local PreparedWarnMsg = string.gsub(WarnPlayerMsg,"{BotCount}",BotCount)
			PreparedWarnMsg = (string.gsub(PreparedWarnMsg,"{BotSteam}",(BotSteam or "[U:0:0]")) or PreparedWarnMsg)
			PreparedWarnMsg = (string.gsub(PreparedWarnMsg,"{BotID}",(KickCheater or "unknown")) or PreparedWarnMsg) 
			--Planned addition, unknown if functional 
			local FixedBotName = (((string.gsub(BotName,"\"","''")  or BotName) or (string.gsub(KickWaitName,"\"","''")  or KickWaitName)) or "unknown")
			PreparedWarnMsg = (string.gsub(PreparedWarnMsg,"{BotName}",FixedBotName) or PreparedWarnMsg)
			--this should work? 
			luacfg:write(string.format("say %s;echo %s;wait %d;%s;exec lua_nocheat",PreparedWarnMsg,step,WaitSec(0.5),cmd)) --run the command *after* we cleared the file!  
			
			BotSteam = nil --i dont need it anymore
			BotName = nil 
			PreparedWarnMsg = nil
		else 
			luacfg:write(string.format("echo %s;wait %d;%s;exec lua_nocheat",step,WaitSec(0.5),cmd)) --run the command *after* we cleared the file!  
		end 
	elseif cmd then --Raw command write
		luacfg:write(cmd) 
	else
		luacfg:write('echo "End of Lua_NoCheat"') --?
	end 
	luacfg:close() 
end 

local function updateCheater(username,steamid) 

	steamid = tostring(steamid) --Just make it a string
	
	--Clean the database, Possible to have nil accounts.
	for k,v in pairs(Cheaters) do 
		if v['name'] == "nil" and v['steamid'] == "nil" then
			TimedPrint(string.format("Removing invalid entry #%d...",k))
			table.remove(Cheaters,k)
		end 
	end 
	
	if steamid ~= "nil" then --if steamid is set...
		for k,chtTbl in pairs(Cheaters) do --Find a cheater where we already have their SteamID...
			if chtTbl['steamid']==steamid then --if it's found...
				Cheaters[k]['name']=username --Update its name 
				Cheaters[k]['updtime']=os.time() --Update time?
				return false --Updated it :)
			end 
		end 
	end 
	
	--If we don't have a steamid *OR* we have one but not one we already know...
	
	for k,chtTbl in pairs(Cheaters) do --Search for all known cheaters 
		if chtTbl['name']==username then --find the one we have their name for ..
			if chtTbl['steamid'] ~= "nil" and steamid ~= "nil" then --If that steamid is *somehow* already valid; 
				--Found what they use at the end of names: https://unicode-table.com/en/200F/ "Right-To-Left Mark"
				--TODO: Find a way to grab the last *UTF8* character and if it matches this one, warn/flag as Namestealer.
				TimedPrint(string.format("WARN: Possible Namestealer!  Cheaters: {name=%q,steamid=%q} ; args: [name=%q,steamid=%q]",chtTbl['name'],chtTbl['steamid'],name,steamid)) --Namestealer? Should never trip as namesteals are adding a 0width character at the end; making it unique still
			end 
			Cheaters[k]['steamid'] = steamid --Update the currently known cheater with their new steamid :)
			Cheaters[k]['updtime']=os.time() --Update time?
			return false --Updated it :)
		end 
	end 
	
	
	--Populate a new cheater.
	local newCheater = {} 
	newCheater['name']=username 
	newCheater['steamid']=steamid
	newCheater['updtime']=os.time() 
	table.insert(Cheaters,newCheater)
	newCheater = nil; 
	return true --End of cheater 
end 

local function isCheater(InpStr) --accepts a cheater name & messages 
	for k,word in pairs(knownCheatWords) do 
		if InpStr:find(word) then 
			return true 
		end 
	end 
	
	for k,chtTbl in pairs(Cheaters) do --Wait is this useful anymore? 
		if chtTbl['name'] == str or chtTbl['steamid'] == str then 
			--Yes it is a cheater, their Name/SteamID is here :)
			return true
		end 
	end 
	return false 
end 
UpdateTables()
TimedPrint("Cleaning TF2 cfg file...")
local function ResetConfig() 
	if ChatMessageEnabled then 
		RunCommand(string.format("say %s;echo _LUA_PREPARE;wait %d;status;wait %d;echo _LUA_STATUS;wait %d;exec lua_nocheat",ChatMessage,WaitSec(1.25),WaitSec(1.25),WaitSec(1.00)))
	else
		RunCommand(string.format("echo _LUA_PREPARE;wait %d;status;wait %d;echo _LUA_STATUS;wait %d;exec lua_nocheat",WaitSec(1.25),WaitSec(1.25),WaitSec(1.00)))
	end 
end 
ResetConfig() 

local LUAWAITCYCLES = 0 

TimedPrint("!!Please use CTRL-C to stop the script, this will allow resetting the config/bind!!\n")

--Main loop
while true do --Never stop 
	local pcallstatus, conline = pcall(consoleparser.getNextLine)
	if not pcallstatus then
		if string.sub(conline,-12) == "interrupted!" then 
			TimedPrint("Exiting...")
		else 
			TimedPrint("Unexpected error: '"..conline.."'") 
		end 
		RunCommand("echo \"Disabled, Please run script!\"")
		break --Stop the loop.
	end
	
	--These 3 string removal should *not* be removed at the start but it works so far, so whatever.
	
	--This should fix "*DEAD*(TEAM)" spammers
	if string.sub(conline,1,13)== "*DEAD*(TEAM) " then 
		conline = string.sub(conline,14)
	end 
	
	--Removes "*DEAD* " from players, assumes they're dead. 
	if string.sub(conline,1,7) == "*DEAD* " then
		conline = string.sub(conline,8)
	end 
	
	--Removes "(TEAM) " from players, catches team chat players 
	if string.sub(conline,1,7) == "(TEAM) " then
		conline = string.sub(conline,8)
	end 
	
	local chatstart,chatend,user = string.find(conline,"(.-) :  %s-(.-)") --Find a chat message 
		
	if chatstart and chatend then 
		if allChat then 
			TimedPrint(conline) --Prints chat anyway
		end 
		
		prevUser = user --store their name for housekeeping
		
		if CheaterPrint and not allchat then 
			if isCheater(prevUser) then
				if prevCheaterLine ~= conline then --If the current spammed line is not the same as last spam line...
					prevCheaterLine = conline --Store the new one...
					TimedPrint(conline) -- print it 
					SpamCount = 0 --Reset the counter if it changed.
				else --If it *still* is the same line 
					if SpamCount >= SpamMax then --Did we get it SpamMax times again? 
						prevCheaterLine = conline --Store it just in case...
						TimedPrint(conline) --Print it 
						SpamCount = 0 -- Reset the counter 
					else --if we didn't, increment by 1...
						SpamCount = SpamCount + 1
					end
				end 
			elseif isCheater(conline) then 
				TimedPrint(string.format("!>%s",conline))
			end 
		end 
		
		--Store this good line and reset the flag;
		prevConLine = conline
		NewLineFound = false 
		
	elseif string.gsub(conline,"%s","") == "" then  --New line found in current logs ; Changed so *anything thats just spaces* is seen as new line
		--Check what the last one was, if it'sa chat message; Cheater!
		if NewLineFound then 
			local cheatLine = string.gsub(prevConLine,"*DEAD* ","")
			if string.find(cheatLine,"[%(TEAM%)]?(.-) :  %s-(.-)") then --If the earlier message was a cheater (even if they were dead)...
				if updateCheater(prevUser,nil) then --user,steamid; returns true on new cheater, false on updated cheater.
					--Hey it updated 
					--TimedPrint(conline)
					TimedPrint(string.format("Found %d Cheaters!",#Cheaters))
					
					--TODO: RunCommand("status") 
					TimedPrint("\t->Please run status!")
					--RunCommand("status","_LUA_STATUS") 
				end 
			end 
			--START OF _LUA_STATUS; USELESS RIGHT NOW, TODO: FIX
		else --Else if it's Not a cheater, it might be some TF2 bug? 
			--TODO: FIX THIS UP, seems to print a *lot* of my console still, when it doesn't need to.
			
			--------------------------------------------------------------------------
			-- These trip up my anticheat, just block them off.						--
			--	"Setting max routable payload size from 1260 to 1200 for CLIENT"	--
			--	"Server Number: %d+"												--
			--------------------------------------------------------------------------
			
			if prevConLine ~= "Setting max routable payload size from 1260 to 1200 for CLIENT" and not string.find(prevConLine,"Server Number: %d+") then
				--This is disabled for now, doesn't seem that important.
				--TimedPrint("---\""..tostring(prevConLine).."\"---")
			end 
			NewLineFound = true 
		end 
	elseif string.find(conline,"(_LUA_PREPARE)%s?") then 
		BotCount = 0
		TimedPrint("Started scan for bots...")
		--Hack to fix a stale variable (manual status) 
		if KickCheater then TimedPrint("WARN: KickCheater was not nil, was status manually called?",KickCheater) end
		KickCheater = nil 
		UpdateTables()
		--unsure if i should do this, it's late
		--[[
		if KickWaitName then TimedPrint("WARN: KickWaitName was not nil, was status manually called?") end 
		KickWaitName = nil 
		--]]
	elseif string.find(conline,"(_LUA_STATUS)%s?") then 
		--We  already got what we need! Skip to kicking 
		TimedPrint(string.format("Status should be received, Found bots: %d",BotCount)) --DEBUG 
		if KickCheater and not KickWaitName then 
			TimedPrint("Attempting to kick "..KickCheater)
			RunCommand(string.format(((debugMode and "echo ") or "").."callvote kick \"%s cheating\"",KickCheater),"_LUA_VOTED") --If debug mode is enabled, don't call actual votekicks
			KickCheater = nil 
			KickWaitName = nil 
		else 
			RunCommand("wait "..WaitSec(0.5),"_LUA_WAIT") 
		end 
		LUAWAITCYCLES = 0 	
	elseif string.find(conline,"(_LUA_WAIT)%s?") then 
		--TimedPrint("_LUA_WAIT") --DEBUG 
		LUAWAITCYCLES = LUAWAITCYCLES + 1
		if not KickWaitName then --Are we waiting for a bot...? If so, Wait indefinately...? TODO: Make sure this doesn't always loop 
			if LUAWAITCYCLES >= 5 and not KickCheater then --This makes sure that we'll be able to kick them, waits a few seconds but executes the cfg a few times as well.
				--TimedPrint("It seems no cheaters were found, aborting..")
				RunCommand(string.format("say %q",NoBotMsg),"_LUA_END")  --We've waited long enough, let's give up.
			else 
				if KickCheater then 
					TimedPrint("Attempting to kick "..KickCheater)
					RunCommand(string.format(((debugMode and "echo ") or "").."callvote kick \"%s cheating\"",KickCheater),"_LUA_VOTED")  --This would go into a script thing 
					KickCheater = nil 
				end 
			end 
		else
			--[[-- We can't actually call a vote if KickWaitName is valid, we need to *wait* :\ 
			if KickCheater then 
				TimedPrint("Attempting to kick "..KickCheater)
				RunCommand(string.format("callvote kick %s cheating",KickCheater),"_LUA_VOTED")  --This would go into a script thing 
				KickCheater = nil 
				KickWaitName = nil 
			end 
			--]]--
			if LUAWAITCYCLES >= 20 then --Only loop 20 times, 100 is abusively too long...
				KickCheater = nil 
				KickWaitName = nil
				TimedPrint(string.format("%q did not spawn in time, aborting...",KickWaitName))
				RunCommand()  --We've waited long enough, let's give up.
				LUAWAITCYCLES = 0 
				--IDEA: Maybe just restart at _LUA_PREPARE and see if we can catch the bot again?
			end 
		end 
	elseif string.find(conline,"(_LUA_VOTED)%s?")  then --Bug? Tf2 Adds a space at the end.
		TimedPrint("Called a vote, let's hope it passes.") --DEBUG 
		LUAWAITCYCLES = 0 --We got a vote!
		RunCommand() --Wipes the config file.
	elseif string.find(conline,"(_LUA_END)%s?") then 
		--TODO: Replace stuff that does RunCommand() to RunCommand("say <No bots found>","_LUA_NOBOT")
		--and put the give up parts here 
		RunCommand()
		--if bots = 0 then say (no bot found)
		--else, just go straight to RunCommand()
	elseif string.find(conline,"(End of Lua_NoCheat)%s?") then
		TimedPrint("Scan completed.") --DEBUG 
		LUAWAITCYCLES = 0
		ResetConfig() --Okay we ran to the end and now we can put the config back
	--elseif KickWaitName and conline == KickWaitName.." connected" then 
	elseif KickWaitName and string.gsub(conline,"( connected)%s?","") == KickWaitName then --Wait until the player is connected.
		if KickCheater then 
			LUAWAITCYCLES = 0 
			--We can kick the bot now!!! DO IT!!
			TimedPrint("A known bot connected: "..KickWaitName.." ["..KickCheater.."] ")
			--It seems that actually placing this here breaks if the bot connected between the spawning state & _LUA_STATUS
			--[[
			RunCommand(string.format(((debugMode and "echo ") or "").."callvote kick %s cheating",KickCheater),"_LUA_VOTED")  --This would go into a script thing 
			KickCheater = nil 
			]]--
			KickWaitName = nil 
		end 
	else
		--Might be possible to just put printing unknown suspicious lines here: 
		
		--Parses every line as if they were status lines, if it doesnt work it should fail here. 
		if not string.gmatch(conline,"[^\n]+") then --There's no newlines here...
			if not chatstart and not chatend and not user then --It's not a chat message... 
				if SuspPrint then --Is suspicious printing enabled? 
					if isCheater(statusline) then --Just scan the whole thing for possible cheat words for now; attempt to not have status messages
						TimedPrint(string.format("!>%s",statusline)) --print it...
					end 
				end
			end 
		end 
		
		local conlineback = conline
		for fixme in string.gmatch(conline,'".-"') do --Catches *all* the names even with empty names, except if they have `"` which breaks :(
			--I can't gsub apparently lol 
			
			local fixmenew = fixme:gsub("\n","\\n") --All new lines were replaced. 
			fixme = fixme:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
			conline = conline:gsub(fixme,fixmenew)
		end 
		if (conline ~= conlineback) or string.find(conline,"\\n") then --if the text is not the same as the backup, or there's escaped new lines
			TimedPrint("WARNING: escaped newlines found in fixed text, bots with newlines possible; *BE CAREFUL*")
		end 
		conlineback = nil --This is only to warn in console
		for statusline in string.gmatch(conline,"[^\n]+") do --This is *assuming* the newline is at the end of the line, not inside plyname
		
			local userid,plyname, steamid,plystate = string.match(statusline,"#%s+(%d+)%s+\"(.+)\"%s+(%[U:%d:%d+%])%s+%d+:%d+%s+%d+%s+%d+%s+(.+)")
			
			--[[
			if not (userid and plyname and steamid) and not StatusCount then
				TimedPrint("Invalid status count?")
			end 
			]]--
			if SuspPrint then 
				if isCheater(statusline) then --Just scan the whole thing for possible cheat words for now; attempt to not have status messages
					TimedPrint(string.format("!>%s",statusline))
				end 
			end
		
			if userid and plyname and steamid then
				--TODO: Make sure that the old KickCheater is not an innocent player (should not be valid)
				for k,chtTbl in pairs(Cheaters) do 
					if chtTbl['name']==plyname then --We already have a cheater with that name! Log their steamid 
						if CheaterLogEnabled then 
							local chtFh = io.open("cheaters.log","a+")
							chtFh:write(plyname.."\n"..steamid.."\n")  --This makes it so https://steamid.io  supports just copypasting my list :) 
							chtFh:close()
						end 
						local updTime = chtTbl['updtime'] -- When was it last updated? 
						updateCheater(plyname,steamid)
						TimedPrint(string.format("Added <%s> %s to cheater list: %q",userid,steamid,plyname)) --userid,steamid,plyname; Userid is a string as it needs to passed as a string anyways.
						
						--TODO: ONLY CALLVOTE A CHEATER ONCE EVERY 15-30 SECONDS
						KickCheater = userid 
					end 
				end 
				
				--This code kind of sucks, but it'll work for now. 
				--TODO: Actually use a table of forcekick bots
				--TODO: Have an option to enable/disable this
				if EnableBlackList then 
					local PlyNameFiltered = string.gsub(plyname,"\xE2\x80\x8F","") --Removes namestealing bytes ("CAN YOU QUACK" uses them *a lot*); TODO: Maybe find other 0-width characters
					local DEBUGNAME = PlyNameFiltered 
					PlyNameFiltered = string.gsub(PlyNameFiltered,"^%(%d%)","") --Removes (1) off the start of the myg0t bots, as they get numbered if more than one in a server.
					if DEBUGNAME == PlyNameFiltered and string.match(DEBUGNAME,"%(%d%).*") then  print("[BUG?]",PlyNameFiltered) end 
					DEBUGNAME = nil 
					PlyNameFiltered = string.gsub(PlyNameFiltered," %d+$","") --Removes numbers at the end of their names, kind of stupid fix though
					local PlyNameFilteredAlt = string.gsub(PlyNameFiltered,"%s","") --Remove all spaces IN THE ALTERNATE STRING (Should re-check against new bots that adds spaces as well 
					local FoundBLSteamID = false 
					
					for k,BLSteamID in pairs(BlacklistSteamIDs) do 
						if steamid == BLSteamID then 
							FoundBLSteamID = true 
							BotCount = BotCount + 1
							TimedPrint(string.format("[Banned SteamID] Kicking bot <%d> %s (%s) state=%q",userid,steamid,plyname,plystate))
							if not KickWaitName then 
								KickCheater = userid --The steamid is blacklisted! KICK IT.
								BotSteam = steamid
								BotName = plyname
								if plystate == "spawning" or plystate == "connecting" then 
									KickWaitName = plyname
								else 
									KickWaitName = nil --Don't bother waiting 
								end 
							end 
							break --Right, we stop the loop here.
						end 
					end 
					
					--Re-enabled this block because i'd rather have a better list of bots than just kick the banned ones
					--if not KickCheater then --Disabled this, removed end 
					if not FoundBLSteamID then --We didn't find them in the SteamID Blacklist, try here
						for k,BLName in pairs(BlackListedNames) do 
							if (PlyNameFiltered == BLName or PlyNameFilteredAlt == BLName) and not IsWhitelisted(steamid) then --kick anyone with a matching name but *not* whitelisted steamids 
								--CHECK A WHITELIST FIRST 
								BotCount = BotCount + 1
								TimedPrint(string.format("[Banned Name] Kicking bot <%d> %s (%s) state=%q",userid,steamid,plyname,plystate))
								if not KickWaitName then 
									KickCheater = userid
									BotSteam = steamid
									BotName = plyname
									if plystate == "spawning" or plystate == "connecting" then --fix spawning/connecting states?
										KickWaitName = plyname
									else 
										KickWaitName = nil --Don't bother waiting 
									end 
								end
								AddCheaterToTables(plyname,steamid)
								break
							elseif IsWhitelisted(steamid) then --debug
								--print(string.format("The user %s with steamid %s is whitelisted!",plyname,steamid))
							end 
						end 
					end 
					PlyNameFiltered = nil 
					FoundBLSteamID = nil 
				end 
			end
		end 
		--This is how STATUS looks like, Have to find name & steamid
		--#    709 "[VAC] OneTrick"    [U:1:1086889437]    00:09       83   77 spawning
		------------------------------------------------------------------------------------------

		--Store this good line and reset the flag;
		prevConLine = conline
		NewLineFound = false 
		--[[
		if debugMode then 
			TimedPrint("None valid: ",conline)
		end 
		]]--
		
		
		--EXPERIMENTAL:  Checks for the remaining lines if it contains any namestealer bytes :) 
		--if string.find(conline,"\xE2\x80\x8F") then --might update  to isCheater, so known cheaters detected outside chat/status 
		--TODO: Fix this, this does not work anymore.
		
	end  
	
	if debugMode then 
		print("[DEBUG] \""..conline.."\"")
	end 
	
end 

--Shutdown cleanly
consoleparser.shutdown()
TimedPrint("Shutdown of the script completed, Thank you for using Link2006's Cheater Detector") --End of script :)