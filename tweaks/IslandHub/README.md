# IslandHub

IslandHub is a SpringBoard-only Dynamic Island-style command center for iOS 17 Bootstrap / roothide.

Version `1.0.1-1` is the safe MVP tranche:

- Top Island overlay with compact and expanded states.
- Priority stack for enabled modules.
- Swipe left/right to cycle sections.
- Tap to expand/collapse.
- Long-press to open Command Center section.
- Scene-attached overlay host sized to the Island frame for iOS 17 SpringBoard visibility.
- Theme, glow, size, offset, haptics, and module toggles.
- Safe local Smart Battery card.
- Clipboard card reads clipboard only when the user taps the Clipboard action.
- UI placeholders for AI, Business, Privacy, Inbox, Transfer, Switcher, Emergency, Prayer, Gym, and Habit modules.

Not in v1:

- No credential collection.
- No external AI or business service calls.
- No destructive command execution.
- No hidden notification, clipboard, camera, microphone, or location data exfiltration.
- No private payment, DRM, or account bypass behavior.

Build:

```bash
cd "/Users/chase/ios17 tweaks/tweaks/IslandHub"
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```

Install from the repo package and respring SpringBoard.
