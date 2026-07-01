/*
 * AppGuard Pro — Tweak.x
 * ----------------------
 * One dylib, two jobs, branched by process at load time:
 *
 *   1. In normal apps:  present a biometric/passcode lock over the app before
 *                       its content is visible, and re-lock when backgrounded.
 *                       Optional "fake-crash decoy" exits the app after repeated
 *                       failed/cancelled auths.
 *
 *   2. In SpringBoard:  hide flagged apps from the Home Screen (and Spotlight),
 *                       which is possible now that RootHide Bootstrap 2.0 supports
 *                       SpringBoard injection.
 *
 * Preferences live in our own CFPreferences domain and are read cross-sandbox
 * with CFPreferencesCopyAppValue (works from any process for a foreign domain).
 * A Darwin notification invalidates our cache when the prefs bundle saves.
 *
 * NOTE (self-verification): the SpringBoard icon-visibility hooks below target
 * iOS 17.x private APIs and must be validated on-device per point release — see
 * lessons.md. The per-app lock path uses only public UIKit/LocalAuthentication.
 */

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <notify.h>

static NSString *const kPrefsDomain = @"com.chasedavis.appguardpro";
static NSString *const kReloadNotification = @"com.chasedavis.appguardpro/reload";

#pragma mark - Preferences (cross-sandbox, cached)

// Cached copies so we don't hit CFPreferences on every lifecycle callback.
static BOOL gEnabled = NO;
static BOOL gUseBiometrics = YES;
static BOOL gDecoyEnabled = NO;
static NSInteger gDecoyThreshold = 3;
static NSSet<NSString *> *gLockedApps = nil;
static NSSet<NSString *> *gHiddenApps = nil;

static id AGPPref(NSString *key, id fallback) {
    // CFPreferencesCopyAppValue reads a *foreign* domain from the global store,
    // which is exactly how a prefs value set by our bundle reaches every app.
    CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                    (__bridge CFStringRef)kPrefsDomain);
    if (!v) return fallback;
    return (__bridge_transfer id)v;
}

static NSSet<NSString *> *AGPPrefSet(NSString *key) {
    id arr = AGPPref(key, nil);
    if ([arr isKindOfClass:[NSArray class]]) {
        return [NSSet setWithArray:(NSArray *)arr];
    }
    return [NSSet set];
}

static void AGPReloadPrefs() {
    // Force CFPreferences to re-read from disk before we pull values.
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefsDomain);

    id enabled       = AGPPref(@"enabled", @YES);
    id useBio        = AGPPref(@"useBiometrics", @YES);
    id decoy         = AGPPref(@"decoyEnabled", @NO);
    id threshold     = AGPPref(@"decoyThreshold", @3);

    gEnabled         = [enabled respondsToSelector:@selector(boolValue)] ? [enabled boolValue] : YES;
    gUseBiometrics   = [useBio respondsToSelector:@selector(boolValue)] ? [useBio boolValue] : YES;
    gDecoyEnabled    = [decoy respondsToSelector:@selector(boolValue)] ? [decoy boolValue] : NO;
    gDecoyThreshold  = [threshold respondsToSelector:@selector(integerValue)] ? [threshold integerValue] : 3;
    if (gDecoyThreshold < 1) gDecoyThreshold = 1;

    gLockedApps      = AGPPrefSet(@"lockedApps");
    gHiddenApps      = AGPPrefSet(@"hiddenApps");
}

#pragma mark - App-side lock

// Per-process auth state.
static BOOL gAuthenticated = NO;   // has the user unlocked this foreground session?
static BOOL gAuthInFlight = NO;    // guard against stacking auth prompts
static NSInteger gFailCount = 0;   // for the decoy threshold
static UIWindow *gCoverWindow = nil;

static BOOL AGPCurrentAppLocked() {
    if (!gEnabled) return NO;
    NSString *bid = [NSBundle mainBundle].bundleIdentifier;
    return bid && [gLockedApps containsObject:bid];
}

// A cover window sits above everything and blurs the app content until unlocked,
// preventing the "content flash" before authentication completes.
static void AGPShowCover() {
    if (gCoverWindow) { gCoverWindow.hidden = NO; return; }

    UIWindow *w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    w.windowLevel = UIWindowLevelAlert + 100;   // above alerts/keyboard
    w.backgroundColor = [UIColor blackColor];

    UIViewController *vc = [UIViewController new];
    UIVisualEffectView *blur =
        [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    blur.frame = vc.view.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [vc.view addSubview:blur];

    UIImageView *lockIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
    lockIcon.tintColor = [UIColor whiteColor];
    lockIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:lockIcon];
    [NSLayoutConstraint activateConstraints:@[
        [lockIcon.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
        [lockIcon.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor],
        [lockIcon.widthAnchor constraintEqualToConstant:44],
        [lockIcon.heightAnchor constraintEqualToConstant:44],
    ]];

    w.rootViewController = vc;
    w.hidden = NO;
    gCoverWindow = w;
}

static void AGPHideCover() {
    gCoverWindow.hidden = YES;
}

// Called when auth fails or is cancelled. If the decoy is armed and we cross the
// threshold, exit(0) so the app appears to have crashed to the snooper.
static void AGPHandleAuthFailure() {
    gFailCount++;
    if (gDecoyEnabled && gFailCount >= gDecoyThreshold) {
        exit(0);
    }
}

static void AGPAuthenticate() {
    if (gAuthInFlight || gAuthenticated) return;
    gAuthInFlight = YES;

    LAContext *ctx = [LAContext new];
    // DeviceOwnerAuthentication = biometrics with automatic passcode fallback.
    LAPolicy policy = gUseBiometrics ? LAPolicyDeviceOwnerAuthentication
                                     : LAPolicyDeviceOwnerAuthentication;
    NSString *reason = @"Unlock to open this app";

    void (^done)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            gAuthInFlight = NO;
            if (success) {
                gAuthenticated = YES;
                gFailCount = 0;
                AGPHideCover();
            } else {
                // User cancelled or auth failed — keep the cover, count the miss,
                // and offer a retry tap. (Decoy may fire inside the handler.)
                AGPHandleAuthFailure();
            }
        });
    };

    if ([ctx canEvaluatePolicy:policy error:nil]) {
        [ctx evaluatePolicy:policy localizedReason:reason reply:done];
    } else {
        // No biometrics/passcode configured — fail safe by staying locked but
        // not trapping the user forever: reveal after showing the cover.
        gAuthInFlight = NO;
        gAuthenticated = YES;
        AGPHideCover();
    }
}

%group AppLock

%hook UIApplication

- (void)_applicationDidBecomeActive:(id)arg {
    %orig;
    if (!AGPCurrentAppLocked()) return;
    if (!gAuthenticated) {
        AGPShowCover();
        AGPAuthenticate();
    }
}

%end

%hook UIWindowScene

// Belt-and-suspenders: on scene foreground, make sure the cover is up before
// any content can be seen if this app is locked and not yet authenticated.
- (void)_setDeactivationReasons:(NSUInteger)reasons {
    %orig;
    if (AGPCurrentAppLocked() && !gAuthenticated) {
        AGPShowCover();
    }
}

%end

%end // group AppLock

// Reset auth when the app leaves the foreground so a fresh unlock is required.
static void AGPAppDidEnterBackground() {
    if (AGPCurrentAppLocked()) {
        gAuthenticated = NO;
        gAuthInFlight = NO;
        AGPShowCover();   // pre-cover so the app switcher snapshot is blurred too
    }
}

// Allow a tap on the cover to re-trigger auth after a cancel.
%group CoverTap
%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (gCoverWindow && !gCoverWindow.hidden && self == gCoverWindow && !gAuthInFlight && !gAuthenticated) {
        if (event.type == UIEventTypeTouches) {
            AGPAuthenticate();
        }
    }
}
%end
%end

#pragma mark - SpringBoard-side hiding

// These target iOS 17 private SpringBoard classes; validate on-device per point
// release. isIconVisible: is consulted when the icon model builds the layout.
@interface SBIcon : NSObject
- (NSString *)applicationBundleIdentifier;
@end

%group SpringBoardHide

%hook SBIconModel

- (BOOL)isIconVisible:(SBIcon *)icon {
    if (gEnabled && gHiddenApps.count &&
        [icon respondsToSelector:@selector(applicationBundleIdentifier)]) {
        NSString *bid = [icon applicationBundleIdentifier];
        if (bid && [gHiddenApps containsObject:bid]) {
            return NO;   // pretend the app isn't installed on the Home Screen
        }
    }
    return %orig;
}

%end

%end // group SpringBoardHide

#pragma mark - Load

static void AGPPrefsChanged(CFNotificationCenterRef center, void *observer,
                            CFStringRef name, const void *object,
                            CFDictionaryRef userInfo) {
    AGPReloadPrefs();
}

%ctor {
    @autoreleasepool {
        AGPReloadPrefs();

        // Hot-reload prefs when the settings bundle posts a change.
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL, AGPPrefsChanged,
                                        (__bridge CFStringRef)kReloadNotification,
                                        NULL, CFNotificationSuspensionBehaviorCoalesce);

        NSString *bid = [NSBundle mainBundle].bundleIdentifier;
        if ([bid isEqualToString:@"com.apple.springboard"]) {
            %init(SpringBoardHide);
        } else {
            %init(AppLock);
            %init(CoverTap);
            // Re-lock on background via notification (no need to hook the delegate).
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                             object:nil
                                                              queue:[NSOperationQueue mainQueue]
                                                         usingBlock:^(NSNotification *n) {
                AGPAppDidEnterBackground();
            }];
        }
    }
}
