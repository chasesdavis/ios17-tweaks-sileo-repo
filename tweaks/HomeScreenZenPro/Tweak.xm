#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDZenDomain = @"com.chasedavis.homescreenzenpro";

static BOOL CDZenEnabled(void) {
    if (!CDPremiumBool(CDZenDomain, @"enabled", NO)) {
        return NO;
    }
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    NSInteger start = CDPremiumInteger(CDZenDomain, @"zenStartHour", 20);
    NSInteger end = CDPremiumInteger(CDZenDomain, @"zenEndHour", 8);
    BOOL inWindow = start > end ? (hour >= start || hour < end) : (hour >= start && hour < end);
    return CDPremiumBool(CDZenDomain, @"alwaysOn", NO) || inWindow;
}

static void CDZenApplyView(UIView *view) {
    if (!view.window || !CDZenEnabled()) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDZenDomain, CDVTColor(186, 118, 255, 1.0));
    if (CDPremiumBool(CDZenDomain, @"dimBadges", YES) && CDVTLooksLikeSurface(view, @[@"Badge"], 6.0, 6.0, 64.0, 64.0)) {
        view.alpha = CDPremiumClampedFloat(CDZenDomain, @"badgeAlpha", 0.38, 0.05, 1.0);
        CDVTStyleSurface(view, [tint colorWithAlphaComponent:0.34], tint, MIN(15.0, CGRectGetHeight(view.bounds) / 2.0), 6.0);
    } else if (CDPremiumBool(CDZenDomain, @"dimWidgets", YES) && CDVTClassChainContains(view, @[@"Widget", @"IconList"])) {
        view.alpha = MIN(view.alpha, CDPremiumClampedFloat(CDZenDomain, @"widgetAlpha", 0.74, 0.15, 1.0));
    } else if (CDPremiumBool(CDZenDomain, @"styleDock", YES) && CDVTLooksLikeSurface(view, @[@"Dock"], 120.0, 40.0, 520.0, 180.0)) {
        CGFloat dockFill = CDPremiumClampedFloat(CDZenDomain, @"dockFill", 0.20, 0.03, 0.56);
        CGFloat dockShadow = CDPremiumClampedFloat(CDZenDomain, @"dockShadow", 0.38, 0.0, 1.0);
        CDVTStyleSurface(view, [UIColor colorWithWhite:0.01 alpha:dockFill], tint, 28.0, 4.0 + dockShadow * 18.0);
    }
}

static void CDZenApplyLabel(UILabel *label) {
    if (label.window && CDZenEnabled() && CDPremiumBool(CDZenDomain, @"hideLabels", YES) && CDVTClassChainContains(label, @[@"IconView", @"IconLabel"])) {
        label.alpha = CDPremiumClampedFloat(CDZenDomain, @"labelAlpha", 0.0, 0.0, 1.0);
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
