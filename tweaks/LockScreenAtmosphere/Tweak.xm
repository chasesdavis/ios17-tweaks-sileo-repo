#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDLockAtmosphereDomain = @"com.chasedavis.lockscreenatmosphere";
static char kCDLockAtmosphereGlowKey;

static UIColor *CDLockAtmosphereTint(void) {
    if (CDPremiumBool(CDLockAtmosphereDomain, @"chargingOverride", YES) && [UIDevice currentDevice].batteryState == UIDeviceBatteryStateCharging) {
        return CDVTColor(112, 229, 168, 0.82);
    }
    return CDPremiumTint(CDLockAtmosphereDomain, CDVTColor(142, 205, 255, 0.72));
}

static void CDLockAtmosphereUpdateGlow(void) {
    UIWindow *window = CDVTKeyWindow();
    if (!CDPremiumBool(CDLockAtmosphereDomain, @"enabled", NO) || !CDPremiumBool(CDLockAtmosphereDomain, @"edgeGlow", YES)) {
        if (window) {
            CDVTRemoveAssociatedView(window, &kCDLockAtmosphereGlowKey);
        }
        return;
    }
    if (!window) {
        return;
    }
    CGFloat opacity = CDPremiumClampedFloat(CDLockAtmosphereDomain, @"glowOpacity", 0.44, 0.05, 0.95);
    CDVTAddEdgeGlow(window, &kCDLockAtmosphereGlowKey, CDLockAtmosphereTint(), @"cd.lockatmosphere.glow", opacity);
}

static void CDLockAtmosphereApplyLabel(UILabel *label) {
    if (!CDPremiumBool(CDLockAtmosphereDomain, @"enabled", NO) || !CDPremiumBool(CDLockAtmosphereDomain, @"tintLabels", YES) || !label.window || !label.text.length || !CDVTClassChainContains(label, @[@"DateView", @"Clock", @"LockScreen", @"CoverSheet"])) {
        return;
    }
    UIColor *tint = CDLockAtmosphereTint();
    CGFloat labelAlpha = CDPremiumClampedFloat(CDLockAtmosphereDomain, @"labelAlpha", 0.92, 0.25, 1.0);
    label.textColor = [tint colorWithAlphaComponent:labelAlpha];
    if (CDPremiumBool(CDLockAtmosphereDomain, @"labelGlow", YES)) {
        label.layer.shadowColor = tint.CGColor;
        label.layer.shadowOffset = CGSizeZero;
        label.layer.shadowRadius = CDPremiumClampedFloat(CDLockAtmosphereDomain, @"labelRadius", 8.0, 0.0, 22.0);
        label.layer.shadowOpacity = CDPremiumClampedFloat(CDLockAtmosphereDomain, @"labelGlowOpacity", 0.54, 0.0, 1.0);
    }
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
