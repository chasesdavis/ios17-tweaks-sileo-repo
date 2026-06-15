# SpotifyReframe

SpotifyReframe is a Spotify-only UI redesign tweak for Bootstrap / roothide.

It targets `com.spotify.client` and keeps behavior visual-only:

- SwiftUI AI home concept inspired by the mockup, enabled by default.
- Concept UI is static mock content for now, with a close button and in-app reopen action.
- Native-first defaults that preserve Spotify's own layout.
- Upgrade migration that disables the older gray-card/glow-heavy settings.
- Minimal album-art rounding as the only default visual polish.
- Low Power Mode enabled by default.
- In-app floating settings button is opt-in to avoid overlapping Spotify controls.
- Experimental cards, player, tab bar, label tinting, debug badge, and force mode remain available from Settings.
- PreferenceLoader pane with matching controls.

Build:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```
