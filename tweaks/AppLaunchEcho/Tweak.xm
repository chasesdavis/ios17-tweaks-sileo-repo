#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDAppLaunchEchoShow(UIView *icon) {
    if (!icon.window || !CDVTClassChainContains(icon, @[@"IconView"])) {
        return;
    }
    CDVTAddPop(icon.layer, @"cd.applaunchecho.pop");

    UIView *ring = [[UIView alloc] initWithFrame:CGRectInset(icon.bounds, -6.0, -6.0)];
    ring.userInteractionEnabled = NO;
    ring.layer.cornerCurve = kCACornerCurveContinuous;
    ring.layer.cornerRadius = 22.0;
    ring.layer.borderWidth = 2.0;
    ring.layer.borderColor = CDVTColor(116, 220, 255, 0.68).CGColor;
    ring.alpha = 0.85;
    [icon addSubview:ring];

    [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        ring.alpha = 0.0;
        ring.transform = CGAffineTransformMakeScale(1.18, 1.18);
    } completion:^(__unused BOOL finished) {
        [ring removeFromSuperview];
    }];
}

%hook UIView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    CDAppLaunchEchoShow(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[AppLaunchEcho] loaded");
        %init;
    }
}
