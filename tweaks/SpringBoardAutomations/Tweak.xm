#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDAutomationsDomain = @"com.chasedavis.springboardautomations";
static char kCDAutomationsPanelKey;

static NSString *CDAutomationsModeName(void) {
    UIDevice *device = [UIDevice currentDevice];
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    if (device.batteryLevel >= 0 && device.batteryLevel < 0.20) {
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
    if (!CDPremiumBool(CDAutomationsDomain, @"enabled", YES)) {
        return;
    }
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }
    NSString *subtitle = [NSString stringWithFormat:@"%@ - %@", CDAutomationsModeName(), reason ?: @"trigger"];
    CDPremiumPanel(window, &kCDAutomationsPanelKey, @"SpringBoard Automations", subtitle, CDAutomationsTint(), MAX(70.0, window.safeAreaInsets.top + 54.0), 310.0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDPremiumDismissPanel(window, &kCDAutomationsPanelKey);
    });
}

static void CDAutomationsDarwinNotify(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        CDAutomationsRun(@"system event");
    });
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDAutomationsRun(@"battery changed");
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDAutomationsRun(@"power changed");
    }];
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, CDAutomationsDarwinNotify, CFSTR("com.apple.springboard.ringerstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(center, NULL, CDAutomationsDarwinNotify, CFSTR("com.apple.system.config.network_change"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDAutomationsRun(@"startup");
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
