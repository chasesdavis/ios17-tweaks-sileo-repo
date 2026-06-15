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
    return [NSString stringWithFormat:@"%@ %ld%% - %@", charge, (long)percent, [formatter stringFromDate:[NSDate date]]];
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
    CGFloat y = MAX(8.0, window.safeAreaInsets.top + 4.0);
    UIVisualEffectView *panel = CDPremiumPanel(window, &kCDIslandCommandPanelKey, @"Island Command", CDIslandCommandSubtitle(), tint, y, 286.0);
    panel.layer.shadowColor = tint.CGColor;
    panel.layer.shadowOffset = CGSizeZero;
    panel.layer.shadowRadius = 16.0;
    panel.layer.shadowOpacity = 0.34;
    CDVTAddPulse(panel.layer, @"cd.islandcommand.panelPulse", 0.82, 1.0, 2.8);
}

static void CDIslandCommandAutoHide(void) {
    UIWindow *window = CDVTKeyWindow();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDPremiumDismissPanel(window, &kCDIslandCommandPanelKey);
    });
}

static void CDIslandCommandStyleAperture(UIView *view) {
    if (!CDPremiumBool(CDIslandCommandDomain, @"enabled", NO)) {
        return;
    }
    if (!CDVTLooksLikeSurface(view, @[@"SystemAperture", @"Island", @"Aperture"], 60.0, 20.0, 420.0, 180.0)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDIslandCommandDomain, CDVTColor(116, 220, 255, 1.0));
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.02 alpha:0.42], tint, MIN(30.0, CGRectGetHeight(view.bounds) / 2.0), 14.0);
}

static void CDIslandCommandNotify(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        CDIslandCommandShow();
        CDIslandCommandAutoHide();
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDIslandCommandShow();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        if (CDPremiumBool(CDIslandCommandDomain, @"enabled", NO)) {
            CDPremiumToast(@"Island Command", @"Screenshot captured", CDPremiumTint(CDIslandCommandDomain, nil));
        }
    }];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CDIslandCommandNotify, CFSTR("com.apple.springboard.ringerstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDIslandCommandShow();
        CDIslandCommandAutoHide();
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
