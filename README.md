# Shadow Warrior Windows 11 Port

A reproducible Windows 11 x64 modernization kit for the GPL-released Shadow Warrior/JFShadowWarrior codebase.

This repository is an **engine/source-port project only**. It does not contain the original commercial Shadow Warrior data files. You must supply legally obtained game data such as `SW.GRP` from your own installation.

## Current state

Stage 3 display modernization is implemented in the overlay and CI configuration. The exact Windows 11 x64 build and runtime behavior still need to be validated by GitHub Actions and on real hardware.

Implemented so far:

- Visual Studio 2022 x64 build profile
- legacy assembly disabled in the Win11 profile
- Polymost/OpenGL 3 build profile
- PerMonitorV2 DPI-aware Windows manifest
- `longPathAware`
- 1920x1080/32-bit fresh-install default
- modern control preset
- normal `%APPDATA%\JFShadowWarrior` profile behavior preserved
- portable mode through upstream `user_profiles_disabled`
- separate game-data path using upstream `SWGRP`
- Windowed / Exclusive Fullscreen / Borderless overrides
- monitor selection
- VSync control
- optional exclusive-fullscreen refresh cap
- standard display modes through 4K and common ultrawide sizes
- diagnostics and packaging scripts
- Windows 11 GitHub Actions build

## Quick start on Windows 11

Requirements:

- Windows 11 x64
- Git for Windows
- Visual Studio 2022 with **Desktop development with C++**
- legally obtained Shadow Warrior game data

Open PowerShell in the repository:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\bootstrap-win11.ps1
.\scripts\build-win11.ps1
```

Then start with your game-data directory:

```powershell
.\scripts\run-win11.ps1 -GameDataPath "C:\Games\Shadow Warrior"
```

The Stage 3 launcher defaults to borderless desktop fullscreen. Other examples:

```powershell
# Classic exclusive fullscreen
.\scripts\run-win11.ps1 -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Fullscreen

# Exclusive fullscreen, capped to 144 Hz during mode selection
.\scripts\run-win11.ps1 -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Fullscreen -MaxRefresh 144

# Windowed
.\scripts\run-win11.ps1 -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Windowed

# Second SDL display, borderless
.\scripts\run-win11.ps1 -GameDataPath "C:\Games\Shadow Warrior" -DisplayMode Borderless -Monitor 1
```

## Display controls

The JFBuild Stage 3 patch recognizes:

```text
SW_DISPLAY_MODE=windowed|fullscreen|borderless
SW_MONITOR=<SDL display index>
SW_VSYNC=-1..8
SW_MAX_REFRESH=<Hz>
```

The included PowerShell launchers set these variables for the game process and restore the previous environment afterward.

Borderless mode uses SDL desktop fullscreen and therefore follows the selected monitor's current desktop mode. Exclusive fullscreen retains the existing JFBuild display-mode selection path.

The engine's SDL timer already uses a high-resolution performance counter independently of frame presentation, so Stage 3 deliberately does not modify simulation timing for high-refresh displays.

## Portable vs profile mode

Normal JFShadowWarrior behavior writes mutable configuration/save data under:

```text
%APPDATA%\JFShadowWarrior
```

The existing upstream marker file:

```text
user_profiles_disabled
```

can be used to request portable behavior. Use:

```powershell
.\scripts\set-portable-mode.ps1 -Mode On
```

or pass `-Portable` to the launcher.

## Packaging

After a successful build:

```powershell
.\scripts\package-win11.ps1
```

The generated package is engine-only. The packaging script intentionally does not include `SW.GRP` or other commercial assets.

## Repository structure

- `Based.md` - project rules and implementation direction
- `PROJECT-STATUS.md` - current development state
- `PORTING-NOTES.md` - technical notes and verified assumptions
- `patches/` - JFShadowWarrior and JFBuild source patches
- `overlay/` - MSVC profile and Windows manifest
- `scripts/` - bootstrap/build/run/diagnostic/package scripts
- `launcher/` - packaged Windows launcher
- `docs/` - display notes and manual regression checklist
- `.github/workflows/windows11-x64.yml` - Windows 11 x64 CI build

## Licensing

Respect the licenses present in the upstream projects. The source-code release does **not** grant permission to redistribute the original commercial Shadow Warrior art, maps, sounds, music or other game assets.

See upstream JFShadowWarrior for the original project history and licensing files.
