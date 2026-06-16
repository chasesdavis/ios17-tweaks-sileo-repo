#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"
#import "SpotifyReframePlayerView.h"

static NSString *const CDSpotifyReframeDomain = @"com.chasedavis.spotifyreframe";
static char kCDSpotifyBackgroundLayerKey;
static char kCDSpotifyWindowOverlayKey;
static char kCDSpotifyWindowGradientKey;
static char kCDSpotifyLaunchBadgeKey;
static char kCDSpotifySettingsButtonKey;
static char kCDSpotifySettingsPanelKey;
static char kCDSpotifyReframePlayerKey;
static char kCDSpotifyReframePlayerLauncherKey;
static char kCDSpotifyControlProxyKey;
static char kCDSpotifyCardStyleKey;
static char kCDSpotifyArtworkStyleKey;
static char kCDSpotifyPlayerStyleKey;
static char kCDSpotifyChromeStyleKey;
static char kCDSpotifyLabelStyleKey;
static char kCDSpotifyControlStyleKey;
static BOOL kCDSpotifyLaunchBadgeShown = NO;
static NSInteger kCDSpotifyStyleGeneration = 1;
static CFTimeInterval kCDSpotifyLastWindowRefresh = 0.0;

static void CDSpotifyReapplyAllWindows(void);
static void CDSpotifyOpenSettingsPanel(UIWindow *window);
static void CDSpotifyShowReframePlayer(UIWindow *window, BOOL userInitiated);
static void CDSpotifyDismissReframePlayer(UIWindow *window);

@interface CDSpotifyReframeControlProxy : NSObject
@property (nonatomic, copy) void (^handler)(id sender);
- (instancetype)initWithHandler:(void (^)(id sender))handler;
- (void)invoke:(id)sender;
@end

@implementation CDSpotifyReframeControlProxy
- (instancetype)initWithHandler:(void (^)(id sender))handler {
    self = [super init];
    if (self) {
        _handler = [handler copy];
    }
    return self;
}
- (void)invoke:(id)sender {
    if (self.handler) {
        self.handler(sender);
    }
}
@end

static BOOL CDSpotifyIsTarget(void) {
    return [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.spotify.client"];
}

static BOOL CDSpotifyEnabled(void) {
    return CDSpotifyIsTarget() && CDPremiumBool(CDSpotifyReframeDomain, @"enabled", YES);
}

static BOOL CDSpotifyForceVisualMode(void) {
    return CDPremiumBool(CDSpotifyReframeDomain, @"forceVisualMode", NO);
}

static BOOL CDSpotifyLaunchBadgeEnabled(void) {
    return CDPremiumBool(CDSpotifyReframeDomain, @"launchBadge", NO);
}

static BOOL CDSpotifyInAppSettingsEnabled(void) {
    return CDPremiumBool(CDSpotifyReframeDomain, @"inAppSettings", NO);
}

static BOOL CDSpotifyLowPowerMode(void) {
    return CDPremiumBool(CDSpotifyReframeDomain, @"lowPowerMode", YES);
}

static BOOL CDSpotifyReframePlayerEnabled(void) {
    return CDPremiumBool(CDSpotifyReframeDomain, @"reframePlayerEnabled", YES);
}

static BOOL CDSpotifyReframePlayerLauncherEnabled(void) {
    return CDPremiumBool(CDSpotifyReframeDomain, @"reframePlayerLauncher", YES);
}

static NSInteger CDSpotifyReframePlayerLauncherPlacement(void) {
    NSInteger placement = CDPremiumInteger(CDSpotifyReframeDomain, @"reframePlayerPlacement", 0);
    return MIN(MAX(placement, 0), 3);
}

static void CDSpotifySynchronizePreferences(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)CDSpotifyReframeDomain);
}

static void CDSpotifySetPreference(NSString *key, id value) {
    if (!key.length || !value) {
        return;
    }
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)CDSpotifyReframeDomain);
    CDSpotifySynchronizePreferences();
    kCDSpotifyStyleGeneration++;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chasedavis.spotifyreframe/preferences.changed"), NULL, NULL, YES);
}

static void CDSpotifySetPreferenceSilently(NSString *key, id value) {
    if (!key.length || !value) {
        return;
    }
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)CDSpotifyReframeDomain);
}

static NSDictionary<NSString *, id> *CDSpotifyCalmDefaults(void) {
    return @{
        @"enabled": @YES,
        @"lowPowerMode": @YES,
        @"forceVisualMode": @NO,
        @"inAppSettings": @NO,
        @"launchBadge": @NO,
        @"reframePlayerEnabled": @YES,
        @"reframePlayerLauncher": @YES,
        @"reframePlayerPlacement": @0,
        @"palette": @0,
        @"backgroundWash": @0.0,
        @"glassCards": @NO,
        @"cardDensity": @0,
        @"cardFill": @0.0,
        @"cardRadius": @8.0,
        @"cardShadow": @0.0,
        @"styleArtwork": @YES,
        @"artworkRadius": @4.0,
        @"artworkGlow": @0.0,
        @"nowPlayingGlass": @NO,
        @"controlTint": @NO,
        @"playerGlow": @0.0,
        @"tintPrimaryLabels": @NO,
        @"labelTintStrength": @0.0,
        @"tabBarGlass": @NO,
        @"navBarGlass": @NO,
        @"chromeFill": @0.0,
        @"profileVersion": @5
    };
}

static void CDSpotifyMigrateCalmDefaultsIfNeeded(void) {
    CDSpotifySynchronizePreferences();
    NSInteger currentProfile = CDPremiumInteger(CDSpotifyReframeDomain, @"profileVersion", 0);
    if (currentProfile >= 5) {
        return;
    }
    NSDictionary<NSString *, id> *defaults = CDSpotifyCalmDefaults();
    if (currentProfile < 3) {
        for (NSString *key in defaults) {
            CDSpotifySetPreferenceSilently(key, defaults[key]);
        }
    } else {
        BOOL tweakEnabled = CDPremiumBool(CDSpotifyReframeDomain, @"enabled", YES);
        if (tweakEnabled) {
            CDSpotifySetPreferenceSilently(@"reframePlayerEnabled", @YES);
            CDSpotifySetPreferenceSilently(@"reframePlayerLauncher", @YES);
        }
        CFTypeRef existingPlacement = CFPreferencesCopyAppValue(CFSTR("reframePlayerPlacement"), (__bridge CFStringRef)CDSpotifyReframeDomain);
        if (!existingPlacement) {
            CDSpotifySetPreferenceSilently(@"reframePlayerPlacement", @0);
        } else {
            CFRelease(existingPlacement);
        }
        CDSpotifySetPreferenceSilently(@"profileVersion", @5);
    }
    CDSpotifySynchronizePreferences();
    kCDSpotifyStyleGeneration++;
}

static BOOL CDSpotifyShouldApplyStyle(UIView *view, const void *key) {
    if (!view || !key) {
        return NO;
    }
    NSNumber *applied = objc_getAssociatedObject(view, key);
    if (CDSpotifyLowPowerMode() && applied.integerValue == kCDSpotifyStyleGeneration) {
        return NO;
    }
    objc_setAssociatedObject(view, key, @(kCDSpotifyStyleGeneration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return YES;
}

static BOOL CDSpotifyShouldRefreshWindow(void) {
    CFTimeInterval now = CACurrentMediaTime();
    if (now - kCDSpotifyLastWindowRefresh < 0.75) {
        return NO;
    }
    kCDSpotifyLastWindowRefresh = now;
    return YES;
}

static void CDSpotifyAddControlHandler(UIControl *control, UIControlEvents events, void (^handler)(id sender)) {
    if (!control || !handler) {
        return;
    }
    CDSpotifyReframeControlProxy *proxy = [[CDSpotifyReframeControlProxy alloc] initWithHandler:handler];
    NSMutableArray *proxies = objc_getAssociatedObject(control, &kCDSpotifyControlProxyKey);
    if (!proxies) {
        proxies = [NSMutableArray array];
        objc_setAssociatedObject(control, &kCDSpotifyControlProxyKey, proxies, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [proxies addObject:proxy];
    [control addTarget:proxy action:@selector(invoke:) forControlEvents:events];
}

static UIColor *CDSpotifyTint(void) {
    return CDPremiumTint(CDSpotifyReframeDomain, CDVTColor(30, 215, 96, 1.0));
}

static BOOL CDSpotifyViewIsLargeEnough(UIView *view, CGFloat minWidth, CGFloat minHeight) {
    return view && view.window && CGRectGetWidth(view.bounds) >= minWidth && CGRectGetHeight(view.bounds) >= minHeight;
}

static BOOL CDSpotifyViewLooksLikeArtwork(UIImageView *imageView) {
    if (!CDSpotifyViewIsLargeEnough(imageView, 42.0, 42.0) || !imageView.image) {
        return NO;
    }
    CGFloat width = CGRectGetWidth(imageView.bounds);
    CGFloat height = CGRectGetHeight(imageView.bounds);
    if (fabs(width - height) > 10.0 || width > 420.0 || height > 420.0) {
        return NO;
    }
    if (CDSpotifyForceVisualMode()) {
        return YES;
    }
    return CDVTClassChainContains(imageView, @[@"Cell", @"Collection", @"Table", @"NowPlaying", @"Player", @"Album", @"Playlist", @"Track", @"Artwork", @"Cover"]);
}

static BOOL CDSpotifyViewLooksLikePlayerSurface(UIView *view) {
    if (!CDSpotifyViewIsLargeEnough(view, 180.0, 44.0)) {
        return NO;
    }
    CGFloat height = CGRectGetHeight(view.bounds);
    if (height > 220.0) {
        return NO;
    }
    if (CDSpotifyForceVisualMode() && view.window) {
        CGRect frameInWindow = [view.superview convertRect:view.frame toView:view.window];
        CGFloat windowHeight = CGRectGetHeight(view.window.bounds);
        CGFloat windowWidth = CGRectGetWidth(view.window.bounds);
        BOOL isLowerSurface = CGRectGetMinY(frameInWindow) > windowHeight * 0.48;
        BOOL spansUsefulWidth = CGRectGetWidth(frameInWindow) > windowWidth * 0.42;
        BOOL isReasonableHeight = height >= 48.0 && height <= 150.0;
        if (isLowerSurface && spansUsefulWidth && isReasonableHeight) {
            return YES;
        }
    }
    return CDVTClassChainContains(view, @[@"NowPlaying", @"Player", @"MiniPlayer", @"Playback", @"Bar", @"Track"]);
}

static BOOL CDSpotifyWindowIsAppWindow(UIWindow *window) {
    if (!window || window.hidden || CGRectIsEmpty(window.bounds)) {
        return NO;
    }
    NSString *className = NSStringFromClass(object_getClass(window));
    NSArray<NSString *> *blocked = @[@"Keyboard", @"TextEffects", @"RemoteKeyboard", @"Alert", @"StatusBar"];
    for (NSString *needle in blocked) {
        if ([className rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return NO;
        }
    }
    return YES;
}

static void CDSpotifyRemoveWindowOverlay(UIWindow *window) {
    UIView *overlay = objc_getAssociatedObject(window, &kCDSpotifyWindowOverlayKey);
    [overlay removeFromSuperview];
    objc_setAssociatedObject(window, &kCDSpotifyWindowOverlayKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

static void CDSpotifyShowLaunchBadge(UIWindow *window) {
    if (!CDSpotifyLaunchBadgeEnabled() || kCDSpotifyLaunchBadgeShown || !CDSpotifyWindowIsAppWindow(window)) {
        return;
    }
    kCDSpotifyLaunchBadgeShown = YES;

    UIVisualEffectView *badge = objc_getAssociatedObject(window, &kCDSpotifyLaunchBadgeKey);
    if (!badge) {
        badge = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        badge.userInteractionEnabled = NO;
        badge.layer.cornerCurve = kCACornerCurveContinuous;
        badge.layer.cornerRadius = 17.0;
        badge.layer.masksToBounds = YES;
        badge.layer.borderWidth = 1.0;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.tag = 9101;
        label.text = @"SpotifyReframe active";
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
        label.textColor = [UIColor whiteColor];
        [badge.contentView addSubview:label];

        [window addSubview:badge];
        objc_setAssociatedObject(window, &kCDSpotifyLaunchBadgeKey, badge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UIColor *tint = CDSpotifyTint();
    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 52.0, 228.0);
    badge.frame = CGRectMake((CGRectGetWidth(window.bounds) - width) / 2.0, MAX(18.0, window.safeAreaInsets.top + 10.0), width, 34.0);
    badge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    badge.backgroundColor = [tint colorWithAlphaComponent:0.20];
    badge.layer.borderColor = [tint colorWithAlphaComponent:0.50].CGColor;
    badge.alpha = 0.0;

    UILabel *label = [badge.contentView viewWithTag:9101];
    label.frame = badge.contentView.bounds;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window bringSubviewToFront:badge];

    [UIView animateWithDuration:0.18 animations:^{
        badge.alpha = 1.0;
        badge.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.65 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.24 animations:^{
                badge.alpha = 0.0;
                badge.transform = CGAffineTransformMakeTranslation(0.0, -8.0);
            } completion:^(__unused BOOL done) {
                [badge removeFromSuperview];
                objc_setAssociatedObject(window, &kCDSpotifyLaunchBadgeKey, nil, OBJC_ASSOCIATION_ASSIGN);
            }];
        });
    }];
}

static void CDSpotifyDismissReframePlayer(UIWindow *window) {
    if (!window) {
        window = CDVTKeyWindow();
    }
    UIView *player = objc_getAssociatedObject(window, &kCDSpotifyReframePlayerKey);
    if (!player) {
        return;
    }
    [UIView animateWithDuration:0.18 animations:^{
        player.alpha = 0.0;
        if (!CDSpotifyLowPowerMode() && !UIAccessibilityIsReduceMotionEnabled()) {
            player.transform = CGAffineTransformMakeTranslation(0.0, 14.0);
        }
    } completion:^(__unused BOOL finished) {
        [player removeFromSuperview];
        objc_setAssociatedObject(window, &kCDSpotifyReframePlayerKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }];
}

static void CDSpotifyShowReframePlayer(UIWindow *window, BOOL userInitiated) {
    if (!userInitiated || !CDSpotifyEnabled() || !CDSpotifyReframePlayerEnabled() || !CDSpotifyWindowIsAppWindow(window)) {
        return;
    }

    UIView *existing = objc_getAssociatedObject(window, &kCDSpotifyReframePlayerKey);
    if (existing) {
        existing.frame = window.bounds;
        [window bringSubviewToFront:existing];
        return;
    }

    __weak UIWindow *weakWindow = window;
    UIView *player = CDSpotifyCreateReframePlayerView(^{
        CDSpotifyDismissReframePlayer(weakWindow ?: CDVTKeyWindow());
    }, ^{
        UIWindow *targetWindow = weakWindow ?: CDVTKeyWindow();
        CDSpotifyDismissReframePlayer(targetWindow);
        CDSpotifyOpenSettingsPanel(targetWindow);
    });
    player.frame = window.bounds;
    player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    player.alpha = 0.0;
    BOOL reduceMotion = CDSpotifyLowPowerMode() || UIAccessibilityIsReduceMotionEnabled();
    player.transform = reduceMotion ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0.0, 18.0);
    [window addSubview:player];
    objc_setAssociatedObject(window, &kCDSpotifyReframePlayerKey, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [UIView animateWithDuration:reduceMotion ? 0.12 : 0.22 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        player.alpha = 1.0;
        player.transform = CGAffineTransformIdentity;
    } completion:nil];
}

static void CDSpotifyApplyReframePlayerLauncher(UIWindow *window) {
    UIButton *button = objc_getAssociatedObject(window, &kCDSpotifyReframePlayerLauncherKey);
    if (!CDSpotifyIsTarget() || !CDSpotifyEnabled() || !CDSpotifyReframePlayerEnabled() || !CDSpotifyReframePlayerLauncherEnabled() || !CDSpotifyWindowIsAppWindow(window)) {
        [button removeFromSuperview];
        objc_setAssociatedObject(window, &kCDSpotifyReframePlayerLauncherKey, nil, OBJC_ASSOCIATION_ASSIGN);
        if (!CDSpotifyReframePlayerEnabled()) {
            CDSpotifyDismissReframePlayer(window);
        }
        return;
    }

    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.accessibilityLabel = @"Open SpotifyReframe player";
        [button setTitle:@"Player" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBlack];
        button.tintColor = [UIColor blackColor];
        button.backgroundColor = CDSpotifyTint();
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.layer.cornerRadius = 15.0;
        button.layer.borderWidth = 1.0;
        button.layer.shadowColor = CDSpotifyTint().CGColor;
        button.layer.shadowOpacity = 0.18;
        button.layer.shadowRadius = 8.0;
        button.layer.shadowOffset = CGSizeZero;
        CDSpotifyAddControlHandler(button, UIControlEventTouchUpInside, ^(__unused id sender) {
            CDSpotifyShowReframePlayer(window, YES);
        });
        [window addSubview:button];
        objc_setAssociatedObject(window, &kCDSpotifyReframePlayerLauncherKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat width = 74.0;
    CGFloat height = 34.0;
    CGFloat margin = 10.0;
    CGFloat topY = MAX(82.0, window.safeAreaInsets.top + 78.0);
    CGFloat lowerY = MIN(MAX(window.safeAreaInsets.top + 146.0, CGRectGetHeight(window.bounds) * 0.30), CGRectGetHeight(window.bounds) - window.safeAreaInsets.bottom - 210.0);
    NSInteger placement = CDSpotifyReframePlayerLauncherPlacement();
    BOOL left = placement == 1 || placement == 3;
    BOOL lower = placement == 2 || placement == 3;
    CGFloat x = left ? margin : CGRectGetWidth(window.bounds) - width - margin;
    CGFloat y = lower ? lowerY : topY;
    button.frame = CGRectMake(x, y, width, height);
    button.autoresizingMask = (left ? UIViewAutoresizingFlexibleRightMargin : UIViewAutoresizingFlexibleLeftMargin) | UIViewAutoresizingFlexibleBottomMargin;
    button.backgroundColor = CDSpotifyTint();
    button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16].CGColor;
    [window bringSubviewToFront:button];
}

static UILabel *CDSpotifyMakeSettingsLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

static NSString *CDSpotifySliderValueText(CGFloat value, BOOL wholeNumber) {
    return wholeNumber ? [NSString stringWithFormat:@"%.0f", value] : [NSString stringWithFormat:@"%.2f", value];
}

static UIView *CDSpotifyAddSettingsRow(UIScrollView *scrollView, CGFloat *cursorY, NSString *title, NSString *subtitle, CGFloat height) {
    CGFloat inset = 16.0;
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(inset, *cursorY, CGRectGetWidth(scrollView.bounds) - inset * 2.0, height)];
    row.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    row.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.075];
    row.layer.cornerCurve = kCACornerCurveContinuous;
    row.layer.cornerRadius = 14.0;
    row.layer.borderWidth = 1.0;
    row.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;

    UILabel *titleLabel = CDSpotifyMakeSettingsLabel(title, [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold], [UIColor whiteColor]);
    titleLabel.frame = CGRectMake(14.0, subtitle.length ? 10.0 : 0.0, CGRectGetWidth(row.bounds) - 96.0, subtitle.length ? 20.0 : height);
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [row addSubview:titleLabel];

    if (subtitle.length) {
        UILabel *subtitleLabel = CDSpotifyMakeSettingsLabel(subtitle, [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium], [[UIColor whiteColor] colorWithAlphaComponent:0.62]);
        subtitleLabel.frame = CGRectMake(14.0, 30.0, CGRectGetWidth(row.bounds) - 104.0, height - 36.0);
        subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [row addSubview:subtitleLabel];
    }

    [scrollView addSubview:row];
    *cursorY += height + 10.0;
    return row;
}

static void CDSpotifyAddSwitchRow(UIScrollView *scrollView, CGFloat *cursorY, NSString *title, NSString *subtitle, NSString *key, BOOL fallback) {
    UIView *row = CDSpotifyAddSettingsRow(scrollView, cursorY, title, subtitle, subtitle.length ? 62.0 : 52.0);
    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
    toggle.onTintColor = CDSpotifyTint();
    toggle.on = CDPremiumBool(CDSpotifyReframeDomain, key, fallback);
    toggle.frame = CGRectMake(CGRectGetWidth(row.bounds) - 66.0, (CGRectGetHeight(row.bounds) - CGRectGetHeight(toggle.bounds)) / 2.0, CGRectGetWidth(toggle.bounds), CGRectGetHeight(toggle.bounds));
    toggle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    CDSpotifyAddControlHandler(toggle, UIControlEventValueChanged, ^(UISwitch *sender) {
        CDSpotifySetPreference(key, @(sender.on));
        CDSpotifyReapplyAllWindows();
    });
    [row addSubview:toggle];
}

static void CDSpotifyAddSliderRow(UIScrollView *scrollView, CGFloat *cursorY, NSString *title, NSString *key, CGFloat fallback, CGFloat minimum, CGFloat maximum, BOOL wholeNumber) {
    UIView *row = CDSpotifyAddSettingsRow(scrollView, cursorY, title, @"", 78.0);
    UILabel *valueLabel = CDSpotifyMakeSettingsLabel(CDSpotifySliderValueText(CDPremiumClampedFloat(CDSpotifyReframeDomain, key, fallback, minimum, maximum), wholeNumber), [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightSemibold], [CDSpotifyTint() colorWithAlphaComponent:0.92]);
    valueLabel.textAlignment = NSTextAlignmentRight;
    valueLabel.frame = CGRectMake(CGRectGetWidth(row.bounds) - 74.0, 10.0, 58.0, 20.0);
    valueLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [row addSubview:valueLabel];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(14.0, 40.0, CGRectGetWidth(row.bounds) - 28.0, 28.0)];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    slider.minimumValue = minimum;
    slider.maximumValue = maximum;
    slider.value = CDPremiumClampedFloat(CDSpotifyReframeDomain, key, fallback, minimum, maximum);
    slider.minimumTrackTintColor = CDSpotifyTint();
    slider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20];
    CDSpotifyAddControlHandler(slider, UIControlEventValueChanged, ^(UISlider *sender) {
        CGFloat value = wholeNumber ? round(sender.value) : sender.value;
        valueLabel.text = CDSpotifySliderValueText(value, wholeNumber);
        CDSpotifySetPreference(key, @(value));
        CDSpotifyReapplyAllWindows();
    });
    [row addSubview:slider];
}

static void CDSpotifyAddSegmentRow(UIScrollView *scrollView, CGFloat *cursorY, NSString *title, NSString *key, NSArray<NSString *> *items, NSInteger fallback) {
    UIView *row = CDSpotifyAddSettingsRow(scrollView, cursorY, title, @"", 82.0);
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:items];
    segment.selectedSegmentTintColor = CDSpotifyTint();
    segment.selectedSegmentIndex = MIN(MAX(CDPremiumInteger(CDSpotifyReframeDomain, key, fallback), 0), (NSInteger)items.count - 1);
    segment.frame = CGRectMake(14.0, 40.0, CGRectGetWidth(row.bounds) - 28.0, 32.0);
    segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [segment setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [segment setTitleTextAttributes:@{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.72]} forState:UIControlStateNormal];
    CDSpotifyAddControlHandler(segment, UIControlEventValueChanged, ^(UISegmentedControl *sender) {
        CDSpotifySetPreference(key, @(sender.selectedSegmentIndex));
        CDSpotifyReapplyAllWindows();
    });
    [row addSubview:segment];
}

static void CDSpotifyDismissSettingsPanel(UIWindow *window) {
    UIView *panel = objc_getAssociatedObject(window, &kCDSpotifySettingsPanelKey);
    if (!panel) {
        return;
    }
    [UIView animateWithDuration:0.22 animations:^{
        panel.alpha = 0.0;
        panel.transform = CGAffineTransformMakeTranslation(0.0, 18.0);
    } completion:^(__unused BOOL finished) {
        [panel removeFromSuperview];
        objc_setAssociatedObject(window, &kCDSpotifySettingsPanelKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }];
}

static void CDSpotifyOpenSettingsPanel(UIWindow *window) {
    if (!CDSpotifyWindowIsAppWindow(window)) {
        return;
    }
    UIView *existing = objc_getAssociatedObject(window, &kCDSpotifySettingsPanelKey);
    if (existing) {
        [window bringSubviewToFront:existing];
        return;
    }

    UIColor *tint = CDSpotifyTint();
    UIView *container = [[UIView alloc] initWithFrame:window.bounds];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    container.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.42];
    container.alpha = 0.0;

    CGFloat top = MAX(18.0, window.safeAreaInsets.top + 18.0);
    CGFloat bottom = MAX(18.0, window.safeAreaInsets.bottom + 18.0);
    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 24.0, 428.0);
    CGFloat height = MIN(CGRectGetHeight(window.bounds) - top - bottom, 674.0);
    CGRect sheetFrame = CGRectMake((CGRectGetWidth(window.bounds) - width) / 2.0, top, width, height);

    UIVisualEffectView *sheet = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    sheet.frame = sheetFrame;
    sheet.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    sheet.layer.cornerCurve = kCACornerCurveContinuous;
    sheet.layer.cornerRadius = 24.0;
    sheet.layer.masksToBounds = YES;
    sheet.layer.borderWidth = 1.0;
    sheet.layer.borderColor = [tint colorWithAlphaComponent:0.38].CGColor;
    [container addSubview:sheet];

    UILabel *titleLabel = CDSpotifyMakeSettingsLabel(@"SpotifyReframe", [UIFont systemFontOfSize:22.0 weight:UIFontWeightBlack], [UIColor whiteColor]);
    titleLabel.frame = CGRectMake(18.0, 16.0, CGRectGetWidth(sheet.bounds) - 78.0, 28.0);
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [sheet.contentView addSubview:titleLabel];

    UILabel *subtitleLabel = CDSpotifyMakeSettingsLabel(@"In-app tweak settings", [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold], [tint colorWithAlphaComponent:0.86]);
    subtitleLabel.frame = CGRectMake(18.0, 42.0, CGRectGetWidth(sheet.bounds) - 78.0, 18.0);
    subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [sheet.contentView addSubview:subtitleLabel];

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *closeImage = [UIImage systemImageNamed:@"xmark"];
    if (closeImage) {
        [closeButton setImage:closeImage forState:UIControlStateNormal];
    } else {
        [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    }
    closeButton.tintColor = [UIColor whiteColor];
    closeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    closeButton.layer.cornerRadius = 16.0;
    closeButton.frame = CGRectMake(CGRectGetWidth(sheet.bounds) - 50.0, 18.0, 32.0, 32.0);
    closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    CDSpotifyAddControlHandler(closeButton, UIControlEventTouchUpInside, ^(__unused id sender) {
        CDSpotifyDismissSettingsPanel(window);
    });
    [sheet.contentView addSubview:closeButton];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 72.0, CGRectGetWidth(sheet.bounds), CGRectGetHeight(sheet.bounds) - 88.0)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.alwaysBounceVertical = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    [sheet.contentView addSubview:scrollView];

    CGFloat y = 0.0;
    CDSpotifyAddSwitchRow(scrollView, &y, @"Enabled", @"Master switch for all SpotifyReframe visuals.", @"enabled", YES);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Low Power Mode", @"Avoids repeated glow work while scrolling.", @"lowPowerMode", YES);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Force Visual Mode", @"Compatibility fallback; keep off unless normal styling is invisible.", @"forceVisualMode", NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"In-App Settings Button", @"Opt-in floating control. Off by default to avoid Spotify UI overlap.", @"inAppSettings", NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Launch Badge", @"Debug-only load confirmation.", @"launchBadge", NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Reframe Player", @"Custom UIKit shell. It only opens when you tap the launcher.", @"reframePlayerEnabled", YES);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Player Launcher", @"Shows the Player button inside Spotify.", @"reframePlayerLauncher", YES);
    CDSpotifyAddSegmentRow(scrollView, &y, @"Launcher Position", @"reframePlayerPlacement", @[@"Top R", @"Top L", @"Low R", @"Low L"], 0);

    UIView *previewRow = CDSpotifyAddSettingsRow(scrollView, &y, @"Open Reframe Player", @"Turns the player shell on and shows it now.", 74.0);
    UIButton *previewButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [previewButton setTitle:@"Open Player" forState:UIControlStateNormal];
    previewButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBlack];
    previewButton.tintColor = [UIColor blackColor];
    previewButton.backgroundColor = tint;
    previewButton.layer.cornerCurve = kCACornerCurveContinuous;
    previewButton.layer.cornerRadius = 16.0;
    previewButton.frame = CGRectMake(14.0, 34.0, CGRectGetWidth(previewRow.bounds) - 28.0, 32.0);
    previewButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CDSpotifyAddControlHandler(previewButton, UIControlEventTouchUpInside, ^(__unused id sender) {
        CDSpotifySetPreference(@"reframePlayerEnabled", @YES);
        CDSpotifyDismissSettingsPanel(window);
        CDSpotifyShowReframePlayer(window, YES);
        CDSpotifyReapplyAllWindows();
    });
    [previewRow addSubview:previewButton];

    CDSpotifyAddSegmentRow(scrollView, &y, @"Accent Palette", @"palette", @[@"Green", @"Coral", @"Mint", @"Gold", @"Violet"], 0);
    CDSpotifyAddSliderRow(scrollView, &y, @"Background Wash", @"backgroundWash", 0.0, 0.0, 0.30, NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Glass Cards", @"Experimental. Off by default because Spotify cells vary by feed.", @"glassCards", NO);
    CDSpotifyAddSliderRow(scrollView, &y, @"Card Fill", @"cardFill", 0.0, 0.0, 0.26, NO);
    CDSpotifyAddSliderRow(scrollView, &y, @"Card Radius", @"cardRadius", 8.0, 0.0, 20.0, YES);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Album Art Styling", @"Round covers and add a subtle accent stroke.", @"styleArtwork", YES);
    CDSpotifyAddSliderRow(scrollView, &y, @"Artwork Radius", @"artworkRadius", 4.0, 0.0, 18.0, YES);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Now Playing Glass", @"Experimental. Off by default to avoid video and mini-player blocks.", @"nowPlayingGlass", NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Tint Controls", @"Apply the palette to playback controls and icons.", @"controlTint", NO);
    CDSpotifyAddSliderRow(scrollView, &y, @"Player Accent", @"playerGlow", 0.0, 0.0, 0.30, NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Tint Key Labels", @"Accent headings and primary Spotify labels.", @"tintPrimaryLabels", NO);
    CDSpotifyAddSliderRow(scrollView, &y, @"Label Tint", @"labelTintStrength", 0.0, 0.0, 0.35, NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Tab Bar Glass", @"Experimental. Off by default for native Spotify tabs.", @"tabBarGlass", NO);
    CDSpotifyAddSwitchRow(scrollView, &y, @"Navigation Glass", @"Apply tint and shadow to UIKit navigation bars when present.", @"navBarGlass", NO);
    CDSpotifyAddSliderRow(scrollView, &y, @"Chrome Fill", @"chromeFill", 0.0, 0.0, 0.32, NO);

    UIView *buttonRow = CDSpotifyAddSettingsRow(scrollView, &y, @"", @"", 58.0);
    UIButton *disableButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [disableButton setTitle:@"Disable" forState:UIControlStateNormal];
    disableButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    disableButton.tintColor = [UIColor whiteColor];
    disableButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.24 blue:0.32 alpha:0.28];
    disableButton.layer.cornerRadius = 14.0;
    disableButton.frame = CGRectMake(14.0, 14.0, (CGRectGetWidth(buttonRow.bounds) - 42.0) / 2.0, 30.0);
    disableButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    CDSpotifyAddControlHandler(disableButton, UIControlEventTouchUpInside, ^(__unused id sender) {
        CDSpotifySetPreference(@"enabled", @NO);
        CDSpotifyReapplyAllWindows();
        CDSpotifyDismissSettingsPanel(window);
    });
    [buttonRow addSubview:disableButton];

    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    resetButton.tintColor = [UIColor whiteColor];
    resetButton.backgroundColor = [tint colorWithAlphaComponent:0.28];
    resetButton.layer.cornerRadius = 14.0;
    resetButton.frame = CGRectMake(CGRectGetMaxX(disableButton.frame) + 14.0, 14.0, CGRectGetWidth(disableButton.bounds), 30.0);
    resetButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    CDSpotifyAddControlHandler(resetButton, UIControlEventTouchUpInside, ^(__unused id sender) {
        NSDictionary<NSString *, id> *defaults = CDSpotifyCalmDefaults();
        for (NSString *key in defaults) {
            CDSpotifySetPreference(key, defaults[key]);
        }
        CDSpotifyDismissSettingsPanel(window);
        CDSpotifyReapplyAllWindows();
    });
    [buttonRow addSubview:resetButton];

    scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollView.bounds), y + 12.0);
    [window addSubview:container];
    objc_setAssociatedObject(window, &kCDSpotifySettingsPanelKey, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [window bringSubviewToFront:container];

    container.transform = CGAffineTransformMakeTranslation(0.0, 18.0);
    [UIView animateWithDuration:0.24 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        container.alpha = 1.0;
        container.transform = CGAffineTransformIdentity;
    } completion:nil];
}

static void CDSpotifyApplyInAppSettingsButton(UIWindow *window) {
    UIButton *button = objc_getAssociatedObject(window, &kCDSpotifySettingsButtonKey);
    if (!CDSpotifyIsTarget() || !CDSpotifyInAppSettingsEnabled() || !CDSpotifyWindowIsAppWindow(window)) {
        [button removeFromSuperview];
        objc_setAssociatedObject(window, &kCDSpotifySettingsButtonKey, nil, OBJC_ASSOCIATION_ASSIGN);
        return;
    }

    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.accessibilityLabel = @"SpotifyReframe settings";
        button.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.26];
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.layer.cornerRadius = 14.0;
        button.layer.borderWidth = 1.0;
        button.layer.shadowOffset = CGSizeZero;
        button.layer.shadowRadius = 0.0;
        button.layer.shadowOpacity = 0.0;

        UIImage *image = [UIImage systemImageNamed:@"slider.horizontal.3"];
        if (image) {
            [button setImage:image forState:UIControlStateNormal];
        } else {
            [button setTitle:@"RF" forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBlack];
        }
        CDSpotifyAddControlHandler(button, UIControlEventTouchUpInside, ^(__unused id sender) {
            CDSpotifyOpenSettingsPanel(window);
        });
        [window addSubview:button];
        objc_setAssociatedObject(window, &kCDSpotifySettingsButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UIColor *tint = CDSpotifyTint();
    CGFloat size = 28.0;
    button.frame = CGRectMake(CGRectGetWidth(window.bounds) - size - 10.0, MAX(48.0, window.safeAreaInsets.top + 44.0), size, size);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.layer.borderColor = [tint colorWithAlphaComponent:0.18].CGColor;
    button.layer.shadowColor = nil;
    [window bringSubviewToFront:button];
}

static void CDSpotifyApplyWindowOverlay(UIWindow *window) {
    if (!CDSpotifyEnabled() || !CDSpotifyForceVisualMode() || !CDSpotifyWindowIsAppWindow(window)) {
        CDSpotifyRemoveWindowOverlay(window);
        return;
    }

    UIView *overlay = objc_getAssociatedObject(window, &kCDSpotifyWindowOverlayKey);
    if (!overlay) {
        overlay = [[UIView alloc] initWithFrame:window.bounds];
        overlay.userInteractionEnabled = NO;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlay.backgroundColor = [UIColor clearColor];
        overlay.layer.cornerCurve = kCACornerCurveContinuous;
        overlay.layer.cornerRadius = 0.0;
        overlay.layer.borderWidth = 0.0;

        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.name = @"com.chasedavis.spotifyreframe.windowWash";
        gradient.startPoint = CGPointMake(0.18, 0.0);
        gradient.endPoint = CGPointMake(0.86, 1.0);
        [overlay.layer insertSublayer:gradient atIndex:0];
        objc_setAssociatedObject(overlay, &kCDSpotifyWindowGradientKey, gradient, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        [window insertSubview:overlay atIndex:0];
        objc_setAssociatedObject(window, &kCDSpotifyWindowOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UIColor *tint = CDSpotifyTint();
    CGFloat wash = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"backgroundWash", 0.06, 0.0, 0.30);
    CGFloat topAlpha = MIN(0.08, wash * 0.30);
    CGFloat bottomAlpha = MIN(0.06, wash * 0.22);

    overlay.frame = window.bounds;
    overlay.layer.borderColor = [UIColor clearColor].CGColor;
    overlay.layer.shadowColor = nil;
    overlay.layer.shadowOffset = CGSizeZero;
    overlay.layer.shadowRadius = 0.0;
    overlay.layer.shadowOpacity = 0.0;

    CAGradientLayer *gradient = objc_getAssociatedObject(overlay, &kCDSpotifyWindowGradientKey);
    gradient.frame = overlay.bounds;
    gradient.colors = @[
        (id)[tint colorWithAlphaComponent:topAlpha].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
        (id)[tint colorWithAlphaComponent:bottomAlpha].CGColor
    ];
    gradient.locations = @[@0.0, @0.50, @1.0];

    CDSpotifyApplyInAppSettingsButton(window);
    CDSpotifyShowLaunchBadge(window);
}

static void CDSpotifyReapplyAllWindows(void) {
    if (!CDSpotifyIsTarget()) {
        return;
    }
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        CDSpotifyApplyWindowOverlay(window);
        CDSpotifyApplyInAppSettingsButton(window);
        CDSpotifyApplyReframePlayerLauncher(window);
        if (!CDSpotifyReframePlayerEnabled()) {
            CDSpotifyDismissReframePlayer(window);
        }
    }
}

static void CDSpotifyPreferencesChanged(__unused CFNotificationCenterRef center, __unused void *observer, __unused CFStringRef name, __unused const void *object, __unused CFDictionaryRef userInfo) {
    CDSpotifySynchronizePreferences();
    kCDSpotifyStyleGeneration++;
    dispatch_async(dispatch_get_main_queue(), ^{
        CDSpotifyReapplyAllWindows();
    });
}

static void CDSpotifyApplyRootWash(UIView *view) {
    if (!CDSpotifyEnabled() || !view.window || !CDSpotifyViewIsLargeEnough(view, 260.0, 400.0)) {
        return;
    }
    CGFloat wash = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"backgroundWash", 0.06, 0.0, 0.30);
    if (wash <= 0.01) {
        CALayer *oldLayer = objc_getAssociatedObject(view, &kCDSpotifyBackgroundLayerKey);
        [oldLayer removeFromSuperlayer];
        objc_setAssociatedObject(view, &kCDSpotifyBackgroundLayerKey, nil, OBJC_ASSOCIATION_ASSIGN);
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CAGradientLayer *layer = objc_getAssociatedObject(view, &kCDSpotifyBackgroundLayerKey);
    if (!layer) {
        layer = [CAGradientLayer layer];
        layer.name = @"com.chasedavis.spotifyreframe.backgroundWash";
        layer.startPoint = CGPointMake(0.0, 0.0);
        layer.endPoint = CGPointMake(1.0, 1.0);
        [view.layer insertSublayer:layer atIndex:0];
        objc_setAssociatedObject(view, &kCDSpotifyBackgroundLayerKey, layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    layer.frame = view.bounds;
    layer.colors = @[
        (id)[tint colorWithAlphaComponent:wash * 0.16].CGColor,
        (id)[UIColor colorWithWhite:0.015 alpha:wash * 0.28].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor
    ];
    layer.locations = @[@0.0, @0.48, @1.0];
}

static void CDSpotifyApplyCard(UIView *surface) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"glassCards", YES) || !CDSpotifyViewIsLargeEnough(surface, 80.0, 42.0)) {
        return;
    }
    if (!CDSpotifyShouldApplyStyle(surface, &kCDSpotifyCardStyleKey)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat fill = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardFill", 0.08, 0.0, 0.26);
    CGFloat radius = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardRadius", 12.0, 6.0, 20.0);
    CGFloat shadow = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardShadow", 0.0, 0.0, 0.22);
    NSInteger density = CDPremiumInteger(CDSpotifyReframeDomain, @"cardDensity", 0);
    if (density == 0) {
        radius = MIN(radius, 14.0);
        fill *= 0.70;
    } else if (density == 2) {
        radius = MAX(radius, 16.0);
        fill = MIN(fill * 1.10, 0.26);
    }
    surface.backgroundColor = [UIColor colorWithWhite:1.0 alpha:fill];
    surface.layer.cornerCurve = kCACornerCurveContinuous;
    surface.layer.cornerRadius = radius;
    surface.layer.masksToBounds = YES;
    surface.layer.borderColor = [tint colorWithAlphaComponent:0.055 + shadow * 0.10].CGColor;
    surface.layer.borderWidth = fill > 0.01 ? 0.5 : 0.0;
    surface.layer.shadowOpacity = 0.0;
}

static void CDSpotifyApplyArtwork(UIImageView *imageView) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"styleArtwork", YES) || !CDSpotifyViewLooksLikeArtwork(imageView)) {
        return;
    }
    if (!CDSpotifyShouldApplyStyle(imageView, &kCDSpotifyArtworkStyleKey)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat radius = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"artworkRadius", 8.0, 0.0, 18.0);
    CGFloat glow = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"artworkGlow", 0.06, 0.0, 0.30);
    imageView.layer.cornerCurve = kCACornerCurveContinuous;
    imageView.layer.cornerRadius = radius;
    imageView.clipsToBounds = YES;
    imageView.layer.borderColor = [tint colorWithAlphaComponent:glow * 0.45].CGColor;
    imageView.layer.borderWidth = glow > 0.02 ? 0.5 : 0.0;
    imageView.layer.shadowOpacity = 0.0;
}

static void CDSpotifyApplyPlayerSurface(UIView *view) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"nowPlayingGlass", YES) || !CDSpotifyViewLooksLikePlayerSurface(view)) {
        return;
    }
    if (!CDSpotifyShouldApplyStyle(view, &kCDSpotifyPlayerStyleKey)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat fill = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardFill", 0.08, 0.0, 0.26);
    CGFloat glow = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"playerGlow", 0.06, 0.0, 0.30);
    CGFloat radius = MIN(18.0, MAX(10.0, CGRectGetHeight(view.bounds) * 0.18));
    view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:MIN(fill + 0.05, 0.24)];
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
    view.layer.borderColor = [tint colorWithAlphaComponent:glow * 0.38].CGColor;
    view.layer.borderWidth = glow > 0.02 ? 0.5 : 0.0;
    view.layer.shadowOpacity = 0.0;
}

static void CDSpotifyApplyChrome(UIView *view, BOOL navigationBar) {
    if (!CDSpotifyEnabled()) {
        return;
    }
    if (navigationBar && !CDPremiumBool(CDSpotifyReframeDomain, @"navBarGlass", YES)) {
        return;
    }
    if (!navigationBar && !CDPremiumBool(CDSpotifyReframeDomain, @"tabBarGlass", YES)) {
        return;
    }
    if (!CDSpotifyShouldApplyStyle(view, &kCDSpotifyChromeStyleKey)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat fill = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"chromeFill", 0.12, 0.0, 0.32);
    view.tintColor = tint;
    view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:fill];
    view.layer.shadowColor = nil;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 0.0;
    view.layer.shadowOpacity = 0.0;
}

static void CDSpotifyApplyLabel(UILabel *label) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"tintPrimaryLabels", YES) || !label.window || label.text.length == 0) {
        return;
    }
    CGFloat fontSize = label.font.pointSize;
    if (fontSize < 13.0 || label.text.length > 80) {
        return;
    }
    BOOL matchesSpotifySurface = CDVTClassChainContains(label, @[@"Cell", @"Header", @"Title", @"NowPlaying", @"Player", @"Album", @"Playlist", @"Track", @"TabBar", @"Navigation"]);
    if (!matchesSpotifySurface && (!CDSpotifyForceVisualMode() || fontSize < 15.0 || label.text.length > 64)) {
        return;
    }
    if (!CDSpotifyShouldApplyStyle(label, &kCDSpotifyLabelStyleKey)) {
        return;
    }
    CGFloat strength = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"labelTintStrength", 0.0, 0.0, 0.35);
    if (strength <= 0.01) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    label.textColor = [tint colorWithAlphaComponent:MIN(0.78, 0.44 + strength)];
    label.layer.shadowColor = nil;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = 0.0;
    label.layer.shadowOpacity = 0.0;
}

static void CDSpotifyApplyControlTint(UIView *view) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"controlTint", NO) || !view.window) {
        return;
    }
    BOOL isObviousControl = [view isKindOfClass:[UIButton class]] || [view isKindOfClass:[UIImageView class]];
    if (!isObviousControl && !CDVTClassChainContains(view, @[@"NowPlaying", @"Player", @"Playback", @"TabBar", @"Button", @"Control"])) {
        return;
    }
    if (!CDSpotifyShouldApplyStyle(view, &kCDSpotifyControlStyleKey)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    view.tintColor = tint;
    view.layer.shadowColor = nil;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 0.0;
    view.layer.shadowOpacity = 0.0;
}

%hook UIViewController
- (void)viewDidLayoutSubviews {
    %orig;
    if (!CDSpotifyLowPowerMode()) {
        CDSpotifyApplyRootWash(self.view);
    }
}
- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    CDSpotifyApplyRootWash(self.view);
    if (CDSpotifyForceVisualMode()) {
        CDSpotifyApplyWindowOverlay(self.view.window);
    }
    CDSpotifyApplyInAppSettingsButton(self.view.window);
    CDSpotifyApplyReframePlayerLauncher(self.view.window);
}
%end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    if (CDSpotifyForceVisualMode()) {
        CDSpotifyApplyWindowOverlay(self);
    }
    CDSpotifyApplyInAppSettingsButton(self);
    CDSpotifyApplyReframePlayerLauncher(self);
}
- (void)layoutSubviews {
    %orig;
    if (CDSpotifyShouldRefreshWindow()) {
        if (CDSpotifyForceVisualMode()) {
            CDSpotifyApplyWindowOverlay(self);
        }
        CDSpotifyApplyInAppSettingsButton(self);
        CDSpotifyApplyReframePlayerLauncher(self);
    }
}
%end

%hook UITableView
- (void)layoutSubviews {
    %orig;
    if (CDSpotifyEnabled() && CDSpotifyForceVisualMode()) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.03];
        self.separatorColor = [CDSpotifyTint() colorWithAlphaComponent:0.08];
    }
}
%end

%hook UICollectionView
- (void)layoutSubviews {
    %orig;
    if (CDSpotifyEnabled() && CDSpotifyForceVisualMode()) {
        self.backgroundColor = [UIColor clearColor];
    }
}
%end

%hook UITableViewCell
- (void)layoutSubviews {
    %orig;
    CDSpotifyApplyCard(self.contentView ?: self);
}
%end

%hook UICollectionViewCell
- (void)layoutSubviews {
    %orig;
    CDSpotifyApplyCard(self.contentView ?: self);
}
%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDSpotifyApplyPlayerSurface(self);
    CDSpotifyApplyControlTint(self);
}
- (void)layoutSubviews {
    %orig;
    if (!CDSpotifyLowPowerMode()) {
        CDSpotifyApplyPlayerSurface(self);
    }
}
%end

%hook UIImageView
- (void)didMoveToWindow {
    %orig;
    CDSpotifyApplyArtwork(self);
    CDSpotifyApplyControlTint(self);
}
- (void)layoutSubviews {
    %orig;
    if (!CDSpotifyLowPowerMode()) {
        CDSpotifyApplyArtwork(self);
        CDSpotifyApplyControlTint(self);
    }
}
- (void)setImage:(UIImage *)image {
    %orig(image);
    CDSpotifyApplyArtwork(self);
}
%end

%hook UIButton
- (void)layoutSubviews {
    %orig;
    if (!CDSpotifyLowPowerMode()) {
        CDSpotifyApplyControlTint(self);
    }
}
%end

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    CDSpotifyApplyLabel(self);
}
- (void)layoutSubviews {
    %orig;
    if (!CDSpotifyLowPowerMode()) {
        CDSpotifyApplyLabel(self);
    }
}
- (void)setText:(NSString *)text {
    %orig(text);
    CDSpotifyApplyLabel(self);
}
%end

%hook UITabBar
- (void)layoutSubviews {
    %orig;
    CDSpotifyApplyChrome(self, NO);
}
%end

%hook UINavigationBar
- (void)layoutSubviews {
    %orig;
    CDSpotifyApplyChrome(self, YES);
}
%end

%ctor {
    @autoreleasepool {
        if (CDSpotifyIsTarget()) {
            NSLog(@"[SpotifyReframe] loaded");
            CDSpotifyMigrateCalmDefaultsIfNeeded();
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CDSpotifyPreferencesChanged, CFSTR("com.chasedavis.spotifyreframe/preferences.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
            %init;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.85 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CDSpotifyReapplyAllWindows();
            });
        }
    }
}
