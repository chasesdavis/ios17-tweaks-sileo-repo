# IslandHub MVP Workflow

Goal:
Build and publish IslandHub, a SpringBoard Dynamic Island-style command center/dashboard tweak for Bootstrap roothide.

Success criteria:
- Creates `tweaks/IslandHub` with Theos roothide build files, SpringBoard filter, PreferenceLoader bundle, and README.
- Implements a UI/UX-only priority Island overlay with compact and expanded states, gestures, haptics, module cards, stack rendering, and theming.
- Avoids credentials, DRM/payment bypass, hidden exfiltration, destructive filesystem actions, and privacy bypass behavior.
- Builds `com.chasedavis.islandhub_1.0.0-1_iphoneos-arm64e.deb`.
- Regenerates repo metadata without breaking existing pending IslandInbox artifacts.
- Pushes `main` and `gh-pages`, then verifies the live hosted deb matches local bytes.

Current context:
- The workspace already contains many roothide Theos tweaks.
- The repo currently has pending IslandInbox source/package/metadata.
- The requested IslandHub scope is large, so this tranche ships the core engine and safe modules only.

Constraints:
- Use `/Users/chase/theos`.
- Use `THEOS_PACKAGE_SCHEME = roothide`, `TARGET = iphone:clang:latest:15.0`, `ARCHS = arm64 arm64e`.
- First tranche is UI/UX-only.
- Do not revert unrelated or user-created changes.

Risks:
- Real notification, privacy sensor, command-center, AI, and business integrations require private APIs or external services and should be split into future tranches.
- SpringBoard overlays can interfere with gestures if hit-testing is too broad.
- Repo metadata can become inconsistent if existing pending debs are not preserved.

Approval required:
- Publishing to the user's repo is explicitly requested.
- No extra approval is needed for normal git push and gh-pages publication in this requested workflow.

Workflow artifact path:
`.workflow/islandhub-mvp/`

Work packets:
- T001 Scout: repo pattern and risk mapping.
- T002 Worker: implement IslandHub source/preferences/package.
- T003 Worker: package and audit local repo.
- T004 Worker: commit, push, publish, verify live repo.
- T999 Judge: completion audit.

Integration policy:
Only merge code that builds locally and keeps repo metadata internally consistent. Preserve pending IslandInbox artifacts.

Verification:
Run plist lint, Theos build, package metadata inspection, `audit-tweaks.sh`, live repo hash verification, and final git status.

Reusable artifacts:
The goal board can seed future IslandHub tranches for notification capture, media state, and real module integrations.
