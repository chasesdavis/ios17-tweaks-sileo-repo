#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDZenDomain = @"com.chasedavis.homescreenzenpro";

static BOOL CDZenEnabled(void) {
    if (!CDPremiumBool(CDZenDomain, @"enabled", YES)) {
        return NO;
    }
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    return CDPremiumBool(CDZenDomain, @"alwaysOn", NO) || hour >= 20 || hour < 8;
}

static void CDZenApplyView(UIView *view) {
    if (!view.window || !CDZenEnabled()) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDZenDomain, CDVTColor(186, 118, 255, 1.0));
    if (CDVTLooksLikeSurface(view, @[@"Badge"], 6.0, 6.0, 64.0, 64.0)) {
        view.alpha = 0.38;
        CDVTStyleSurface(view, [tint colorWithAlphaComponent:0.34], tint, MIN(15.0, CGRectGetHeight(view.bounds) / 2.0), 6.0);
    } else if (CDVTClassChainContains(view, @[@"Widget", @"IconList"])) {
        view.alpha = MIN(view.alpha, 0.74);
    } else if (CDVTLooksLikeSurface(view, @[@"Dock"], 120.0, 40.0, 520.0, 180.0)) {
        CDVTStyleSurface(view, [UIColor colorWithWhite:0.01 alpha:0.20], tint, 28.0, 10.0);
    }
}

static void CDZenApplyLabel(UILabel *label) {
    if (label.window && CDZenEnabled() && CDVTClassChainContains(label, @[@"IconView", @"IconLabel"])) {
        label.alpha = 0.0;
    }
}

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    CDZenApplyLabel(self);
}
- (void)layoutSubviews {
    %orig;
    CDZenApplyLabel(self);
}
%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDZenApplyView(self);
}
- (void)layoutSubviews {
    %orig;
    CDZenApplyView(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[HomeScreenZenPro] loaded");
        %init;
    }
}
