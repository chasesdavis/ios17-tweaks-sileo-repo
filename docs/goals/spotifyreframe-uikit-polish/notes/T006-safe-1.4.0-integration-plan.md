# T006 Safe 1.4.0 Integration Plan

## Goal

Feed the UIKit AI Home preview with content already visible in Spotify's rendered UI, while keeping SpotifyReframe UI/UX-only and avoiding private account data, credentials, DRM/payment behavior, hidden scraping, persistence, or background collection.

## Allowed Data Source

Only inspect the current foreground Spotify view hierarchy when the user explicitly opens the AI Home preview.

Allowed:

- Visible `UILabel` text already rendered on screen.
- Visible `UIImageView` artwork already rendered on screen.
- Geometry, visibility, alpha, size, and coarse class-chain hints needed to identify likely title/subtitle/artwork groups.

Not allowed:

- Network requests.
- Spotify API calls.
- Keychain, cookies, auth tokens, databases, caches, files, or account containers.
- Background polling.
- Persistent storage of captured labels/artwork.
- DRM, payment, subscription, ad, or entitlement behavior.
- Hidden views, offscreen cells, or data models behind Spotify UI.

## Candidate Architecture

### 1. Visible Snapshot Provider

Create a small Objective-C module, for example:

```objc
SpotifyVisibleContentSnapshot.h
SpotifyVisibleContentSnapshot.m
```

It exposes one function:

```objc
NSDictionary *CDSpotifyCreateVisibleContentSnapshot(UIWindow *window);
```

The function:

- runs only from the user-initiated preview open path;
- traverses `window.rootViewController.view` and visible subviews;
- ignores hidden/transparent/tiny/offscreen views;
- collects bounded labels and artwork candidates;
- returns plain in-memory data only;
- never writes to disk or preferences.

### 2. Conservative Label Filtering

Collect text from visible `UILabel` instances only when:

- `hidden == NO`;
- `alpha >= 0.20`;
- converted frame intersects the app window bounds;
- text length is between 2 and 80 characters;
- text does not look like a timestamp-only, badge-only, or navigation-only value;
- label is not inside keyboard, alert, status bar, or tweak-owned preview views.

Rank candidates by:

- larger font size;
- left alignment or central content region;
- nearby visible image candidate;
- class-chain hints containing `Cell`, `Track`, `Playlist`, `Album`, `Artist`, `Home`, `Collection`, `Table`, `NowPlaying`, or `Player`.

### 3. Conservative Artwork Filtering

Collect artwork from visible `UIImageView` instances only when:

- image is non-nil;
- view is visible and onscreen;
- size is roughly square;
- size is between 36 and 260 points;
- class-chain hints or geometry suggest cell/playlist/album/player artwork;
- the image is used in-memory only while constructing the preview.

If rendering copied artwork into the preview is unstable, fall back to generated gradient art while still using visible labels.

### 4. Preview Data Contract

Add a lightweight model object or dictionary shape:

```objc
@{
  @"heroTitle": @"Good Vibes, Better Days",
  @"jumpBack": @[
    @{@"title": @"...", @"subtitle": @"...", @"image": imageOrNull}
  ],
  @"nowPlayingTitle": @"...",
  @"nowPlayingSubtitle": @"..."
}
```

The UIKit preview should accept a nullable snapshot:

```objc
UIView *CDSpotifyCreateUIKitHomePreviewView(NSDictionary *snapshot, void (^closeHandler)(void), void (^settingsHandler)(void));
```

If `snapshot == nil` or low confidence, render the current static mock content.

### 5. Settings

Add one opt-in setting:

- `Use Visible Spotify Content`
- default: off for the first 1.4.0 beta-style build
- description: "Uses only labels/artwork already visible on screen when you open the preview."

Keep:

- `AI Home Preview`
- `Show AI Launcher`
- `Launcher Position`

## Risk Controls

- Hard cap collected labels, e.g. 40 labels and 20 images.
- Hard cap traversal depth.
- Run only on main thread and only when opening preview.
- Do not repeat traversal while the preview is open.
- Do not observe Spotify notifications or data models.
- Do not persist snapshots.
- Include a debug-only launch badge/log line behind `Launch Badge`, not always-on logging.
- Provide a single Settings switch to disable visible-content integration instantly.

## Proposed 1.4.0 Tasks

1. Add `SpotifyVisibleContentSnapshot` provider with traversal/filter/ranking logic.
2. Change the UIKit preview factory to accept an optional snapshot dictionary.
3. Populate hero/jump-back/mini-player labels from snapshot when confidence is high.
4. Keep generated gradient artwork fallback for all image slots.
5. Add Settings.app and in-app switch for `Use Visible Spotify Content`, default off.
6. Build and inspect package:
   - no SwiftUI/libswift linkage;
   - filter remains `com.spotify.client`;
   - no filesystem or network APIs added;
   - no private account identifiers in strings.
7. Device-test manually by opening real Spotify Home, Search, Library, and Now Playing before tapping `AI Home`.

## Stop Conditions

Stop and keep static content if:

- traversal causes noticeable lag;
- labels are consistently wrong or private-looking;
- artwork copying causes crashes or memory spikes;
- implementation needs private Spotify model objects;
- any data would need to be stored, sent, or read from non-visible sources.
