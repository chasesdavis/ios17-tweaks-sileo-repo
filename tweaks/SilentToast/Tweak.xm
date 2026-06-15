#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDSilentToastViewKey;

static UIWindow *CDSilentToastWindow(void) {
    UIApplication *application = [UIApplication sharedApplication];
    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return application.windows.firstObject;
}

static void CDSilentToastPresent(NSString *message) {
    UIWindow *window = CDSilentToastWindow();
    if (!window) {
        return;
    }

    UIView *oldToast = objc_getAssociatedObject(window, &kCDSilentToastViewKey);
    [oldToast removeFromSuperview];

    UIVisualEffectView *toast = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    toast.userInteractionEnabled = NO;
    toast.layer.cornerCurve = kCACornerCurveContinuous;
    toast.layer.cornerRadius = 18.0;
    toast.layer.masksToBounds = YES;
    toast.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    [toast.contentView addSubview:label];

    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 48.0, 210.0);
    CGFloat height = 38.0;
    CGFloat x = (CGRectGetWidth(window.bounds) - width) / 2.0;
    CGFloat y = MAX(54.0, window.safeAreaInsets.top + 14.0);
    toast.frame = CGRectMake(x, y, width, height);
    label.frame = toast.contentView.bounds;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toast.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;

    [window addSubview:toast];
    objc_setAssociatedObject(window, &kCDSilentToastViewKey, toast, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [UIView animateWithDuration:0.18 animations:^{
        toast.alpha = 1.0;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.20 animations:^{
                toast.alpha = 0.0;
                toast.transform = CGAffineTransformMakeTranslation(0.0, -8.0);
            } completion:^(__unused BOOL done) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

static void CDSilentToastNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        CDSilentToastPresent(@"Silent state changed");
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, CDSilentToastNotification, CFSTR("com.apple.springboard.ringerstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(center, NULL, CDSilentToastNotification, CFSTR("com.apple.springboard.silentmode"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    NSLog(@"[SilentToast] observers installed");
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[SilentToast] loaded");
        %init;
    }
}
