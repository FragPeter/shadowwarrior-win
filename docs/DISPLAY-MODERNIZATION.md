# Windows 11 display modernization

## Goal

Add modern Windows display behavior without replacing JFBuild's existing SDL2 renderer or changing Shadow Warrior simulation timing.

## Existing JFBuild behavior

The pinned SDL2 layer enumerates physical displays and exclusive fullscreen display modes through SDL. Fullscreen modes carry their refresh rates and duplicate resolutions retain the highest allowed rate.

The existing timer is based on `SDL_GetPerformanceCounter()` and a configured tick rate. Frame swaps therefore do not drive the game clock.

## Stage 3 modes

### Borderless

Recommended Windows 11 default for the packaged launcher.

```text
SW_DISPLAY_MODE=borderless
```

The patch creates a desktop-fullscreen SDL window using the selected monitor's desktop mode. This avoids a monitor mode switch and is suitable for normal Alt+Tab usage.

### Exclusive fullscreen

```text
SW_DISPLAY_MODE=fullscreen
```

Preserves JFBuild's existing exclusive `SDL_WINDOW_FULLSCREEN` path and real SDL display-mode selection.

An optional cap can filter enumerated refresh modes:

```text
SW_MAX_REFRESH=144
```

### Windowed

```text
SW_DISPLAY_MODE=windowed
```

Forces a normal SDL window while retaining the requested game resolution.

### Config-controlled

If `SW_DISPLAY_MODE` is not set, the game's stored configuration determines windowed/fullscreen behavior as before.

## Monitor selection

```text
SW_MONITOR=0
SW_MONITOR=1
```

The index is the zero-based SDL display index. Invalid values fall back to display 0.

## VSync

```text
SW_VSYNC=0
SW_VSYNC=1
SW_VSYNC=-1
```

The patch feeds this into JFBuild's existing OpenGL swap interval before the video mode is established.

## Resolution range

JFBuild's current maximums are 3840x2160. Stage 3 adds common modern standard modes up to that limit, including 2560x1440 and 3840x2160, plus 2560x1080 and 3440x1440 ultrawide profiles.

It does not raise `MAXXDIM` or `MAXYDIM`; doing so would require a broader renderer audit.

## High refresh

No game-timer change is made. This is intentional.

The SDL layer already calculates engine ticks using the high-resolution performance counter independently of frame presentation. A 144 Hz or 165 Hz display can therefore present more frequently without intentionally increasing Shadow Warrior's simulation tick rate.

## Test requirements

Before release, test at minimum:

- 1920x1080 @ 60 and 144 Hz
- 2560x1440 @ 60 and 144/165 Hz
- 3840x2160 @ 60 Hz
- borderless Alt+Tab
- exclusive fullscreen mode switching
- windowed resizing expectations
- first and second monitor selection
- 100%, 125%, 150%, 200% Windows scaling
- mixed-DPI two-monitor setup
- VSync 0 and 1
- adaptive VSync where supported

Do not mark high-refresh or 4K support as hardware-validated until these checks have actually been performed.
