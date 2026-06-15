#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDKineticBadgeLastPulseKey;

static BOOL CDKineticBadgeLooksLikeBadge(UIView *view) {
    if (!view || CGRectGetWidth(view.bounds) > 58.0 || CGRectGetHeight(view.bounds) > 58.0) {
        return NO;
    }

    for (UIView *cursor = view; cursor != nil; cursor = cursor.superview) {
        NSString *className = NSStringFromClass(object_getClass(cursor));
        if ([className rangeOfString:@"Badge" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

static void CDKineticBadgeAnimate(UIView *badge) {
    if (!badge.window || badge.hidden || badge.alpha < 0.05 || !CDKineticBadgeLooksLikeBadge(badge)) {
        return;
    }

    NSNumber *lastPulse = objc_getAssociatedObject(badge, &kCDKineticBadgeLastPulseKey);
    CFTimeInterval now = CACurrentMediaTime();
    if (lastPulse && now - lastPulse.doubleValue < 0.35) {
        return;
    }
    objc_setAssociatedObject(badge, &kCDKineticBadgeLastPulseKey, @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [badge.layer removeAnimationForKey:@"cd.kineticbadges.pop"];

    if (UIAccessibilityIsReduceMotionEnabled()) {
        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fade.fromValue = @0.65;
        fade.toValue = @1.0;
        fade.duration = 0.18;
        [badge.layer addAnimation:fade forKey:@"cd.kineticbadges.pop"];
        return;
    }

    CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scale.values = @[@0.92, @1.28, @0.96, @1.0];
    scale.keyTimes = @[@0.0, @0.45, @0.78, @1.0];
    scale.duration = 0.42;
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [badge.layer addAnimation:scale forKey:@"cd.kineticbadges.pop"];
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDKineticBadgeAnimate(self);
}

- (void)setHidden:(BOOL)hidden {
    %orig(hidden);
    if (!hidden) {
        CDKineticBadgeAnimate(self);
    }
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (alpha > 0.05) {
        CDKineticBadgeAnimate(self);
    }
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[KineticBadges] loaded");
        %init;
    }
}
