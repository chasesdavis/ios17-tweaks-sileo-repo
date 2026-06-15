#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDIslandCommandDomain = @"com.chasedavis.islandcommandpro";
static char kCDIslandCommandPanelKey;

static NSString *CDIslandCommandSubtitle(void) {
    UIDevice *device = [UIDevice currentDevice];
    NSInteger percent = device.batteryLevel >= 0 ? (NSInteger)lrint(device.batteryLevel * 100.0) : 0;
    NSString *charge = (device.batteryState == UIDeviceBatteryStateCharging || device.batteryState == UIDeviceBatteryStateFull) ? @"Charging" : @"Battery";
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"h:mm a";
    NSInteger mode = CDPremiumInteger(CDIslandCommandDomain, @"subtitleMode", 0);
    if (mode == 1) {
        return [NSString stringWithFormat:@"%@ %ld%%", charge, (long)percent];
    }
    if (mode == 2) {
        return [formatter stringFromDate:[NSDate date]];
    }
    return [NSString stringWithFormat:@"%@ %ld%% - %@", charge, (long)percent, [formatter stringFromDate:[NSDate date]]];
}

static CGFloat CDIslandCommandPanelWidth(void) {
    NSInteger widthMode = CDPremiumInteger(CDIslandCommandDomain, @"panelWidth", 1);
    if (widthMode == 0) {
        return 238.0;
    }
    if (widthMode == 2) {
        return 334.0;
    }
    return 286.0;
}

static void CDIslandCommandShow(void) {
    if (!CDPremiumBool(CDIslandCommandDomain, @"enabled", NO)) {
        return;
    }
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDIslandCommandDomain, CDVTColor(116, 220, 255, 1.0));
    CGFloat yOffset = CDPremiumClampedFloat(CDIslandCommandDomain, @"panelYOffset", 0.0, 0.0, 92.0);
    CGFloat y = MAX(8.0, window.safeAreaInsets.top + 4.0 + yOffset);
    UIVisualEffectView *panel = CDPremiumPanel(window, &kCDIslandCommandPanelKey, @"Island Command", CDIslandCommandSubtitle(), tint, y, CDIslandCommandPanelWidth());
    CGFloat glow = CDPremiumClampedFloat(CDIslandCommandDomain, @"glowStrength", 0.45, 0.0, 1.0);
    CGFloat fill = CDPremiumClampedFloat(CDIslandCommandDomain, @"panelFill", 0.10, 0.02, 0.24);
    panel.layer.shadowColor = tint.CGColor;
    panel.layer.shadowOffset = CGSizeZero;
    panel.layer.shadowRadius = 8.0 + glow * 24.0;
    panel.layer.shadowOpacity = glow * 0.72;
    panel.backgroundColor = [tint colorWithAlphaComponent:fill];
    if (CDPremiumBool(CDIslandCommandDomain, @"pulseEnabled", YES)) {
        CDVTAddPulse(panel.layer, @"cd.islandcommand.panelPulse", 0.82, 1.0, 2.8);
    } else {
        [panel.layer removeAnimationForKey:@"cd.islandcommand.panelPulse"];
    }
}

static void CDIslandCommandAutoHide(void) {
    UIWindow *window = CDVTKeyWindow();
    NSInteger seconds = CDPremiumInteger(CDIslandCommandDomain, @"autoHideSeconds", 5);
    if (seconds <= 0) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDPremiumDismissPanel(window, &kCDIslandCommandPanelKey);
    });
}

static void CDIslandCommandStyleAperture(UIView *view) {
    if (!CDPremiumBool(CDIslandCommandDomain, @"enabled", NO) || !CDPremiumBool(CDIslandCommandDomain, @"styleAperture", YES)) {
        return;
    }
    if (!CDVTLooksLikeSurface(view, @[@"SystemAperture", @"Island", @"Aperture"], 60.0, 20.0, 420.0, 180.0)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDIslandCommandDomain, CDVTColor(116, 220, 255, 1.0));
    CGFloat fill = CDPremiumClampedFloat(CDIslandCommandDomain, @"apertureFill", 0.42, 0.08, 0.70);
    CGFloat shadow = CDPremiumClampedFloat(CDIslandCommandDomain, @"apertureShadow", 0.55, 0.0, 1.0);
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.02 alpha:fill], tint, MIN(30.0, CGRectGetHeight(view.bounds) / 2.0), 6.0 + shadow * 18.0);
}

static void CDIslandCommandNotify(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (CDPremiumBool(CDIslandCommandDomain, @"ringerEvents", YES)) {
            CDIslandCommandShow();
            CDIslandCommandAutoHide();
        }
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        if (CDPremiumBool(CDIslandCommandDomain, @"batteryUpdates", YES)) {
            CDIslandCommandShow();
            CDIslandCommandAutoHide();
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        if (CDPremiumBool(CDIslandCommandDomain, @"enabled", NO) && CDPremiumBool(CDIslandCommandDomain, @"screenshotToast", YES)) {
            CDPremiumToast(@"Island Command", @"Screenshot captured", CDPremiumTint(CDIslandCommandDomain, nil));
        }
    }];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CDIslandCommandNotify, CFSTR("com.apple.springboard.ringerstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (CDPremiumBool(CDIslandCommandDomain, @"startupPanel", YES)) {
            CDIslandCommandShow();
            CDIslandCommandAutoHide();
        }
    });
    NSLog(@"[IslandCommandPro] loaded observers");
}

%end

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDIslandCommandStyleAperture(self);
}

- (void)layoutSubviews {
    %orig;
    CDIslandCommandStyleAperture(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[IslandCommandPro] loaded");
        %init;
    }
}
