#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static BOOL CDQuietBadgesIsQuietHour(void) {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    return hour >= 21 || hour < 7;
}

static BOOL CDQuietBadgesLooksLikeBadge(UIView *view) {
    return CDVTLooksLikeSurface(view, @[@"Badge"], 6.0, 6.0, 60.0, 60.0);
}

static void CDQuietBadgesApply(UIView *view) {
    if (!CDQuietBadgesLooksLikeBadge(view)) {
        return;
    }
    if (CDQuietBadgesIsQuietHour()) {
        view.alpha = MIN(view.alpha, 0.62);
        CDVTStyleSurface(view, CDVTColor(120, 42, 62, 0.72), CDVTColor(255, 96, 128, 0.34), MIN(16.0, CGRectGetHeight(view.bounds) / 2.0), 6.0);
    } else {
        view.alpha = MAX(view.alpha, 0.90);
    }
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDQuietBadgesApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDQuietBadgesApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[QuietBadges] loaded");
        %init;
    }
}
