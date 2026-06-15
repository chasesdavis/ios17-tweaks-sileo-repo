#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDChargingAuroraViewKey;

static UIWindow *CDChargingAuroraWindow(void) {
    UIApplication *application = [UIApplication sharedApplication];
    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return application.windows.firstObject;
}

static BOOL CDChargingAuroraIsCharging(void) {
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    return state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull;
}

static void CDChargingAuroraUpdate(void) {
    UIWindow *window = CDChargingAuroraWindow();
    if (!window) {
        return;
    }

    UIView *aurora = objc_getAssociatedObject(window, &kCDChargingAuroraViewKey);
    if (!CDChargingAuroraIsCharging()) {
        [aurora removeFromSuperview];
        objc_setAssociatedObject(window, &kCDChargingAuroraViewKey, nil, OBJC_ASSOCIATION_ASSIGN);
        return;
    }

    if (!aurora) {
        aurora = [[UIView alloc] initWithFrame:window.bounds];
        aurora.userInteractionEnabled = NO;
        aurora.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        aurora.backgroundColor = [UIColor clearColor];
        aurora.layer.borderWidth = 3.0;
        aurora.layer.cornerCurve = kCACornerCurveContinuous;
        aurora.layer.cornerRadius = 34.0;
        aurora.layer.borderColor = [UIColor colorWithRed:0.22 green:0.95 blue:0.74 alpha:0.82].CGColor;
        aurora.layer.shadowColor = [UIColor colorWithRed:0.20 green:0.72 blue:1.0 alpha:0.85].CGColor;
        aurora.layer.shadowOffset = CGSizeZero;
        aurora.layer.shadowRadius = 22.0;
        aurora.layer.shadowOpacity = 0.85;
        [window addSubview:aurora];
        objc_setAssociatedObject(window, &kCDChargingAuroraViewKey, aurora, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    aurora.frame = window.bounds;
    [window bringSubviewToFront:aurora];

    if (![aurora.layer animationForKey:@"cd.chargingaurora.pulse"]) {
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pulse.fromValue = @0.28;
        pulse.toValue = @0.82;
        pulse.duration = UIAccessibilityIsReduceMotionEnabled() ? 2.4 : 1.7;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [aurora.layer addAnimation:pulse forKey:@"cd.chargingaurora.pulse"];
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDChargingAuroraUpdate();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDChargingAuroraUpdate();
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        CDChargingAuroraUpdate();
    });
    NSLog(@"[ChargingAurora] observers installed");
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[ChargingAurora] loaded");
        %init;
    }
}
