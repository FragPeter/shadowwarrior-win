param(
    [Parameter(Mandatory=$true)][string]$SourceRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Replace-Required {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Old,
        [Parameter(Mandatory=$true)][string]$New,
        [Parameter(Mandatory=$true)][string]$Label
    )

    $content = Get-Content $Path -Raw
    if ($content.Contains($New)) {
        Write-Host "Already applied: $Label"
        return
    }

    $count = ([regex]::Matches($content, [regex]::Escape($Old))).Count
    if ($count -ne 1) {
        throw "$Label expected exactly one source anchor but found $count in $Path."
    }

    $content = $content.Replace($Old, $New)
    Set-Content $Path -Value $content -NoNewline -Encoding utf8
    Write-Host "Applied: $Label"
}

$configPath = Join-Path $SourceRoot 'src\config.c'
$jfbuildRoot = Join-Path $SourceRoot 'jfbuild'
$winlayerPath = Join-Path $jfbuildRoot 'src\winlayer.c'
$audioPath = Join-Path $SourceRoot 'jfaudiolib\src\driver_xaudio2.c'

foreach ($path in @($configPath, $winlayerPath, $audioPath)) {
    if (-not (Test-Path $path)) { throw "Required source file not found: $path" }
}

# Fresh-install video and control defaults. Existing user configuration still wins.
Replace-Required $configPath 'int32 ScreenWidth = 640;' 'int32 ScreenWidth = 1920;' '1920 default width'
Replace-Required $configPath 'int32 ScreenHeight = 480;' 'int32 ScreenHeight = 1080;' '1080 default height'
Replace-Required $configPath 'int32 ScreenBPP = 8;' 'int32 ScreenBPP = 32;' '32-bit default colour depth'
Replace-Required $configPath '   ScreenWidth = 640;' '   ScreenWidth = 1920;' '1920 reset width'
Replace-Required $configPath '   ScreenHeight = 480;' '   ScreenHeight = 1080;' '1080 reset height'
Replace-Required $configPath '   ScreenBPP = 8;' '   ScreenBPP = 32;' '32-bit reset colour depth'
Replace-Required $configPath '   CONFIG_SetDefaultKeyDefinitions(CONFIG_DEFAULTS_CLASSIC);' '   CONFIG_SetDefaultKeyDefinitions(CONFIG_DEFAULTS_MODERN);' 'modern keyboard defaults'
Replace-Required $configPath '   CONFIG_SetMouseDefaults(CONFIG_DEFAULTS_CLASSIC);' '   CONFIG_SetMouseDefaults(CONFIG_DEFAULTS_MODERN);' 'modern mouse defaults'
Replace-Required $configPath '   CONFIG_SetJoystickDefaults(CONFIG_DEFAULTS_CLASSIC);' '   CONFIG_SetJoystickDefaults(CONFIG_DEFAULTS_MODERN);' 'modern controller defaults'

# JFAudioLib currently hard-codes Windows 7 immediately before including xaudio2.h.
# The Windows 11 port intentionally targets Windows 10+ so the current Windows SDK XAudio2 header is valid.
Replace-Required $audioPath '#define _WIN32_WINNT _WIN32_WINNT_WIN7' '#define _WIN32_WINNT 0x0A00' 'Windows 10+ XAudio2 target'

# Native Windows JFBuild display overrides. The MSVC build uses winlayer.c, not sdlayer2.c.
$displayGlobalsOld = 'static int backgroundidle = 0;'
$displayGlobalsNew = @'
static int backgroundidle = 0;
enum {
	DISPLAYMODE_CONFIG = -1,
	DISPLAYMODE_WINDOWED = 0,
	DISPLAYMODE_FULLSCREEN = 1,
	DISPLAYMODE_BORDERLESS = 2
};
static int forceddisplaymode = DISPLAYMODE_CONFIG;
static int forceddisplay = -1;
'@
Replace-Required $winlayerPath $displayGlobalsOld $displayGlobalsNew 'Win32 display override state'

$enumDisplaysOld = "`tenumdisplays();"
$enumDisplaysNew = @'
	{
		const char *mode = getenv("SW_DISPLAY_MODE");
		const char *monitor = getenv("SW_MONITOR");
		const char *maxrefresh = getenv("SW_MAX_REFRESH");
#if USE_OPENGL
		const char *vsync = getenv("SW_VSYNC");
#endif

		if (mode && mode[0]) {
			if (!Bstrcasecmp(mode, "windowed"))
				forceddisplaymode = DISPLAYMODE_WINDOWED;
			else if (!Bstrcasecmp(mode, "fullscreen"))
				forceddisplaymode = DISPLAYMODE_FULLSCREEN;
			else if (!Bstrcasecmp(mode, "borderless"))
				forceddisplaymode = DISPLAYMODE_BORDERLESS;
		}

		if (monitor && monitor[0])
			forceddisplay = atoi(monitor);

		if (maxrefresh && maxrefresh[0]) {
			int hz = atoi(maxrefresh);
			if (hz > 0)
				maxrefreshfreq = (unsigned)hz;
		}

#if USE_OPENGL
		if (vsync && vsync[0]) {
			int interval = atoi(vsync);
			if (interval >= -1 && interval <= 8)
				glswapinterval = interval;
		}
#endif
	}

	// Enumerate only after SW_MAX_REFRESH is known so the cap can filter modes.
	enumdisplays();

	if (forceddisplay < 0 || forceddisplay >= displaycnt) {
		if (forceddisplay >= 0)
			buildprintf("Windows 11 display override: monitor %d is unavailable, using primary monitor\n", forceddisplay);
		forceddisplay = forceddisplay >= 0 ? 0 : -1;
	}

	if (forceddisplaymode == DISPLAYMODE_WINDOWED)
		buildputs("Windows 11 display override: windowed mode\n");
	else if (forceddisplaymode == DISPLAYMODE_FULLSCREEN)
		buildputs("Windows 11 display override: exclusive fullscreen\n");
	else if (forceddisplaymode == DISPLAYMODE_BORDERLESS)
		buildputs("Windows 11 display override: borderless fullscreen\n");
	if (forceddisplay >= 0)
		buildprintf("Windows 11 display override: monitor %d\n", forceddisplay);
	if (maxrefreshfreq > 0)
		buildprintf("Windows 11 refresh cap: %u Hz\n", maxrefreshfreq);
#if USE_OPENGL
	if (getenv("SW_VSYNC"))
		buildprintf("Windows 11 OpenGL swap interval: %d\n", glswapinterval);
#endif
'@
Replace-Required $winlayerPath $enumDisplaysOld $enumDisplaysNew 'Win32 display environment parsing'

Replace-Required $winlayerPath "`tint display, modenum;" "`tint display, modenum, borderless = 0;" 'Win32 borderless mode state'

$setVideoEarlyOld = "`tif ((fullsc == fullscreen) && (xdim == xres) && (ydim == yres) && (bitspp == bpp) && !videomodereset) {"
$setVideoEarlyNew = @'
	display = forceddisplay >= 0 ? forceddisplay : (fullsc >> 8);
	if (display < 0 || display >= displaycnt)
		display = 0;

	if (forceddisplaymode == DISPLAYMODE_WINDOWED)
		fullsc = display << 8;
	else if (forceddisplaymode == DISPLAYMODE_FULLSCREEN || forceddisplaymode == DISPLAYMODE_BORDERLESS)
		fullsc = (display << 8) | 1;
	else
		fullsc = (fullsc & 255) | (display << 8);

	borderless = (forceddisplaymode == DISPLAYMODE_BORDERLESS) && (fullsc & 255);
	if (borderless) {
		xdim = displays[display].bounds.right - displays[display].bounds.left;
		ydim = displays[display].bounds.bottom - displays[display].bounds.top;
	}

	if ((fullsc == fullscreen) && (xdim == xres) && (ydim == yres) && (bitspp == bpp) && !videomodereset) {
'@
Replace-Required $winlayerPath $setVideoEarlyOld $setVideoEarlyNew 'Win32 forced display mode selection'

$legacyDisplaySelect = @'
	display = fullsc>>8;
	if (display >= displaycnt) display = 0, fullsc &= 255; // Display number out of range, use primary instead.
'@
Replace-Required $winlayerPath $legacyDisplaySelect '' 'remove legacy duplicate display selection'

$refreshOld = "`telse if (fullsc&255) return -1; // Must be a perfect match for fullscreen."
$refreshNew = @'
	else if (fullsc&255) return -1; // Must be a perfect match for fullscreen.

	if (borderless) {
		DEVMODE dmDesktop;
		ZeroMemory(&dmDesktop, sizeof(DEVMODE));
		dmDesktop.dmSize = sizeof(DEVMODE);
		if (EnumDisplaySettings(displays[display].device, ENUM_CURRENT_SETTINGS, &dmDesktop))
			refresh = dmDesktop.dmDisplayFrequency;
	}
'@
Replace-Required $winlayerPath $refreshOld $refreshNew 'Win32 borderless desktop refresh reporting'

$logOld = "`tif ((fullsc&255) && refresh) str = `"Setting video mode %dx%d (%d-bit fullscreen, display %d, %u Hz)\n`";"
$logNew = @'
	if (borderless && refresh) str = "Setting video mode %dx%d (%d-bit borderless fullscreen, display %d, %u Hz)\n";
	else if (borderless) str = "Setting video mode %dx%d (%d-bit borderless fullscreen, display %d)\n";
	else if ((fullsc&255) && refresh) str = "Setting video mode %dx%d (%d-bit fullscreen, display %d, %u Hz)\n";
'@
Replace-Required $winlayerPath $logOld $logNew 'Win32 borderless mode logging'

$createDeclOld = "`tint winw, winh, winx, winy, vieww, viewh, stylebits = 0, stylebitsex = 0, display;"
$createDeclNew = "`tint winw, winh, winx, winy, vieww, viewh, stylebits = 0, stylebitsex = 0, display, borderless;"
Replace-Required $winlayerPath $createDeclOld $createDeclNew 'Win32 CreateAppWindow borderless state'

$fsMaskOld = "`tfs &= 255;"
$fsMaskNew = @'
	fs &= 255;
	borderless = (forceddisplaymode == DISPLAYMODE_BORDERLESS) && fs;
'@
Replace-Required $winlayerPath $fsMaskOld $fsMaskNew 'Win32 borderless CreateAppWindow detection'

Replace-Required $winlayerPath "`t} else if (bitspp > 8) {" "`t} else if (bitspp > 8 && !borderless) {" 'skip exclusive display switch for borderless'

$winlayer = Get-Content $winlayerPath -Raw
foreach ($required in @('SW_DISPLAY_MODE', 'DISPLAYMODE_BORDERLESS', 'bitspp > 8 && !borderless', 'SW_MAX_REFRESH', 'SW_VSYNC')) {
    if ($winlayer -notmatch [regex]::Escape($required)) { throw "Win32 Stage 3.1 validation failed: $required" }
}

Write-Host 'Windows 11 source transforms applied.'
