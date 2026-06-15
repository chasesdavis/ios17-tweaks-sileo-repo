#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDAutomationsDomain = @"com.chasedavis.springboardautomations";
static char kCDAutomationsPanelKey;

static NSString *CDAutomationsModeName(void) {
    UIDevice *device = [UIDevice currentDevice];
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    CGFloat lowThreshold = CDPremiumClampedFloat(CDAutomationsDomain, @"lowBatteryThreshold", 0.20, 0.05, 0.50);
    if (device.batteryLevel >= 0 && device.batteryLevel < lowThreshold) {
        return @"Low Power Visuals";
    }
    if (device.batteryState == UIDeviceBatteryStateCharging || device.batteryState == UIDeviceBatteryStateFull) {
        return @"Charging Flow";
    }
    if (hour >= 22 || hour < 7) {
        return @"Night Focus";
    }
    return @"Day Profile";
}

static UIColor *CDAutomationsTint(void) {
    if (!CDPremiumBool(CDAutomationsDomain, @"adaptiveColors", YES)) {
        return CDPremiumTint(CDAutomationsDomain, CDVTColor(126, 220, 255, 1.0));
    }
    NSString *mode = CDAutomationsModeName();
    if ([mode containsString:@"Low"]) {
        return CDVTColor(255, 76, 96, 1.0);
    }
    if ([mode containsString:@"Charging"]) {
        return CDVTColor(112, 229, 168, 1.0);
    }
    if ([mode containsString:@"Night"]) {
        return CDVTColor(184, 118, 255, 1.0);
    }
    return CDPremiumTint(CDAutomationsDomain, CDVTColor(126, 220, 255, 1.0));
}

static void CDAutomationsRun(NSString *reason) {
    if (!CDPremiumBool(CDAutomationsDomain, @"enabled", NO)) {
        return;
    }
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }
    NSString *subtitle = [NSString stringWithFormat:@"%@ - %@", CDAutomationsModeName(), reason ?: @"trigger"];
    NSInteger widthMode = CDPremiumInteger(CDAutomationsDomain, @"panelWidth", 1);
    CGFloat width = widthMode == 0 ? 260.0 : (widthMode == 2 ? 344.0 : 310.0);
    UIVisualEffectView *panel = CDPremiumPanel(window, &kCDAutomationsPanelKey, @"SpringBoard Automations", subtitle, CDAutomationsTint(), MAX(70.0, window.safeAreaInsets.top + 54.0), width);
    CGFloat glow = CDPremiumClampedFloat(CDAutomationsDomain, @"panelGlow", 0.46, 0.0, 1.0);
    panel.layer.shadowColor = CDAutomationsTint().CGColor;
    panel.layer.shadowRadius = 8.0 + glow * 20.0;
    panel.layer.shadowOpacity = glow * 0.70;
    NSInteger seconds = CDPremiumInteger(CDAutomationsDomain, @"panelSeconds", 3);
    if (seconds <= 0) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDPremiumDismissPanel(window, &kCDAutomationsPanelKey);
    });
}

static void CDAutomationsDarwinNotify(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *eventName = (__bridge NSString *)name;
        if ([eventName containsString:@"network"] && !CDPremiumBool(CDAutomationsDomain, @"networkTrigger", YES)) {
            return;
        }
        if ([eventName containsString:@"ringerstate"] && !CDPremiumBool(CDAutomationsDomain, @"ringerTrigger", YES)) {
            return;
        }
        CDAutomationsRun(@"system event");
    });
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        if (CDPremiumBool(CDAutomationsDomain, @"batteryTrigger", YES)) {
            CDAutomationsRun(@"battery changed");
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        if (CDPremiumBool(CDAutomationsDomain, @"powerTrigger", YES)) {
            CDAutomationsRun(@"power changed");
        }
    }];
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, CDAutomationsDarwinNotify, CFSTR("com.apple.springboard.ringerstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(center, NULL, CDAutomationsDarwinNotify, CFSTR("com.apple.system.config.network_change"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (CDPremiumBool(CDAutomationsDomain, @"startupTrigger", YES)) {
            CDAutomationsRun(@"startup");
        }
    });
    NSLog(@"[SpringBoardAutomations] trigger engine loaded");
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[SpringBoardAutomations] loaded");
        %init;
    }
}
