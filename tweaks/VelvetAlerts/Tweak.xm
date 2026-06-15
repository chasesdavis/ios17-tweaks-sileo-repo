#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDVelvetStyledKey;

static BOOL CDVelvetClassChainContains(UIView *view, NSArray<NSString *> *needles) {
    for (UIView *cursor = view; cursor != nil; cursor = cursor.superview) {
        NSString *className = NSStringFromClass(object_getClass(cursor));
        for (NSString *needle in needles) {
            if ([className rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return YES;
            }
        }
    }
    return NO;
}

static BOOL CDVelvetLooksLikeAlertSurface(UIView *view) {
    if (!view || CGRectGetWidth(view.bounds) < 120.0 || CGRectGetHeight(view.bounds) < 28.0) {
        return NO;
    }
    return CDVelvetClassChainContains(view, @[@"Banner", @"Notification", @"ShortLook", @"Platter", @"NCNotification"]);
}

static void CDVelvetStyle(UIView *view, BOOL entering) {
    if (!view.window || !CDVelvetLooksLikeAlertSurface(view)) {
        return;
    }

    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.cornerRadius = MIN(26.0, MAX(14.0, CGRectGetHeight(view.bounds) * 0.22));
    view.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.36].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    view.layer.shadowRadius = 18.0;
    view.layer.shadowOpacity = 0.28;
    view.layer.masksToBounds = NO;

    if (!entering || objc_getAssociatedObject(view, &kCDVelvetStyledKey)) {
        return;
    }
    objc_setAssociatedObject(view, &kCDVelvetStyledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromTop;
    transition.duration = UIAccessibilityIsReduceMotionEnabled() ? 0.12 : 0.30;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [view.layer addAnimation:transition forKey:@"cd.velvetalerts.enter"];
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDVelvetStyle(self, YES);
}

- (void)layoutSubviews {
    %orig;
    CDVelvetStyle(self, NO);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[VelvetAlerts] loaded");
        %init;
    }
}
