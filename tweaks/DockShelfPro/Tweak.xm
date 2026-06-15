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

static NSArray<NSString *> *CDDockShelfTitles(void) {
    NSInteger mode = CDPremiumInteger(CDDockShelfDomain, @"laneMode", 0);
    if (mode == 1) {
        return @[@"Pinned", @"Recent", @"Next", @"Later"];
    }
    if (mode == 2) {
        return @[@"Wi-Fi", @"Audio", @"Power", @"Tools"];
    }
    if (mode == 3) {
        return @[@"Focus", @"Work", @"Home", @"Sleep"];
    }
    return @[@"Favorites", @"Recents", @"Tools", @"Shortcuts"];
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
        BOOL startsOpen = CDPremiumBool(CDDockShelfDomain, @"startsOpen", NO);
        shelf.alpha = startsOpen ? 1.0 : 0.0;
        shelf.transform = startsOpen ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0.0, 18.0);
        [dock.superview insertSubview:shelf aboveSubview:dock];
        objc_setAssociatedObject(dock, &kCDDockShelfViewKey, shelf, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        CDDockShelfGestureTarget *target = [CDDockShelfGestureTarget new];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(handleShelfGesture:)];
        tap.numberOfTapsRequired = MAX(1, MIN(3, CDPremiumInteger(CDDockShelfDomain, @"tapCount", 2)));
        tap.cancelsTouchesInView = NO;
        [dock addGestureRecognizer:tap];
        objc_setAssociatedObject(dock, &kCDDockShelfTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat width = MIN(CGRectGetWidth(dock.superview.bounds) - 24.0, 392.0);
    CGFloat height = CDPremiumClampedFloat(CDDockShelfDomain, @"shelfHeight", 54.0, 44.0, 78.0);
    CGFloat offset = CDPremiumClampedFloat(CDDockShelfDomain, @"shelfOffset", 10.0, 0.0, 28.0);
    CGFloat y = CGRectGetMinY(dock.frame) - height - offset;
    shelf.frame = CGRectMake((CGRectGetWidth(dock.superview.bounds) - width) / 2.0, MAX(8.0, y), width, height);
    CGFloat fill = CDPremiumClampedFloat(CDDockShelfDomain, @"shelfFill", 0.38, 0.08, 0.70);
    CGFloat shadow = CDPremiumClampedFloat(CDDockShelfDomain, @"shadowStrength", 0.60, 0.0, 1.0);
    CDVTStyleSurface(shelf, [UIColor colorWithWhite:0.03 alpha:fill], tint, 18.0 + height * 0.08, 6.0 + shadow * 20.0);
    [shelf.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSArray<NSString *> *titles = CDDockShelfTitles();
    NSInteger laneCount = MAX(2, MIN(4, CDPremiumInteger(CDDockShelfDomain, @"laneCount", 3)));
    CGFloat gap = 8.0;
    CGFloat laneWidth = (width - 28.0 - gap * (laneCount - 1)) / laneCount;
    for (NSInteger index = 0; index < laneCount; index++) {
        NSString *title = index < (NSInteger)titles.count ? titles[index] : @"Slot";
        [shelf addSubview:CDDockShelfLane(title, tint, 14.0 + (laneWidth + gap) * index, laneWidth)];
    }
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
