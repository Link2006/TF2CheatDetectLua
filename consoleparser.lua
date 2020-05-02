--DO NOT CALL DIRECTLY, USE REQUIRE() 

local games = {
	 --Add your own games like this, beware that the gamename *must* be a valid Lua variable name (does not start with a number,etc)
	 --Please keep the backslashes escaped (\\) and have the last two at the end 
	 --EXAMPLE C:\\Program Files (x86)\\Steam\\Steamapps\\common\\Team Fortress 2\\tf\\
	 
	tf2="Z:\\SteamGames\\steamapps\\common\\Team Fortress 2\\tf\\",
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
		print("Please select the game you want to use:")
		for k,v in pairs(games) do 
			print(k,v)
		end 
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
	consoleparser.file = io.input(gamefolder.."console.log")
end 

function consoleparser.getPath() 
	if gamefolder and  then 
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
		conline = io.read() --Read the next line in the file 
		if conline then --if it has a new line, read it 
			conline:gsub("\r","") --No carriage return (source engine bug??? only tested against echo)
			conline:gsub("\a","") --Source is weird :)
			return conline
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
		io.close(consoleparser.file) --Close 
		consoleparser.file = nil 
		return true
	end 
end 
return consoleparser