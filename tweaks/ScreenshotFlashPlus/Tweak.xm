#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDScreenshotFlashPlusShow(void) {
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }

    UIView *flash = [[UIView alloc] initWithFrame:window.bounds];
    flash.userInteractionEnabled = NO;
    flash.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    flash.backgroundColor = CDVTColor(165, 233, 255, 0.30);

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = flash.bounds;
    gradient.colors = @[(id)CDVTColor(255, 255, 255, 0.70).CGColor, (id)CDVTColor(124, 221, 255, 0.38).CGColor, (id)CDVTColor(186, 112, 255, 0.28).CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    [flash.layer addSublayer:gradient];

    [window addSubview:flash];
    [UIView animateWithDuration:0.36 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        flash.alpha = 0.0;
        flash.transform = CGAffineTransformMakeScale(1.03, 1.03);
    } completion:^(__unused BOOL finished) {
        [flash removeFromSuperview];
    }];
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
        CDScreenshotFlashPlusShow();
    }];
    NSLog(@"[ScreenshotFlashPlus] observer installed");
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[ScreenshotFlashPlus] loaded");
        %init;
    }
}
