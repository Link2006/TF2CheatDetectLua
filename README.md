# Cheater Detector 1.1

### Contact me:
Twitter: [@Linkcool2006](https://twitter.com/linkcool2006/)

### Alternatives: 
[tf2_bot_detector by PazerOP](https://github.com/PazerOP/tf2_bot_detector)

### Requirements

- Team Fortress 2 with a Steam account that can votekick (Requirements uncertain, needs more information) 
- Lua 5.3+ (Might work with 5.2?),Please look online for instructions  [Downloads for Win32/Win64](http://luabinaries.sourceforge.net/download.html) 
- A downloaded zip of these files


### Configuration
- Download the repository (either via `git` cloning or clicking `code` then `download zip`)
- Extract the files to a folder of your choosing (Do not simply put them in TF2's folder)
- On Steam, go to TF2's Properties, Set Launch options and add `-condebug -conclearlog` to your arguments
- Once this is done, modify `consoleparser.lua` to change the path where TF2 is installed (Important!)
- `CheaterDetect.lua` also has quite a few settings to change from their defaults, Look further down for a list.
- Start TF2, Bind a key to `exec lua_nocheat` 
- Start the script by running `lua CheaterDetect.lua` (where `lua` is your Lua interpreter of choice), to safely exit the script, please interrupt it (CTRL-C for windows)
- (Optional) enable `developer 1` and set `hud_saytext_time ` to 180, this allows you to more easily identify chat clears.

### Usage
- Wait for a bot and press your bind, it should automaticly call a vote against them, if it doesn't happen then they either didn't clear chat or aren't in your team

### CheaterDetect Configs
- Check out the file config.lua for a list of what settings you can change

### Custom Lists
- I've added a few ways to load multiple files by simply adding the new list to the config. This should also eventually allow for auto-updates.

### Notes
- Just credit me if you use parts of this code.
- Any suggestions or questions can be posted as an issue.
- Should not be considered a cheat as it does not manipulate the game at all; behaves like HLDJ from back in the day
- Network support is UNTESTED and MAY NOT WORK.
