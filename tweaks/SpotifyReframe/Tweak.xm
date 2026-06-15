#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDSpotifyReframeDomain = @"com.chasedavis.spotifyreframe";
static char kCDSpotifyBackgroundLayerKey;

static BOOL CDSpotifyIsTarget(void) {
    return [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.spotify.client"];
}

static BOOL CDSpotifyEnabled(void) {
    return CDSpotifyIsTarget() && CDPremiumBool(CDSpotifyReframeDomain, @"enabled", NO);
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
    return CDVTClassChainContains(view, @[@"NowPlaying", @"Player", @"MiniPlayer", @"Playback", @"Bar", @"Track"]);
}

static void CDSpotifyApplyRootWash(UIView *view) {
    if (!CDSpotifyEnabled() || !view.window || !CDSpotifyViewIsLargeEnough(view, 260.0, 400.0)) {
        return;
    }
    CGFloat wash = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"backgroundWash", 0.32, 0.0, 0.70);
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
        (id)[tint colorWithAlphaComponent:wash * 0.34].CGColor,
        (id)[UIColor colorWithWhite:0.015 alpha:wash].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor
    ];
    layer.locations = @[@0.0, @0.48, @1.0];
}

static void CDSpotifyApplyCard(UIView *surface) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"glassCards", YES) || !CDSpotifyViewIsLargeEnough(surface, 80.0, 42.0)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat fill = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardFill", 0.28, 0.04, 0.68);
    CGFloat radius = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardRadius", 18.0, 8.0, 30.0);
    CGFloat shadow = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardShadow", 0.42, 0.0, 1.0);
    NSInteger density = CDPremiumInteger(CDSpotifyReframeDomain, @"cardDensity", 1);
    if (density == 0) {
        radius = MIN(radius, 14.0);
        fill *= 0.78;
    } else if (density == 2) {
        radius = MAX(radius, 22.0);
        fill = MIN(fill * 1.16, 0.68);
    }
    surface.backgroundColor = [UIColor colorWithWhite:0.02 alpha:fill];
    CDVTStyleSurface(surface, surface.backgroundColor, tint, radius, 4.0 + shadow * 18.0);
}

static void CDSpotifyApplyArtwork(UIImageView *imageView) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"styleArtwork", YES) || !CDSpotifyViewLooksLikeArtwork(imageView)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat radius = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"artworkRadius", 14.0, 0.0, 28.0);
    CGFloat glow = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"artworkGlow", 0.34, 0.0, 1.0);
    imageView.layer.cornerCurve = kCACornerCurveContinuous;
    imageView.layer.cornerRadius = radius;
    imageView.clipsToBounds = YES;
    imageView.layer.borderColor = [tint colorWithAlphaComponent:glow * 0.62].CGColor;
    imageView.layer.borderWidth = glow > 0.02 ? 1.0 + glow * 1.6 : 0.0;
}

static void CDSpotifyApplyPlayerSurface(UIView *view) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"nowPlayingGlass", YES) || !CDSpotifyViewLooksLikePlayerSurface(view)) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    CGFloat fill = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"cardFill", 0.28, 0.04, 0.68);
    CGFloat glow = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"playerGlow", 0.52, 0.0, 1.0);
    CGFloat radius = MIN(28.0, MAX(14.0, CGRectGetHeight(view.bounds) * 0.24));
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.025 alpha:MIN(fill + 0.12, 0.76)], tint, radius, 5.0 + glow * 20.0);
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
    UIColor *tint = CDSpotifyTint();
    CGFloat fill = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"chromeFill", 0.42, 0.05, 0.82);
    view.tintColor = tint;
    view.backgroundColor = [UIColor colorWithWhite:0.01 alpha:fill];
    view.layer.shadowColor = tint.CGColor;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 12.0;
    view.layer.shadowOpacity = 0.20;
}

static void CDSpotifyApplyLabel(UILabel *label) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"tintPrimaryLabels", YES) || !label.window || label.text.length == 0) {
        return;
    }
    CGFloat fontSize = label.font.pointSize;
    if (fontSize < 13.0 || label.text.length > 80) {
        return;
    }
    if (!CDVTClassChainContains(label, @[@"Cell", @"Header", @"Title", @"NowPlaying", @"Player", @"Album", @"Playlist", @"Track", @"TabBar", @"Navigation"])) {
        return;
    }
    CGFloat strength = CDPremiumClampedFloat(CDSpotifyReframeDomain, @"labelTintStrength", 0.18, 0.0, 0.75);
    if (strength <= 0.01) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    label.textColor = [tint colorWithAlphaComponent:MIN(1.0, 0.35 + strength)];
    label.layer.shadowColor = tint.CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = 2.0 + strength * 7.0;
    label.layer.shadowOpacity = strength * 0.52;
}

static void CDSpotifyApplyControlTint(UIView *view) {
    if (!CDSpotifyEnabled() || !CDPremiumBool(CDSpotifyReframeDomain, @"controlTint", YES) || !view.window) {
        return;
    }
    if (!CDVTClassChainContains(view, @[@"NowPlaying", @"Player", @"Playback", @"TabBar", @"Button", @"Control"])) {
        return;
    }
    UIColor *tint = CDSpotifyTint();
    view.tintColor = tint;
    view.layer.shadowColor = tint.CGColor;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 3.0;
    view.layer.shadowOpacity = 0.26;
}

%hook UIViewController
- (void)viewDidLayoutSubviews {
    %orig;
    CDSpotifyApplyRootWash(self.view);
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
    CDSpotifyApplyPlayerSurface(self);
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
    CDSpotifyApplyArtwork(self);
    CDSpotifyApplyControlTint(self);
}
%end

%hook UIButton
- (void)layoutSubviews {
    %orig;
    CDSpotifyApplyControlTint(self);
}
%end

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    CDSpotifyApplyLabel(self);
}
- (void)layoutSubviews {
    %orig;
    CDSpotifyApplyLabel(self);
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
            %init;
        }
    }
}
