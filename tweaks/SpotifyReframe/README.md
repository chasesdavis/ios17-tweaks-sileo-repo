# SpotifyReframe

SpotifyReframe is a Spotify-only UI redesign tweak for Bootstrap / roothide.

It targets `com.spotify.client` and keeps behavior visual-only:

- Low-power in-app SpotifyReframe settings panel from a small Spotify-side control.
- Calm defaults that migrate away from the old glow-heavy 1.0.1 profile.
- Subtle playlist, album, and queue card shaping.
- Tunable album-art rounding with a restrained accent stroke.
- Refined tab bar and optional navigation bar treatment.
- Now Playing surface polish without live shadow loops.
- Optional label tinting, debug launch badge, and compatibility force mode.
- PreferenceLoader pane with matching controls.

Build:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```
