#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDNotificationForgeDomain = @"com.chasedavis.notificationforge";
static char kCDNotificationForgeStripeKey;

static BOOL CDNotificationForgeQuietHours(void) {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    return hour >= 22 || hour < 7;
}

static void CDNotificationForgeApply(UIView *view) {
    if (!CDPremiumBool(CDNotificationForgeDomain, @"enabled", YES) || !CDVTLooksLikeSurface(view, @[@"Notification", @"Banner", @"ShortLook", @"Platter"], 120.0, 34.0, 520.0, 260.0)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDNotificationForgeDomain, CDVTColor(255, 110, 146, 1.0));
    CGFloat radius = MIN(28.0, MAX(16.0, CGRectGetHeight(view.bounds) * 0.18));
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.035 alpha:CDNotificationForgeQuietHours() ? 0.36 : 0.28], tint, radius, 16.0);
    view.alpha = CDNotificationForgeQuietHours() ? MIN(view.alpha, 0.86) : MAX(view.alpha, 0.96);

    CALayer *stripe = objc_getAssociatedObject(view, &kCDNotificationForgeStripeKey);
    if (!stripe) {
        stripe = [CALayer layer];
        stripe.name = @"com.chasedavis.notificationforge.priorityLane";
        [view.layer insertSublayer:stripe atIndex:0];
        objc_setAssociatedObject(view, &kCDNotificationForgeStripeKey, stripe, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    stripe.backgroundColor = tint.CGColor;
    stripe.opacity = 0.72;
    stripe.frame = CGRectMake(0.0, 10.0, 4.0, MAX(18.0, CGRectGetHeight(view.bounds) - 20.0));
    stripe.cornerRadius = 2.0;
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDNotificationForgeApply(self);
}
- (void)layoutSubviews {
    %orig;
    CDNotificationForgeApply(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[NotificationForge] loaded");
        %init;
    }
}
