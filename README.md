# Cheater Detector 0.51 (Public Release, WIP)

### Requirements

- Team Fortress 2 
- Lua 5.3+ (Might work with 5.2?),Please look online for instructions  [Downloads for Win32/Win64](http://luabinaries.sourceforge.net/download.html) 
- A downloaded zip of these files
- This assumes fps_max of 180, either change your fps_max to 180 or edit the files' `wait` commands (default 300 means roughly 1 second) 

### Configuration
- Extract the files to a folder of your choosing (Do not simply put them in TF2's folder)
- On Steam, go to TF2's Properties, Set Launch options and add "-condebug -conclearlog" to your arguments
- Once this is done, modify `consoleparser.lua` to change the path where TF2 is installed (Important!)
- Start TF2, Bind a key to `say [Script] Cheat Detector;wait 120;status;wait 120;exec lua_nocheat`  (Saying "cheat" allows us to trigger chat clears if not already done, you can also simply exec lua_nocheat`)
- Start the script by running `lua CheaterDetect.lua` (where `lua` is your Lua interpreter of choice) 
- (Optional) enable `developer 1` and set `hud_saytext_time ` to 180, this allows you to more easily identify chat clears.

### Usage
- Wait for a bot and press your bind, it should automaticly call a vote against them, if it doesn't happen then they either didn't clear chat or aren't in your team

### Notes
- Just credit me if you use parts of this code.
- Any suggestions or questions can be posted as an issue.
