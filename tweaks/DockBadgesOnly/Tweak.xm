#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDDockBadgesOnlyApplyLabel(UILabel *label) {
    if (label.window && label.text.length && CDVTClassChainContains(label, @[@"Dock", @"IconView"])) {
        label.alpha = 0.0;
    }
}

static void CDDockBadgesOnlyApplyBadge(UIView *view) {
    if (!CDVTLooksLikeSurface(view, @[@"Dock", @"Badge"], 6.0, 6.0, 62.0, 62.0)) {
        return;
    }
    view.alpha = 1.0;
    CDVTStyleSurface(view, CDVTColor(255, 58, 98, 0.92), CDVTColor(255, 58, 98, 0.44), MIN(16.0, CGRectGetHeight(view.bounds) / 2.0), 8.0);
}

%hook UILabel

- (void)didMoveToWindow {
    %orig;
    CDDockBadgesOnlyApplyLabel(self);
}

- (void)layoutSubviews {
    %orig;
    CDDockBadgesOnlyApplyLabel(self);
}

%end

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDDockBadgesOnlyApplyBadge(self);
}

- (void)layoutSubviews {
    %orig;
    CDDockBadgesOnlyApplyBadge(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[DockBadgesOnly] loaded");
        %init;
    }
}
