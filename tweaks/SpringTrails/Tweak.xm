#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"

static char kCDSpringTrailsLastTimeKey;

static void CDSpringTrailsDrop(UIView *icon) {
    if (UIAccessibilityIsReduceMotionEnabled() || !icon.superview || !CDVTClassChainContains(icon, @[@"IconView"])) {
        return;
    }

    NSNumber *last = objc_getAssociatedObject(icon, &kCDSpringTrailsLastTimeKey);
    CFTimeInterval now = CACurrentMediaTime();
    if (last && now - last.doubleValue < 0.08) {
        return;
    }
    objc_setAssociatedObject(icon, &kCDSpringTrailsLastTimeKey, @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CGPoint center = [icon.superview convertPoint:CGPointMake(CGRectGetMidX(icon.bounds), CGRectGetMidY(icon.bounds)) fromView:icon];
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    dot.center = center;
    dot.userInteractionEnabled = NO;
    dot.layer.cornerRadius = 6.0;
    dot.backgroundColor = CDVTColor(126, 220, 255, 0.34);
    [icon.superview insertSubview:dot belowSubview:icon];

    [UIView animateWithDuration:0.42 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        dot.alpha = 0.0;
        dot.transform = CGAffineTransformMakeScale(0.35, 0.35);
    } completion:^(__unused BOOL finished) {
        [dot removeFromSuperview];
    }];
}

%hook UIView

- (void)setCenter:(CGPoint)center {
    CGPoint oldCenter = self.center;
    %orig(center);
    if (fabs(oldCenter.x - center.x) > 2.0 || fabs(oldCenter.y - center.y) > 2.0) {
        CDSpringTrailsDrop(self);
    }
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[SpringTrails] loaded");
        %init;
    }
}
