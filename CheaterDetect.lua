-- This script should only print warnings and status lines
-- Anything that seems to be a chat message followed by empty lines will be considered a cheater/bot.

----------------------CONFIG----------------------
--CONFIG: 
local debugMode = false  --Debugprints :) 
local allChat = false --Prints chat messages 
local SpamMax = 10  --Only print once every X lines
local CheaterLogEnabled = true 

local ChatMessage = "[Bind] Cheat Detector (github.com/Link2006/TF2CheatDetectLua)" --What you want said when pressing the bind; SET TO FALSE/NIL TO MUTE 

local fps_max = 180 --Issues with the script running too fast/too slow? Tweak this !
--NOTES: ABOUT FPS_MAX!
--This variable here should be set to what's your average *highest* FPS (vsync or not) 
--It is used to calculate your wait commands which are relying on a (somewhat) stable frame-rate.
--Example: You usually hit 180 fps, you would set this to 180 (which should make "wait 180" delay stuff by 1 second.


--CONSTANTS: 
--NOTE: These *DO* need to be escaped, they are used as patterns! End results is "("..word..")"
local knownCheatWords = {"(discord.gg/eyPQd9Q)","(%[VALVE%])","(%[VAC%])","(\x1B)","(OneTrick)", "(LMAOBOX)","(\xE2\x80\x8F)",	"(MYG%)T)"} -- \x1B = Escape (Cathook), \xE2+ = Namestealer bytes
local ScriptVersion = "0.6"

--VARIABLES: 
local Cheaters = {} 
local prevUser = ""
local prevConLine = ""
local prevCheaterLine = "" 
local NewLineFound = false 
local SpamCount = SpamMax --Increment this every newline, will print the first newline.
--TODO: Implementation

-----------DO NOT TOUCH BELOW THIS LINE-----------



local function WaitSec(seconds)
	return math.ceil(fps_max * seconds) -- Returns a number of frames to wait from the seconds input (rounded up due to source wait commands requiring integers)
end 

print(string.format("Cheater Detector %s\n\n",ScriptVersion))--Space this out 
print("\tPlease bind a key to \"exec lua_nocheat\" to activate the script")
--Let's use the actual config to do stuff, no need to create a bind
--print(string.format("\tbind pgup \"say [Bind] Cheat Detector %s;wait %d;status;wait %d;exec lua_nocheat\"\n",ScriptVersion,WaitSec(0.5),WaitSec(0.5)))

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
		print("[WARN] Failed to open file!",luacfg)
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
			print(string.format("Removing invalid entry #%d...",k))
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
				print(string.format("WARN: Possible Namestealer!  Cheaters: {name=%q,steamid=%q} ; args: [name=%q,steamid=%q]",chtTbl['name'],chtTbl['steamid'],name,steamid)) --Namestealer? Should never trip as namesteals are adding a 0width character at the end; making it unique still
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
				print("STRING=",str,"WORD=",word,string.find(str,word)) --Not using string.format as this is just debug stuff
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

print("Cleaning config file...")
local function ResetConfig() 
	RunCommand(string.format("say %s;wait %d;status;wait %d;echo _LUA_STATUS;wait %d;exec lua_nocheat",ChatMessage,WaitSec(0.5),WaitSec(0.5),WaitSec(0.5)))
end 
ResetConfig() 

local LUAWAITCYCLES = 0 

print("!!Please use CTRL-C to stop the script, this will allow resetting the config/bind!!\n")

--Main loop
while true do --Never stop 
	local pcallstatus, conline = pcall(consoleparser.getNextLine)
	if not pcallstatus then
		if string.sub(conline,-12) == "interrupted!" then 
			print("Exiting...")
		else 
			print("Unexpected error: '"..conline.."'") 
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
			print(conline) --Prints chat anyway
		end 
		
		prevUser = user --store their name for housekeeping
		
		if isCheater(prevUser) then
			if not allChat then 
				if prevCheaterLine ~= conline then --If the current spammed line is not the same as last spam line...
					prevCheaterLine = conline --Store the new one...
					print(conline) -- print it 
					SpamCount = 0 --Reset the counter if it changed.
				else --If it *still* is the same line 
					if SpamCount >= SpamMax then --Did we get it SpamMax times again? 
						prevCheaterLine = conline --Store it just in case...
						print(conline) --Print it 
						SpamCount = 0 -- Reset the counter 
					else --if we didn't, increment by 1...
						SpamCount = SpamCount + 1
					end
				end 
			else
				print("!<SUSPECT>!") --Someone in console is known cheater, but doesn't clear chat?
			end 
		elseif isCheater(conline) then 
			print(string.format("!>%s",conline))
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
					--print(conline)
					print(string.format("Found %d Cheaters!\n%s",#Cheaters,prevConLine))
					
					--TODO: RunCommand("status") 
					print("\t->Please run status!")
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
				--print("---\""..tostring(prevConLine).."\"---")
			end 
			NewLineFound = true 
		end 
	elseif conline == "_LUA_STATUS " then 
		RunCommand("wait "..WaitSec(1),"_LUA_WAIT") 
		LUAWAITCYCLES = 0 
	elseif conline == "_LUA_WAIT " then 	
		LUAWAITCYCLES = LUAWAITCYCLES + 1
		if LUAWAITCYCLES >= 1 then --Relic from the past: had to make sure to wait properly
			--print("It seems no cheaters were found, aborting..")
			RunCommand() --Nothing happened... 
		end 
	elseif conline == "_LUA_VOTED "  then --Bug? Tf2 Adds a space at the end.
		LUAWAITCYCLES = 0 --We got a vote!
		RunCommand() --Wipes the config file.
	--END OF _LUA_STATUS; USELESS RIGHT NOW, TODO: FIX
	elseif conline == "End of Lua_NoCheat " then
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
					print(string.format("Added <%s> %s to cheater list: %q",userid,steamid,plyname)) --userid,steamid,plyname; Userid is a string as it needs to passed as a string anyways.
					
					--TODO: ONLY CALLVOTE A CHEATER ONCE EVERY 15-30 SECONDS
					
					RunCommand(string.format("callvote kick %s cheating",userid),"_LUA_VOTED")  --This would go into a script thing 
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
			print("None valid: ",conline)
		end 
		]]--
		
		
		--EXPERIMENTAL:  Checks for the remaining lines if it contains any namestealer bytes :) 
		--if string.find(conline,"\xE2\x80\x8F") then --might update  to isCheater, so known cheaters detected outside chat/status 
		if isCheater(conline) then --Just scan the whole thing for possible cheat words for now 
			print(string.format("?>%s",conline))
		end 
	
	end  
	
	--store this line, if it's not a newline.
	
	if debugMode then 
		print(conline)
	end 
	
end 

--Shutdown cleanly
consoleparser.shutdown()
print("Shutdown of the script completed, Thank you for using Link2006's Cheater Detector") --End of script :)