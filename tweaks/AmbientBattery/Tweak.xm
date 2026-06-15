#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static char kCDAmbientBatteryGlowKey;

static UIColor *CDAmbientBatteryColor(void) {
    CGFloat level = [UIDevice currentDevice].batteryLevel;
    if (level < 0) {
        level = 0.5;
    }
    if (level < 0.20) {
        return CDVTColor(255, 72, 86, 0.78);
    }
    if (level < 0.50) {
        return CDVTColor(255, 178, 72, 0.68);
    }
    return CDVTColor(76, 224, 154, 0.62);
}

static void CDAmbientBatteryUpdate(void) {
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }
    CDVTAddEdgeGlow(window, &kCDAmbientBatteryGlowKey, CDAmbientBatteryColor(), @"cd.ambientbattery.pulse", 0.42);
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDAmbientBatteryUpdate();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDAmbientBatteryUpdate();
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        CDAmbientBatteryUpdate();
    });
    NSLog(@"[AmbientBattery] observers installed");
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[AmbientBattery] loaded");
        %init;
    }
}
