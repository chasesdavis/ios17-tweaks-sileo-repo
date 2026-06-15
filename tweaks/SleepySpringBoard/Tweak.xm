#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDSleepySpringBoardApply(UIView *view) {
    if (UIAccessibilityIsReduceMotionEnabled() || !CDVTLooksLikeSurface(view, @[@"IconView"], 32.0, 32.0, 128.0, 128.0)) {
        return;
    }
    if ([view.layer animationForKey:@"cd.sleepyspringboard.breathe"]) {
        return;
    }
    CABasicAnimation *breathe = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    breathe.fromValue = @0.988;
    breathe.toValue = @1.012;
    breathe.duration = 4.8;
    breathe.autoreverses = YES;
    breathe.repeatCount = HUGE_VALF;
    breathe.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:breathe forKey:@"cd.sleepyspringboard.breathe"];
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDSleepySpringBoardApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDSleepySpringBoardApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[SleepySpringBoard] loaded");
        %init;
    }
}
