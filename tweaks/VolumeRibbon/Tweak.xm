#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDVolumeRibbonStyledKey;

static BOOL CDVolumeRibbonChainContains(UIView *view, NSArray<NSString *> *needles) {
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

static BOOL CDVolumeRibbonLooksLikeHUD(UIView *view) {
    if (!view || CGRectGetWidth(view.bounds) < 36.0 || CGRectGetHeight(view.bounds) < 8.0) {
        return NO;
    }
    return CDVolumeRibbonChainContains(view, @[@"Volume", @"HUD", @"MediaControlsVolume"]);
}

static void CDVolumeRibbonStyle(UIView *view) {
    if (!view.window || !CDVolumeRibbonLooksLikeHUD(view)) {
        return;
    }

    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.cornerRadius = MIN(18.0, CGRectGetHeight(view.bounds) * 0.50);
    view.layer.masksToBounds = NO;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    view.layer.shadowRadius = 12.0;
    view.layer.shadowOpacity = 0.22;
    if (!view.backgroundColor || CGColorGetAlpha(view.backgroundColor.CGColor) > 0.75) {
        view.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.36];
    }

    if (!objc_getAssociatedObject(view, &kCDVolumeRibbonStyledKey)) {
        objc_setAssociatedObject(view, &kCDVolumeRibbonStyledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        CATransition *transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.duration = UIAccessibilityIsReduceMotionEnabled() ? 0.10 : 0.22;
        [view.layer addAnimation:transition forKey:@"cd.volumeribbon.fade"];
    }
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDVolumeRibbonStyle(self);
}

- (void)layoutSubviews {
    %orig;
    CDVolumeRibbonStyle(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[VolumeRibbon] loaded");
        %init;
    }
}
