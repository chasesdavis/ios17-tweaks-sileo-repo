#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDDockShelfDomain = @"com.chasedavis.dockshelfpro";
static char kCDDockShelfViewKey;
static char kCDDockShelfTargetKey;

static BOOL CDDockShelfIsDock(UIView *view) {
    return CDVTLooksLikeSurface(view, @[@"Dock"], 120.0, 44.0, 520.0, 180.0);
}

@interface CDDockShelfGestureTarget : NSObject
@end

@implementation CDDockShelfGestureTarget
- (void)handleShelfGesture:(UIGestureRecognizer *)gesture {
    UIView *dock = gesture.view;
    UIView *shelf = objc_getAssociatedObject(dock, &kCDDockShelfViewKey);
    if (!shelf) {
        return;
    }
    BOOL showing = shelf.alpha < 0.5;
    [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        shelf.alpha = showing ? 1.0 : 0.0;
        shelf.transform = showing ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0.0, 18.0);
    } completion:nil];
}
@end

static UILabel *CDDockShelfLane(NSString *text, UIColor *tint, CGFloat x, CGFloat width) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, 10.0, width, 34.0)];
    label.text = text;
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [tint colorWithAlphaComponent:0.16];
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.layer.cornerRadius = 13.0;
    label.layer.masksToBounds = YES;
    return label;
}

static void CDDockShelfInstall(UIView *dock) {
    if (!CDDockShelfIsDock(dock) || !CDPremiumBool(CDDockShelfDomain, @"enabled", NO)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDDockShelfDomain, CDVTColor(126, 220, 255, 1.0));

    UIView *shelf = objc_getAssociatedObject(dock, &kCDDockShelfViewKey);
    if (!shelf) {
        shelf = [[UIView alloc] initWithFrame:CGRectZero];
        shelf.userInteractionEnabled = NO;
        shelf.alpha = 0.0;
        shelf.transform = CGAffineTransformMakeTranslation(0.0, 18.0);
        CDVTStyleSurface(shelf, [UIColor colorWithWhite:0.03 alpha:0.38], tint, 24.0, 16.0);
        [dock.superview insertSubview:shelf aboveSubview:dock];
        objc_setAssociatedObject(dock, &kCDDockShelfViewKey, shelf, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        CDDockShelfGestureTarget *target = [CDDockShelfGestureTarget new];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(handleShelfGesture:)];
        tap.numberOfTapsRequired = 2;
        tap.cancelsTouchesInView = NO;
        [dock addGestureRecognizer:tap];
        objc_setAssociatedObject(dock, &kCDDockShelfTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat width = MIN(CGRectGetWidth(dock.superview.bounds) - 24.0, 392.0);
    CGFloat height = 54.0;
    CGFloat y = CGRectGetMinY(dock.frame) - height - 10.0;
    shelf.frame = CGRectMake((CGRectGetWidth(dock.superview.bounds) - width) / 2.0, MAX(8.0, y), width, height);
    shelf.layer.cornerRadius = 22.0;
    [shelf.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    CGFloat gap = 8.0;
    CGFloat laneWidth = (width - 28.0 - gap * 2.0) / 3.0;
    [shelf addSubview:CDDockShelfLane(@"Favorites", tint, 14.0, laneWidth)];
    [shelf addSubview:CDDockShelfLane(@"Recents", tint, 14.0 + laneWidth + gap, laneWidth)];
    [shelf addSubview:CDDockShelfLane(@"Tools", tint, 14.0 + (laneWidth + gap) * 2.0, laneWidth)];
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDDockShelfInstall(self);
}
- (void)layoutSubviews {
    %orig;
    CDDockShelfInstall(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[DockShelfPro] loaded");
        %init;
    }
}
