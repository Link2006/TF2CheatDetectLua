--DO NOT CALL DIRECTLY, USE REQUIRE() 

local games = {
	 --Add your own games like this, beware that the gamename *must* be a valid Lua variable name (does not start with a number,etc)
	 --Please keep the backslashes escaped (\\) and have the last two at the end 
	 --EXAMPLE C:\\Program Files (x86)\\Steam\\Steamapps\\common\\Team Fortress 2\\tf\\
	 
	tf2="Z:\\SteamGames\\steamapps\\common\\Team Fortress 2/tf/",
	--csgo="Z:\\SteamGames\\steamapps\\common\\Counter-Strike Global Offensive\\csgo\\"
}
local stdinput
local gamefolder

local consoleparser ={} 
function consoleparser.init() 
	gamefolder = "PLACEHOLDER" --Placeholder for now 
	local selgame = "nil" --this cannot work further down and can't be set in the table :)
	local validChoice = false 
	
	--Select the game here, no function :(
	while not validChoice do 
		print("Please select the game you want to use:\n")
		print("Game","Path")
		print("----","----")
		for k,v in pairs(games) do 
			print(k,v)
		end 
		io.write("\nGame: ")
		selgame = io.read() --Too lazy to implement autoselecting the only choice available
		if not games[selgame] then 
			print("-----")
			print("Invalid choice: "..selgame)
			print("-----")
		else 
			print('-----')
			print("Set game to: ",selgame,games[selgame])
			print('-----')
			gamefolder = games[selgame] --This is now valid .
			validChoice = true --:)
		end 
	end 
	stdinput = io.input() --Please grab this 
	--[[
		--Made obsolete with -conclearlog :)
		print("Cleaning console.log...")
		local tempfh = io.open(gamefolder.."console.log","w")
		tempfh:close() --lol
		print("Done.")
	]]--
	--consoleparser.file = io.input(gamefolder.."console.log")
	--MAC FIX? 
	consoleparser.file = io.open(gamefolder.."console.log","r")
	
	--Okay we need to skip to the end of the file! before starting, 
	consoleparser.file:seek("end")
end 

function consoleparser.getPath() 
	if gamefolder then 
		return gamefolder 
	else 
		print("ERROR: ConsoleParser is not initialised!")
	end 
end 
function consoleparser.getNextLine()
	if not consoleparser.file then 
		print("ERROR: Cannot use library after closing, please re-init")
		return false --failed 
	end 
	
	local conline = nil 
	
	while not conline do 
		--conline = io.read("*all") --Read the next line in the file 
		if consoleparser.file:read(0) ~= nil then 
			conline = consoleparser.file:read("*all") --Read the next chunk of data, I'm using "*all" as this is more reliable against bots; i prefer the occasional hiccups over having broken scripts.
			if conline then --if it has a new line, read it 
				--These two does *nothing* lmao oops. 
				--conline:gsub("\r","\\r") --No carriage return (source engine bug??? only tested against echo)
				--conline:gsub("\a","\\a") --Source is weird :)
				--This returns a new line at the very end, remove it as we don't need it.
				conline = conline:sub(1,-2) --Removes the newline at the very end the bytes 
				return conline
			end 
		end 
	end 
	
	return conline 
end 

function consoleparser.shutdown() 
	if not consoleparser.file then 
		print("ERROR: Cannot use library after closing, please re-init")
		return false --failed 
	else 
		io.input(stdinput) --Please restore 
		consoleparser.file:close() --Close 
		consoleparser.file = nil 
		return true
	end 
end 
return consoleparser