# Audit

Generated: 2026-06-15T06:29:25Z

## Static Tweak Checks

| Tweak | Roothide | Filter | Package | UI boundary | Deb | Deb contents | Arch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AirplaneComet | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| AmbientBattery | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| AppLaunchEcho | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| AuraDock | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| ChargingAurora | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| ControlGlyphs | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| DimInactivePages | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| DockBadgesOnly | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| GhostDock | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| HaloTouches | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| IconLabelPro | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| KineticBadges | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| LiquidFolders | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| LockGlyph | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| MinimalCC | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| PrismStatus | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| QuietBadges | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| ScreenshotFlashPlus | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| SignalBloom | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| SilentToast | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| SleepySpringBoard | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| SnapGrid | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| SpringTrails | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| VelvetAlerts | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| VolumeRibbon | pass | pass | pass | pass | present | pass | iphoneos-arm64e |
| WallpaperDepthTint | pass | pass | pass | pass | present | pass | iphoneos-arm64e |

## Repo Checks

- pass: repo/Packages
- pass: repo/Packages.gz
- pass: repo/Packages.xz
- pass: repo/Release

## Manual Device Test Order

1. SilentToast
2. IconLabelPro
3. AuraDock
4. KineticBadges
5. VelvetAlerts
6. VolumeRibbon
7. ChargingAurora
8. GhostDock
9. AirplaneComet
10. AmbientBattery
11. AppLaunchEcho
12. ControlGlyphs
13. DimInactivePages
14. DockBadgesOnly
15. HaloTouches
16. LiquidFolders
17. LockGlyph
18. MinimalCC
19. PrismStatus
20. QuietBadges
21. ScreenshotFlashPlus
22. SignalBloom
23. SleepySpringBoard
24. SnapGrid
25. SpringTrails
26. WallpaperDepthTint

Install one tweak at a time, respring, verify SpringBoard stability, then proceed.
