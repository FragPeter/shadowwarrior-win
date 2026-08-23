Shadow Warrior Windows 11 launcher
=================================

This package contains the engine only. Original Shadow Warrior game data is not included.

Quick start
-----------
1. Double-click Start-ShadowWarrior.cmd.
2. Select the folder that contains your legally obtained SW.GRP file.
3. The launcher starts the game in borderless desktop fullscreen by default.

Command-line examples
---------------------
Borderless on the first display:
  Start-ShadowWarrior.cmd -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Borderless -Monitor 0

Classic exclusive fullscreen with a 144 Hz cap:
  Start-ShadowWarrior.cmd -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Fullscreen -MaxRefresh 144

Windowed:
  Start-ShadowWarrior.cmd -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Windowed

Portable mode:
  Start-ShadowWarrior.cmd -GameDataPath "C:\Games\Shadow Warrior" -Portable

Normal profile mode stores writable configuration/save files under:
  %APPDATA%\JFShadowWarrior

Portable mode uses the engine working directory through the upstream user_profiles_disabled marker.

DisplayMode values:
  Config      = use the game's saved video configuration
  Windowed    = force a normal window
  Fullscreen  = classic exclusive fullscreen
  Borderless  = desktop fullscreen without a display mode switch
