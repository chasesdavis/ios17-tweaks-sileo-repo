#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDAuraDockLayerKey;

static BOOL CDAuraDockClassChainContains(UIView *view, NSString *needle) {
    for (UIView *cursor = view; cursor != nil; cursor = cursor.superview) {
        NSString *className = NSStringFromClass(object_getClass(cursor));
        if ([className rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

static BOOL CDAuraDockIsDockView(UIView *view) {
    NSString *className = NSStringFromClass(object_getClass(view));
    BOOL directDock = [className containsString:@"Dock"];
    BOOL springBoardDock = directDock && ([className containsString:@"SB"] || [className containsString:@"Home"]);
    return springBoardDock || (directDock && CDAuraDockClassChainContains(view, @"IconController"));
}

static NSArray *CDAuraDockColors(void) {
    UIDevice *device = [UIDevice currentDevice];
    CGFloat battery = device.batteryLevel >= 0 ? device.batteryLevel : 0.72;
    UIColor *primary = battery < 0.25
        ? [UIColor colorWithRed:1.00 green:0.22 blue:0.28 alpha:0.40]
        : [UIColor colorWithRed:0.28 green:0.74 blue:1.00 alpha:0.40];
    UIColor *secondary = [UIColor colorWithRed:0.70 green:0.38 blue:1.00 alpha:0.24];
    UIColor *clear = [UIColor clearColor];
    return @[(id)clear.CGColor, (id)primary.CGColor, (id)secondary.CGColor, (id)clear.CGColor];
}

static void CDAuraDockInstall(UIView *dock) {
    if (!dock.window || CGRectIsEmpty(dock.bounds)) {
        return;
    }

    CAGradientLayer *aura = objc_getAssociatedObject(dock, &kCDAuraDockLayerKey);
    if (!aura) {
        aura = [CAGradientLayer layer];
        aura.name = @"com.chasedavis.auradock.glow";
        aura.startPoint = CGPointMake(0.0, 0.5);
        aura.endPoint = CGPointMake(1.0, 0.5);
        aura.locations = @[@0.00, @0.35, @0.70, @1.00];
        aura.opacity = 0.78;
        aura.masksToBounds = NO;
        [dock.layer insertSublayer:aura atIndex:0];
        objc_setAssociatedObject(dock, &kCDAuraDockLayerKey, aura, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat insetX = MAX(12.0, CGRectGetWidth(dock.bounds) * 0.04);
    aura.frame = CGRectInset(dock.bounds, -insetX, -10.0);
    aura.cornerRadius = MIN(36.0, CGRectGetHeight(aura.bounds) * 0.48);
    aura.colors = CDAuraDockColors();
    aura.shadowColor = [UIColor colorWithRed:0.35 green:0.74 blue:1.0 alpha:0.55].CGColor;
    aura.shadowOffset = CGSizeZero;
    aura.shadowRadius = 18.0;
    aura.shadowOpacity = 0.70;

    if (![aura animationForKey:@"cd.auradock.pulse"]) {
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pulse.fromValue = @0.42;
        pulse.toValue = @0.86;
        pulse.duration = 2.8;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [aura addAnimation:pulse forKey:@"cd.auradock.pulse"];
    }
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    if (CDAuraDockIsDockView(self)) {
        CDAuraDockInstall(self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (CDAuraDockIsDockView(self)) {
        CDAuraDockInstall(self);
    }
}

%end

%ctor {
    @autoreleasepool {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        NSLog(@"[AuraDock] loaded");
        %init;
    }
}
