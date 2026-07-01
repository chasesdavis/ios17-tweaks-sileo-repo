# AppGuard Pro

Per-app **Face ID / passcode lock**, **hidden apps**, and an optional **fake-crash decoy** for iOS 15–17 **RootHide / rootless** (Bootstrap 2.0+).

## Features

- **App Lock** — Require Face ID / Touch ID (with passcode fallback) before a chosen app's content is shown. Re-locks every time the app is backgrounded, and blurs the app-switcher snapshot.
- **Hidden Apps** — Hide chosen apps from the Home Screen (SpringBoard injection, Bootstrap 2.0+).
- **Fake-Crash Decoy (Pro)** — After N failed/cancelled unlocks, the locked app instantly quits so it looks like it crashed.
- **Per-app picker** in Settings (enumerates installed apps via `LSApplicationWorkspace`).

## How it works

A single dylib is injected into every UIKit process (`Filter → com.apple.UIKit`) and branches at load time:

| Process | Behavior |
|---------|----------|
| Normal app | Cover window + `LAContext` auth on `didBecomeActive`; re-lock on background |
| SpringBoard | `SBIconModel isIconVisible:` returns `NO` for hidden bundle IDs |

Preferences live in the `com.chasedavis.appguardpro` CFPreferences domain, read cross-sandbox via `CFPreferencesCopyAppValue`, and hot-reloaded on a Darwin notification (`com.chasedavis.appguardpro/reload`).

## Build

Theos with the bundled iPhoneOS 17.0 SDK (needed for the private `Preferences` framework). Path must contain **no spaces**.

```sh
make package FINALPACKAGE=1
```

Output: `packages/com.chasedavis.appguardpro_1.0.0_iphoneos-arm64.deb` (rootless, installs under `/var/jb`).

## Test plan

See `../lessons.md` and the checklist below — several SpringBoard hooks need on-device validation per iOS 17.x point release.

1. Install `.deb` via Sileo, respring.
2. Settings → AppGuard Pro → enable, add an app to **Locked Apps**. Open it → biometric prompt appears over a blur; unlock reveals content.
3. Background + reopen the app → re-prompts.
4. Add an app to **Hidden Apps** → it disappears from the Home Screen after respring.
5. Enable **Decoy**, set attempts = 2, cancel the prompt twice → app quits.

## Known TODO / polish

- Bundle icon (`icon.png`) not yet included — Sileo shows a default.
- SpringBoard hiding hook (`SBIconModel isIconVisible:`) needs device verification on the exact 17.x build; Spotlight-exclusion hook not yet added.
