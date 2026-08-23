# Porting notes

## Upstream baseline

The port kit is pinned to JFShadowWarrior commit:

```text
befcdd01afe5151cac2f1dabf0a7256c42537284
```

JFBuild is initialized through the upstream git submodule revision associated with that commit.

## Verified upstream behavior

### User profile path

JFShadowWarrior already has a user-profile path on current platforms. On Windows, the compatibility layer resolves the home/support path through the Windows application-data location. The game creates and changes into `JFShadowWarrior` under that user path for normal runs.

Expected normal Windows path:

```text
%APPDATA%\JFShadowWarrior
```

The marker file:

```text
user_profiles_disabled
```

suppresses that profile-directory change and therefore provides upstream portable behavior. Launchers that depend on the marker must start the process with the engine directory as the current working directory.

### Game-data separation

JFShadowWarrior reads the `SWGRP` environment variable and uses it as the selected GRP path before group scanning. The Win11 scripts use this existing mechanism rather than copying proprietary data into the engine directory.

### Save files

The save code opens `game%d.sav` relative to the game's current working directory. Because normal profile mode changes into the user profile directory, saves naturally follow the profile path. Portable mode intentionally keeps the engine working directory.

## Stage 3 display findings

The JFBuild SDL2 layer already:

- enumerates SDL displays;
- enumerates real fullscreen display modes;
- records refresh rates;
- prefers the highest refresh rate for otherwise duplicate fullscreen modes;
- supports `SDL_WINDOW_FULLSCREEN` for exclusive fullscreen;
- uses `SDL_WINDOW_FULLSCREEN_DESKTOP` for desktop fullscreen in the existing 8-bit path;
- exposes OpenGL swap interval control;
- samples game timing from `SDL_GetPerformanceCounter()` rather than display frames.

Because the timer is independent of `SDL_GL_SwapWindow()`, Stage 3 does not alter simulation timing for high-refresh support.

## Stage 3 implementation

The JFBuild patch adds optional environment-driven display overrides:

```text
SW_DISPLAY_MODE
SW_MONITOR
SW_VSYNC
SW_MAX_REFRESH
```

### Borderless

`SW_DISPLAY_MODE=borderless` uses:

```c
SDL_WINDOW_FULLSCREEN_DESKTOP
```

and the selected display's desktop resolution. It does not call `SDL_SetWindowDisplayMode`, avoiding a physical monitor mode switch.

### Exclusive fullscreen

`SW_DISPLAY_MODE=fullscreen` retains the original `SDL_WINDOW_FULLSCREEN` path and real SDL display-mode selection.

### Windowed

`SW_DISPLAY_MODE=windowed` clears the fullscreen request while preserving the requested renderer resolution.

### Monitor selection

`SW_MONITOR` is interpreted as a zero-based SDL display index and is range-checked against the display count. Out-of-range values fall back to display 0.

### Refresh cap

`SW_MAX_REFRESH` writes to the existing JFBuild `maxrefreshfreq` filtering mechanism. It applies to enumerated exclusive fullscreen modes.

Borderless mode follows the Windows desktop mode and therefore does not use the exclusive-mode refresh cap.

### VSync

`SW_VSYNC` sets the existing OpenGL swap interval value before the GL mode is created. Supported values follow the existing JFBuild console behavior:

- `0` no synchronization
- `1` normal VSync
- `-1` adaptive VSync when the driver supports it
- positive values through 8 where supported

## Resolution limits

The pinned JFBuild `build.h` defines:

```c
#define MAXXDIM 3840
#define MAXYDIM 2160
```

Stage 3 therefore expands standard mode enumeration up to 3840x2160 but deliberately does not advertise modes above the engine's existing hard maximum.

Added standard profiles include:

- 2560x1080
- 2560x1440
- 3440x1440
- 3840x2160

Real exclusive fullscreen modes are still enumerated directly from SDL and filtered by these engine maximums.

## Runtime validation still required

The source review establishes the intended behavior, but it does not replace Windows hardware testing. Validate:

- 1080p, 1440p and 4K;
- 100%, 125%, 150% and 200% DPI;
- mixed-DPI monitors;
- 60, 120, 144 and 165 Hz;
- Alt+Tab from borderless and exclusive fullscreen;
- mouse capture/release;
- controller hot-plugging;
- save/load paths;
- audio output-device changes.
