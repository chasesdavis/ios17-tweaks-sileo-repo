#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDLockAtmosphereDomain = @"com.chasedavis.lockscreenatmosphere";
static char kCDLockAtmosphereGlowKey;

static UIColor *CDLockAtmosphereTint(void) {
    if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateCharging) {
        return CDVTColor(112, 229, 168, 0.82);
    }
    return CDPremiumTint(CDLockAtmosphereDomain, CDVTColor(142, 205, 255, 0.72));
}

static void CDLockAtmosphereUpdateGlow(void) {
    if (!CDPremiumBool(CDLockAtmosphereDomain, @"enabled", NO)) {
        return;
    }
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }
    CDVTAddEdgeGlow(window, &kCDLockAtmosphereGlowKey, CDLockAtmosphereTint(), @"cd.lockatmosphere.glow", 0.44);
}

static void CDLockAtmosphereApplyLabel(UILabel *label) {
    if (!CDPremiumBool(CDLockAtmosphereDomain, @"enabled", NO) || !label.window || !label.text.length || !CDVTClassChainContains(label, @[@"DateView", @"Clock", @"LockScreen", @"CoverSheet"])) {
        return;
    }
    UIColor *tint = CDLockAtmosphereTint();
    label.textColor = tint;
    label.layer.shadowColor = tint.CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = 8.0;
    label.layer.shadowOpacity = 0.54;
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDLockAtmosphereUpdateGlow();
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDLockAtmosphereUpdateGlow();
    });
    NSLog(@"[LockScreenAtmosphere] observers installed");
}
%end

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    CDLockAtmosphereApplyLabel(self);
}
- (void)setText:(NSString *)text {
    %orig(text);
    CDLockAtmosphereApplyLabel(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[LockScreenAtmosphere] loaded");
        %init;
    }
}
