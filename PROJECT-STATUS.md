# Shadow Warrior Windows 11 Port - Project Status

## Current stage

Stage 3: display modernization implemented in the code overlay. Hardware validation and the first successful Windows 11 x64 CI build are still pending.

## Implemented

- Visual Studio 2022 x64 build profile
- Legacy assembly disabled for the Win11 path
- Polymost/OpenGL 3 profile
- Windows 10/11 application manifest
- PerMonitorV2 DPI awareness
- longPathAware
- DEP/ASLR/CFG-oriented linker/compiler flags
- 1920x1080/32-bit fresh-install default
- Modern keyboard/mouse/controller preset
- Existing `%APPDATA%\JFShadowWarrior` profile behavior preserved
- Existing `user_profiles_disabled` portable switch preserved
- Explicit `SWGRP` game-data selection
- Borderless fullscreen override
- Exclusive fullscreen preserved
- Windowed override
- SDL display selection
- VSync selection through OpenGL swap interval
- Exclusive-fullscreen refresh cap
- Standard mode list expanded through 3840x2160 and common ultrawide modes
- Diagnostics scripts
- Engine-only packaging launcher
- GitHub Actions Windows 11 x64 workflow
- Manual Windows 11 regression checklist

## Not yet verified

- Full Visual Studio 2022 compile of the exact Stage 3 overlay
- Startup with actual legally obtained Shadow Warrior data
- 1080p / 1440p / 4K runtime output
- Mixed-DPI multi-monitor behavior
- 60/120/144/165 Hz timing behavior on hardware
- Xbox controller hot-plugging
- Audio device switching
- Save/load regression

## Next code target

Stage 4 input modernization:

- inspect SDL2 controller event handling
- add controller hot-plug support
- verify modern relative mouse behavior
- document/default dead zones without altering gameplay timing

The first priority before broadening Stage 4 is getting the Stage 3 Windows CI build green and fixing compile/runtime issues revealed by that build.
