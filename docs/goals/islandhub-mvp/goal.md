# IslandHub MVP Goal

## Goal

Build and publish `IslandHub`, a roothide SpringBoard tweak that turns the top Island area into a configurable command-center style dashboard for UI/UX-only modules.

## Classification

specific

## Non-Negotiable Constraints

- Target Bootstrap / roothide with `THEOS_PACKAGE_SCHEME = roothide`.
- Package id: `com.chasedavis.islandhub`.
- First tranche is UI/UX-only: no credential collection, DRM bypass, payment bypass, hidden data exfiltration, destructive filesystem changes, or privacy bypass behavior.
- Do not break or revert existing pending `IslandInbox` workspace artifacts.
- Publish to the static Sileo repo after build and audit.

## Current Tranche Enough

- New `tweaks/IslandHub` project exists with SpringBoard filter, preferences, README, and roothide package metadata.
- IslandHub renders a top overlay with compact and expanded states.
- The overlay has a priority stack, gesture actions, haptics, and module/theme preferences.
- Real system integration is limited to safe local UI state such as battery level and user-triggered clipboard inspection.
- The package builds for arm64 and arm64e, audits cleanly, and appears in the live Sileo repo.

## Suggested Next Goal

After v1 is installed and tested on-device, create a second tranche for one real integration at a time, starting with notification capture or media state.
