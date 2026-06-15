#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static BOOL CDMinimalCCLooksLikeModule(UIView *view) {
    return CDVTLooksLikeSurface(view, @[@"ControlCenter", @"CCUI", @"Module"], 34.0, 28.0, 360.0, 260.0);
}

static void CDMinimalCCApply(UIView *view) {
    if (!CDMinimalCCLooksLikeModule(view)) {
        return;
    }
    CGFloat radius = MIN(22.0, MAX(12.0, CGRectGetHeight(view.bounds) * 0.18));
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.04 alpha:0.30], CDVTColor(0, 0, 0, 0.34), radius, 10.0);
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDMinimalCCApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDMinimalCCApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[MinimalCC] loaded");
        %init;
    }
}
