# Apply to an existing JFShadowWarrior tree

The safest method is still the Stage 3 bootstrap script because it verifies the pinned upstream revision and applies both the game and JFBuild submodule patches in the correct repositories.

```powershell
.\scripts\bootstrap-win11.ps1 -SourceRoot "C:\path\to\jfsw"
.\scripts\build-win11.ps1 -SourceRoot "C:\path\to\jfsw"
```

Patch order:

1. `0001-win11-modern-defaults.patch` in the JFShadowWarrior root.
2. `0002-win11-1080p-default.patch` in the JFShadowWarrior root.
3. `0003-jfbuild-win11-display-modernization.patch` inside the `jfbuild` submodule.

The bootstrap detects patches that are already applied and leaves them in place. It also copies the Win11 MSVC preset and application manifest.
