-- This script should only print warnings and status lines
-- Anything that seems to be a chat message followed by empty lines will be considered a cheater/bot.

----------------------CONFIG----------------------
--CONFIG: 
local debugMode = false  --Debugprints :) 
local allChat = false --Prints chat messages 
local SpamMax = 10  --Only print once every X lines
local CheaterLogEnabled = true 
local SuspPrint = true --Prints suspicious non-chat lines  (Kills, Connections, etc...)
local TimeStamp = true -- This allows you to enable/disable the timestamp in console.

local ChatMessageEnabled = true --Set this to false to stop saying the message in Chat 
local ChatMessage = "[Bind] Cheat Detector (github.com/Link2006/TF2CheatDetectLua)" --What you want said when pressing the bind;

local fps_max = 180 --Issues with the script running too fast/too slow? Tweak this !
--NOTES: ABOUT FPS_MAX!
--This variable here should be set to what's your average *highest* FPS (vsync or not) 
--It is used to calculate your wait commands which are relying on a (somewhat) stable frame-rate.
--Example: You usually hit 180 fps, you would set this to 180 (which should make "wait 180" delay stuff by 1 second.

--BlackList/Whitelist support
--Anyone with a matching name (without invisible characters/namesteal bytes) will get kicked 
--Unless their steamIDs is in the whitelist. 

local EnableBlackList = true --This will kick anyone that has a name that matches a word in BlackListedNames
local BlackListedNames = {"MYG)T","CAN YOU QUACK","raspy","/id/raspy_on_osu"} -- Names to kick when status is received
local WhiteListSteamIDs = { --USE SteamID3 here to whitelist: 
	"[U:1:11524751]", --		Link2006 - Author of this script.
	"[U:1:67033233]", --		raspy - Victim of Impersonation bots, create a guide to kick bots
	}

-----DO NOT TOUCH ANYTHING BELOW-----
-----DO NOT TOUCH ANYTHING BELOW-----
-----DO NOT TOUCH ANYTHING BELOW-----
-----DO NOT TOUCH ANYTHING BELOW-----

--CONSTANTS: 
--NOTE: These *DO* need to be escaped, they are used as patterns! End results is "("..word..")"
local knownCheatWords = {"(discord.gg/eyPQd9Q)","(%[VALVE%])","(%[VAC%])","(\x1B)","(OneTrick)", "(LMAOBOX)","(\xE2\x80\x8F)",	"(MYG%)T)",'(Stallman Bot)'} -- \x1B = Escape (Cathook), \xE2+ = Namestealer bytes
local ScriptVersion = "0.72"

--VARIABLES: 
local Cheaters = {} 
local prevUser = ""
local prevConLine = ""
local prevCheaterLine = "" 
local NewLineFound = false 
local SpamCount = SpamMax --Increment this every newline, will print the first newline.
local KickCheater = nil
--TODO: Implementation

-----------DO NOT TOUCH BELOW THIS LINE-----------

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

print(string.format("Cheater Detector %s\n\n",ScriptVersion))--Space this out 
print("Please bind a key to \"exec lua_nocheat\" to activate the script\n")
--Let's use the actual config to do stuff, no need to create a bind
--TimedPrint(string.format("\tbind pgup \"say [Bind] Cheat Detector %s;wait %d;status;wait %d;exec lua_nocheat\"\n",ScriptVersion,WaitSec(0.5),WaitSec(0.5)))

--My library to grab source engine console output.
local consoleparser = require("consoleparser")
consoleparser.init() --Game select + io.input setup.

--This is used later in RunCommand...
local tf2path = consoleparser.getPath() --This returns the path to the tf2 folder.

--TODO: getCheater(<something>)  (not needed anymore?)
--TODO: Probably make it so it writes the current script version inside the 'say bind'? maybe also say if we detected them or not? 

local function RunCommand(cmd,step)
		
	--step _LUA_STATUS = when we've done status; 
	--step _LUA_VOTED = when we've done callvote;
	
	local luacfg = io.open(tf2path.."cfg\\lua_nocheat.cfg","w")
	if not luacfg then
		TimedPrint("[WARN] Failed to open file!",luacfg)
		return false 
	end 
	--This should just *delete* when we get a nil variable.
	if cmd and step then 
		luacfg:write(string.format("echo %s;wait %d;%s;exec lua_nocheat",step,WaitSec(0.5),cmd)) --run the command *after* we cleared the file!  
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

local function isCheater(str) --accepts a cheater name & messages 
	for k,word in pairs(knownCheatWords) do 
		if string.find(str,".*"..word..".*") then 
			if debugMode then 
				TimedPrint("STRING=",str,"WORD=",word,string.find(str,word)) --Not using string.format as this is just debug stuff
			end 
			return true 
		end 
	end 
	
	for k,chtTbl in pairs(Cheaters) do
		if chtTbl['name'] == str or chtTbl['steamid'] == str then 
			--Yes it is a cheater, their Name/SteamID is here :)
			return true
		end 
	end 
	return false 
end 

TimedPrint("Cleaning config file...")
local function ResetConfig() 
	if ChatMessageEnabled then 
		RunCommand(string.format("say %s;wait %d;status;wait %d;echo _LUA_STATUS;wait %d;exec lua_nocheat",ChatMessage,WaitSec(1.25),WaitSec(0.5),WaitSec(0.5)))
	else
		RunCommand(string.format("wait %d;status;wait %d;echo _LUA_STATUS;wait %d;exec lua_nocheat",WaitSec(0.5),WaitSec(0.5),WaitSec(0.5)))
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
		
		if isCheater(prevUser) then
			if not allChat then 
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
			else
				TimedPrint("!<SUSPECT>!") --Someone in console is known cheater, but doesn't clear chat?
			end 
		elseif isCheater(conline) then 
			TimedPrint(string.format("!>%s",conline))
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
	elseif conline == "_LUA_STATUS " then 
		TimedPrint("_LUA_STATUS") --DEBUG 
		RunCommand("wait "..WaitSec(0.5),"_LUA_WAIT") 
		LUAWAITCYCLES = 0 
	elseif conline == "_LUA_WAIT " then 	
		TimedPrint("_LUA_WAIT") --DEBUG 
		LUAWAITCYCLES = LUAWAITCYCLES + 1
		if LUAWAITCYCLES >= 5 and not KickCheater then --This makes sure that we'll be able to kick them, waits a few seconds but executes the cfg a few times as well.
			--TimedPrint("It seems no cheaters were found, aborting..")
			RunCommand() --Nothing happened... 
		else 
			if KickCheater then 
				TimedPrint("Attempting to kick "..KickCheater)
				RunCommand(string.format("callvote kick %s cheating",KickCheater),"_LUA_VOTED")  --This would go into a script thing 
				KickCheater = nil 
			end 
		end 
	elseif conline == "_LUA_VOTED "  then --Bug? Tf2 Adds a space at the end.
		TimedPrint("_LUA_VOTED") --DEBUG 
		LUAWAITCYCLES = 0 --We got a vote!
		RunCommand() --Wipes the config file.
	--END OF _LUA_STATUS; USELESS RIGHT NOW, TODO: FIX
	elseif conline == "End of Lua_NoCheat " then
		TimedPrint("_LUA_END") --DEBUG 
		LUAWAITCYCLES = 0
		ResetConfig() --Okay we ran to the end and now we can put the config back
	else
		------------------------------------------------------------------------------------------
		--This is for possible status lines
		local userid,plyname, steamid = string.match(conline,"#%s+(%d+)%s+\"(.+)\"%s+(%[U:%d:%d+%])")
		
		--TODO: 
		if userid and plyname and steamid then
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
				PlyNameFiltered = string.gsub(PlyNameFiltered,"^%(%d%)","") --Removes (1) off the start of the myg0t bots, as they get numbered if more than one in a server.
				for k,BLName in pairs(BlackListedNames) do 
					if PlyNameFiltered == BLName and not IsWhitelisted(steamid) then --kick anyone with a matching name but *not* whitelisted steamids 
						--CHECK A WHITELIST FIRST 
						TimedPrint(string.format("Kicking Bot: <%d> %s",userid,PlyNameFiltered))
						KickCheater = userid
						break
					elseif IsWhitelisted(steamid) then --debug
						--print(string.format("The user %s with steamid %s is whitelisted!",plyname,steamid))
					end 
				end 
				PlyNameFiltered = nil 
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
		if SuspPrint then 
			if isCheater(conline) then --Just scan the whole thing for possible cheat words for now 
				TimedPrint(string.format("?>%s",conline))
			end 
		end
	
	end  
	
	--store this line, if it's not a newline.
	
	if debugMode then 
		TimedPrint(conline)
	end 
	
end 

--Shutdown cleanly
consoleparser.shutdown()
TimedPrint("Shutdown of the script completed, Thank you for using Link2006's Cheater Detector") --End of script :)