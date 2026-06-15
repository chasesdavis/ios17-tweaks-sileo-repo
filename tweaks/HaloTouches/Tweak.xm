#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDHaloTouchesAddRipple(UIWindow *window, CGPoint point) {
    if (!window || UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }

    UIView *ripple = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 54, 54)];
    ripple.center = point;
    ripple.userInteractionEnabled = NO;
    ripple.backgroundColor = [UIColor clearColor];
    ripple.layer.cornerRadius = 27.0;
    ripple.layer.borderWidth = 1.6;
    ripple.layer.borderColor = CDVTColor(102, 220, 255, 0.75).CGColor;
    ripple.layer.shadowColor = CDVTColor(156, 92, 255, 0.55).CGColor;
    ripple.layer.shadowRadius = 10.0;
    ripple.layer.shadowOpacity = 0.8;
    [window addSubview:ripple];

    [UIView animateWithDuration:0.42 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        ripple.alpha = 0.0;
        ripple.transform = CGAffineTransformMakeScale(1.85, 1.85);
    } completion:^(__unused BOOL finished) {
        [ripple removeFromSuperview];
    }];
}

%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig(event);
    if (event.type != UIEventTypeTouches) {
        return;
    }
    for (UITouch *touch in event.allTouches) {
        if (touch.phase == UITouchPhaseBegan) {
            CDHaloTouchesAddRipple(self, [touch locationInView:self]);
        }
    }
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[HaloTouches] loaded");
        %init;
    }
}
