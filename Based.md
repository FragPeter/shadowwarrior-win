# BASED.md

## Project

**Shadow Warrior Windows 11 Port**

This repository modernizes the GPL-released Shadow Warrior codebase for current Windows 11 x64 systems. The practical upstream baseline is **JFShadowWarrior**, not a ground-up rewrite of the 1997 engine.

The project must preserve the original gameplay, maps, weapons, enemies, timing and data compatibility unless a change is explicitly requested.

## Primary goal

Produce a clean, reproducible, native Windows 11 version of Shadow Warrior that:

- builds as x64 with Visual Studio 2022;
- starts without DOSBox or compatibility mode;
- runs without administrator privileges;
- supports modern displays, DPI scaling, mice, keyboards and controllers;
- keeps compatibility with legally obtained original Shadow Warrior game data;
- remains maintainable and suitable for GitHub CI;
- does not redistribute proprietary game assets.

## Technical baseline

Use JFShadowWarrior as upstream:

- Repository: `https://github.com/jonof/jfsw`
- Baseline commit: `befcdd01afe5151cac2f1dabf0a7256c42537284`
- Language: primarily C, with supporting C/C++ code in JFBuild/JFAudioLib
- Platform layer: SDL2/JFBuild
- Renderer baseline: Polymost/OpenGL
- Target OS: Windows 11 64-bit
- Preferred compiler: MSVC from Visual Studio 2022

Do not replace the whole engine merely to make it look modern. Prefer small, reviewable patches that keep original behavior stable.

## Current Windows 11 profile

The Win11 build should use:

```text
PLATFORM=x64
USE_ASM=0
USE_POLYMOST=1
USE_OPENGL=3
RELEASE=1
```

Fresh-install defaults currently target:

```text
Resolution: 1920x1080
Color depth: 32-bit
Controls: modern keyboard/mouse/controller preset
```

Existing user configuration must override these defaults.

## Windows 11 requirements

### Build

- Visual Studio 2022 x64 toolchain.
- Avoid obsolete DOS/OpenWatcom dependencies in the normal Windows 11 path.
- Keep builds reproducible.
- Keep the upstream commit pinned until a deliberate upgrade is made.
- CI must build the same target as a local Windows 11 build.

### Runtime

- No administrator rights should be required.
- No Windows compatibility mode should be required.
- Keep JFShadowWarrior's verified default user-profile behavior for configuration and saves.
- On Windows, the current upstream path resolves under `%APPDATA%\JFShadowWarrior`.
- Preserve the existing `user_profiles_disabled` marker as an explicit portable-mode opt-in.
- Avoid writing mutable files into `Program Files` during normal profile-mode use.

### Display

- Support Windows 11 DPI awareness.
- Use Per-Monitor-V2 DPI behavior for native Win32 UI.
- Preserve correct aspect ratio.
- Add 1920x1080, 2560x1440 and 3840x2160 support where the engine path allows it.
- Prefer borderless fullscreen as an additional option, not as a forced replacement for existing modes.
- High-refresh-rate support must not change gameplay speed or simulation timing.

### Input

- Mouse aiming must feel correct at modern DPI values.
- Preserve configurable sensitivity and inversion.
- Keep keyboard bindings fully remappable.
- Improve Xbox-compatible/XInput-style controller defaults where possible through the existing SDL input layer.
- Controller hot-plugging is desirable but must not destabilize keyboard/mouse input.

### Audio

- Prefer supported modern Windows audio paths already exposed by JFAudioLib/SDL.
- Do not make gameplay depend on legacy MIDI hardware.
- Preserve original sound-effect behavior and music compatibility.

## Stage 3 display controls

The patched JFBuild layer recognizes these optional process environment variables:

```text
SW_DISPLAY_MODE=windowed|fullscreen|borderless
SW_MONITOR=<zero-based SDL display index>
SW_VSYNC=-1..8
SW_MAX_REFRESH=<positive Hz value>
```

`borderless` forces SDL desktop fullscreen at the selected monitor's native desktop resolution. `fullscreen` preserves the original exclusive fullscreen path. `windowed` forces a normal window. If `SW_DISPLAY_MODE` is absent, the original game configuration remains in control.

`SW_MAX_REFRESH` applies to exclusive fullscreen mode enumeration. Borderless mode follows the Windows desktop refresh rate.

## Architecture rules

1. **Preserve gameplay first.**
   Do not change weapon damage, enemy AI, movement speed, map logic, RNG behavior or game timing unless the task explicitly requires it.

2. **Separate platform modernization from gameplay changes.**
   Windows-specific fixes should remain isolated where practical.

3. **Prefer portable code.**
   Do not introduce x86-only assembly into the Windows 11 x64 path.

4. **Keep patches small.**
   Avoid giant refactors that make comparison with upstream difficult.

5. **Do not silently break original data compatibility.**
   Existing `SW.GRP` content and supported expansion data should remain usable.

6. **Do not bundle copyrighted game data.**
   Source code licensing does not make the commercial art, audio, maps or other original data files GPL.

7. **Do not remove GPL notices.**
   Preserve existing copyright and license headers.

8. **Do not rename original upstream authorship away.**
   This project is a Windows 11 modernization of existing open-source work.

## Repository layout

Expected overlay structure:

```text
shadowwarrior-win11-port/
├── Based.md
├── README.md
├── PORTING-NOTES.md
├── APPLY-TO-EXISTING-JFSW.md
├── overlay/
│   ├── Makefile.msvcuser
│   └── rsrc/
│       └── game.manifest
├── patches/
│   ├── 0001-win11-modern-defaults.patch
│   ├── 0002-win11-1080p-default.patch
│   └── 0003-jfbuild-win11-display-modernization.patch
├── launcher/
│   ├── Start-ShadowWarrior.cmd
│   ├── Start-ShadowWarrior.ps1
│   └── README-WINDOWS11.txt
├── docs/
│   ├── DISPLAY-MODERNIZATION.md
│   └── WINDOWS11-TEST-CHECKLIST.md
└── scripts/
    ├── bootstrap-win11.ps1
    ├── build-win11.ps1
    ├── common.ps1
    ├── diagnose-win11.ps1
    ├── package-win11.ps1
    ├── run-win11.ps1
    └── set-portable-mode.ps1
```

The bootstrapped upstream source tree is expected as `jfsw-win11` next to this kit unless the scripts are deliberately changed.

## Build workflow

Typical Windows 11 setup:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\bootstrap-win11.ps1
.\scripts\build-win11.ps1
```

Run with legally obtained data:

```powershell
.\scripts\run-win11.ps1 -GameDataPath "C:\Games\Shadow Warrior"
```

Create an engine-only package:

```powershell
.\scripts\package-win11.ps1
```

A distributable engine package must never copy `SW.GRP` or other commercial assets automatically.

## Development priorities

Work in this order unless a task says otherwise:

### Phase 1: reliable Win11 build

- VS2022 x64 build works from a clean checkout.
- CI succeeds.
- Required runtime DLLs are packaged correctly.
- `sw.exe` launches on current Windows 11.

### Phase 2: filesystem modernization

Status: **baseline behavior verified in upstream**.

- Upstream already changes to a user-writable Windows profile directory for normal runs.
- Keep configuration and saves under `%APPDATA%\JFShadowWarrior` in normal mode.
- Preserve `user_profiles_disabled` as the explicit portable-mode switch.
- Pass legally obtained game data separately through the existing `SWGRP` mechanism.
- Add diagnostics and regression tests around both profile and portable modes.

### Phase 3: display modernization

Status: **implemented in code overlay, hardware validation pending**.

- Fresh-install default raised to 1920x1080/32-bit.
- Windowed, exclusive fullscreen and borderless fullscreen overrides.
- Borderless uses the selected SDL display's desktop mode.
- Monitor selection exposed through `SW_MONITOR`.
- VSync exposed through the existing OpenGL swap interval.
- Exclusive-fullscreen refresh cap exposed through `SW_MAX_REFRESH`.
- Standard mode list expanded through 3840x2160 and common ultrawide resolutions.
- Existing SDL performance-counter timer left unchanged to avoid coupling simulation speed to refresh rate.
- Real 1080p, 1440p, 4K, mixed-DPI and 60/120/144/165 Hz validation is still required.

### Phase 4: input modernization

- modern mouse defaults;
- raw/relative mouse behavior where appropriate;
- Xbox/SDL controller mapping;
- hot-plug support;
- sensible dead zones and remapping UX.

### Phase 5: audio and launcher

- validate Windows 11 audio devices;
- simplify first-run configuration;
- optionally replace the old Win32 startup dialog with a modern launcher or SDL-based UI.

### Phase 6: testing and cleanup

- automated smoke build;
- startup tests with shareware/registered-compatible data layouts where legally possible;
- regression tests for maps, saves and demos;
- compiler-warning cleanup;
- sanitizer/static-analysis passes where practical.

## Definition of done for a Windows 11 release

A release is not considered finished until:

- a clean Windows 11 x64 machine can run it without compatibility mode;
- the build is reproducible from documented dependencies;
- CI produces the same release target;
- game data can be selected without copying proprietary assets into the source repository;
- config and saves work in a user-writable location;
- 1920x1080 works correctly;
- 2560x1440 and 3840x2160 have been tested or explicitly documented as unsupported;
- mouse input is playable at modern DPI values;
- an Xbox-compatible controller is recognized or the limitation is documented;
- audio works through a supported Windows 11 output device;
- GPL notices and source obligations are preserved;
- the package contains no unauthorized Shadow Warrior commercial assets.

## Instructions for AI coding agents

When modifying this project:

1. Read `Based.md`, `README.md` and `PORTING-NOTES.md` first.
2. Inspect the existing implementation before creating a replacement.
3. Prefer fixing the current JFShadowWarrior/JFBuild path over introducing another engine.
4. Keep Windows 11-specific changes minimal and clearly named.
5. Do not invent APIs, source files or build flags. Verify them in the repository.
6. Do not claim a Windows build was tested unless it was actually compiled and run on Windows.
7. When changing build files, update documentation and CI in the same change where appropriate.
8. When changing a default, preserve existing user configuration behavior.
9. Do not add original game assets, extracted data, music, textures, maps, sounds or executables to commits.
10. State any untested assumption explicitly in the commit/PR notes.

## Non-goals

Unless explicitly requested, do not:

- remake Shadow Warrior in Unity, Unreal or another engine;
- convert the game into a browser game;
- replace the Build/JFBuild renderer wholesale;
- alter the original campaign or game balance;
- upscale or replace copyrighted art assets;
- ship a full commercial-game download;
- remove historical author/license attribution.

## Long-term direction

The desired end state is a **native, maintainable Shadow Warrior Windows 11 source port** that behaves like the original game while feeling normal on modern PCs.

Modernize the platform. Preserve the game.
