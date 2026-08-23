# Windows 11 test checklist

Use this checklist on a real Windows 11 x64 system after a successful Visual Studio 2022 build.

## Build

- [ ] Clean checkout of the port kit
- [ ] `scripts/bootstrap-win11.ps1` completes
- [ ] pinned JFShadowWarrior commit is checked out
- [ ] all submodules initialize
- [ ] all three Stage 3 patches apply cleanly
- [ ] `scripts/build-win11.ps1 -Clean` completes
- [ ] `sw.exe` exists
- [ ] no unexpected proprietary files are present in the repository or build artifact

## First start

- [ ] launcher accepts a folder containing legally obtained `SW.GRP`
- [ ] launcher rejects a folder without `SW.GRP`
- [ ] game starts without administrator privileges
- [ ] no Windows compatibility mode is required
- [ ] normal profile directory is `%APPDATA%\JFShadowWarrior`
- [ ] config is created/read there
- [ ] save files are created/read there

## Portable mode

- [ ] `-Portable` creates `user_profiles_disabled`
- [ ] engine runs with engine directory as current working directory
- [ ] config/save files stay in the portable working directory
- [ ] returning to normal mode removes the marker

## Display modes

### Borderless

- [ ] 1920x1080 desktop
- [ ] 2560x1440 desktop
- [ ] 3840x2160 desktop
- [ ] selected monitor is correct
- [ ] no unwanted display-mode switch
- [ ] Alt+Tab works
- [ ] mouse is reacquired correctly after returning to the game

### Exclusive fullscreen

- [ ] 1920x1080
- [ ] 2560x1440
- [ ] 3840x2160 if exposed by the display/driver
- [ ] refresh rate shown/selected correctly
- [ ] `-MaxRefresh 60` prevents higher exclusive modes
- [ ] `-MaxRefresh 144` permits modes up to 144 Hz
- [ ] leaving fullscreen restores the desktop mode

### Windowed

- [ ] 1280x720
- [ ] 1920x1080 when desktop work area allows it
- [ ] window is centered on the expected display

## DPI

Test the startup window/launcher and game behavior at:

- [ ] 100%
- [ ] 125%
- [ ] 150%
- [ ] 200%

Mixed monitors:

- [ ] primary 100%, secondary 150%
- [ ] move/focus behavior remains usable
- [ ] no tiny or oversized startup UI caused by missing DPI awareness

## High refresh

Run identical gameplay timing checks at:

- [ ] 60 Hz
- [ ] 120 Hz
- [ ] 144 Hz
- [ ] 165 Hz if available

Verify:

- [ ] movement speed does not change
- [ ] weapon cadence does not change
- [ ] scripted sequences do not accelerate
- [ ] audio remains synchronized
- [ ] menus remain responsive

## VSync

- [ ] `-VSync 0`
- [ ] `-VSync 1`
- [ ] `-VSync -1` on a driver that supports adaptive sync interval
- [ ] unsupported adaptive mode fails gracefully or logs the existing JFBuild warning

## Input

- [ ] keyboard movement
- [ ] mouse look
- [ ] mouse buttons
- [ ] wheel input
- [ ] mouse release/reacquire after Alt+Tab
- [ ] Xbox-compatible controller recognized
- [ ] controller axes/buttons
- [ ] controller disconnect/reconnect behavior documented

## Audio

- [ ] sound effects
- [ ] music
- [ ] default output device
- [ ] switch Windows output device while game is closed
- [ ] restart uses new device

## Saves and gameplay

- [ ] new game
- [ ] save
- [ ] load
- [ ] level transition
- [ ] quit/restart/load
- [ ] no obvious gameplay-speed regression
- [ ] no obvious renderer corruption

## Package

- [ ] `scripts/package-win11.ps1` creates engine-only ZIP
- [ ] `sw.exe` included
- [ ] required runtime DLLs included when produced by the build
- [ ] launcher included
- [ ] license/release-note files included when available
- [ ] `SW.GRP` not included
- [ ] no original commercial maps/audio/art are included
