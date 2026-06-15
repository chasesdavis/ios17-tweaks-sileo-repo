# SpotifyReframe UIKit Polish

## Objective

Stabilize the visible UIKit AI Home launcher and turn the current static preview into a more polished SpotifyReframe `1.3.0` experience without reintroducing SwiftUI, automatic presentation, or risky Spotify internals.

## Goal Kind

`specific`

## Current Tranche

Confirm the `1.2.1` visible-launcher path, choose a bounded `1.3.0` polish scope, implement it, publish it to the local/static Sileo repo, and leave a safe `1.4.0` integration plan for real visible Spotify content.

## Non-Negotiable Constraints

- Keep the work UI/UX-only.
- Do not add credential collection, DRM bypass, payment bypass, hidden data exfiltration, destructive filesystem changes, or privacy bypass behavior.
- Do not link `SwiftUI.framework` or `libswift` into the Spotify tweak dylib.
- Do not auto-open the full AI Home preview on Spotify launch.
- Keep the feature reversible from Settings.app and in-app controls.
- Keep the package filtered to `com.spotify.client`.
- Preserve Bootstrap / roothide Theos settings:
  - `THEOS_PACKAGE_SCHEME = roothide`
  - `TARGET = iphone:clang:latest:15.0`
  - `ARCHS = arm64 arm64e`

## Stop Rule

Stop when the `1.3.0` polish package builds, audits, publishes, and the board contains a reviewable `1.4.0` integration plan; or stop earlier if device feedback shows the launcher/preview is unstable, verification fails twice, or the next step requires owner input.

## Canonical Board

Machine truth lives at:

`docs/goals/spotifyreframe-uikit-polish/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/spotifyreframe-uikit-polish/goal.md
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Work only on the active board task.
4. Assign Scout, Judge, Worker, or PM according to the task.
5. Write a compact task receipt.
6. Update the board.
7. Select the next active task or finish with a Judge/PM audit receipt.
