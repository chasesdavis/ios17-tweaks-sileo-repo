#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDNotificationForgeDomain = @"com.chasedavis.notificationforge";
static char kCDNotificationForgeStripeKey;

static BOOL CDNotificationForgeQuietHours(void) {
    if (!CDPremiumBool(CDNotificationForgeDomain, @"quietHoursEnabled", YES)) {
        return NO;
    }
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    NSInteger start = CDPremiumInteger(CDNotificationForgeDomain, @"quietStartHour", 22);
    NSInteger end = CDPremiumInteger(CDNotificationForgeDomain, @"quietEndHour", 7);
    return start > end ? (hour >= start || hour < end) : (hour >= start && hour < end);
}

static CGFloat CDNotificationForgeRadius(UIView *view) {
    NSInteger style = CDPremiumInteger(CDNotificationForgeDomain, @"cornerStyle", 0);
    if (style == 1) {
        return 14.0;
    }
    if (style == 2) {
        return 24.0;
    }
    if (style == 3) {
        return CGRectGetHeight(view.bounds) / 2.0;
    }
    return MIN(28.0, MAX(16.0, CGRectGetHeight(view.bounds) * 0.18));
}

static void CDNotificationForgeApply(UIView *view) {
    if (!CDPremiumBool(CDNotificationForgeDomain, @"enabled", NO) || !CDVTLooksLikeSurface(view, @[@"Notification", @"Banner", @"ShortLook", @"Platter"], 120.0, 34.0, 520.0, 260.0)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDNotificationForgeDomain, CDVTColor(255, 110, 146, 1.0));
    BOOL quiet = CDNotificationForgeQuietHours();
    CGFloat fill = CDPremiumClampedFloat(CDNotificationForgeDomain, @"backgroundFill", quiet ? 0.36 : 0.28, 0.06, 0.72);
    CGFloat shadow = CDPremiumClampedFloat(CDNotificationForgeDomain, @"shadowStrength", 0.58, 0.0, 1.0);
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.035 alpha:fill], tint, CDNotificationForgeRadius(view), 4.0 + shadow * 22.0);
    if (quiet && CDPremiumBool(CDNotificationForgeDomain, @"dimQuietBanners", YES)) {
        CGFloat quietAlpha = CDPremiumClampedFloat(CDNotificationForgeDomain, @"quietAlpha", 0.86, 0.35, 1.0);
        view.alpha = MIN(view.alpha, quietAlpha);
    } else {
        CGFloat normalAlpha = CDPremiumClampedFloat(CDNotificationForgeDomain, @"normalAlpha", 0.96, 0.45, 1.0);
        view.alpha = MAX(view.alpha, normalAlpha);
    }

    CALayer *stripe = objc_getAssociatedObject(view, &kCDNotificationForgeStripeKey);
    if (!stripe) {
        stripe = [CALayer layer];
        stripe.name = @"com.chasedavis.notificationforge.priorityLane";
        [view.layer insertSublayer:stripe atIndex:0];
        objc_setAssociatedObject(view, &kCDNotificationForgeStripeKey, stripe, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    stripe.backgroundColor = tint.CGColor;
    stripe.hidden = !CDPremiumBool(CDNotificationForgeDomain, @"priorityStripe", YES);
    stripe.opacity = CDPremiumClampedFloat(CDNotificationForgeDomain, @"stripeOpacity", 0.72, 0.15, 1.0);
    CGFloat stripeWidth = CDPremiumClampedFloat(CDNotificationForgeDomain, @"stripeWidth", 4.0, 2.0, 10.0);
    stripe.frame = CGRectMake(0.0, 10.0, stripeWidth, MAX(18.0, CGRectGetHeight(view.bounds) - 20.0));
    stripe.cornerRadius = stripeWidth / 2.0;
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
