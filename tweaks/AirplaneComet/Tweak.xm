#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDAirplaneCometNotify(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        CDVTShowToast(@"Airplane state changed", CDVTColor(120, 220, 255, 1.0));
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, CDAirplaneCometNotify, CFSTR("com.apple.springboard.airplaneModeChanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(center, NULL, CDAirplaneCometNotify, CFSTR("com.apple.system.config.network_change"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    NSLog(@"[AirplaneComet] observers installed");
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[AirplaneComet] loaded");
        %init;
    }
}
