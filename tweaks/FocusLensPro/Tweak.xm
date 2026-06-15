#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDFocusLensDomain = @"com.chasedavis.focuslenspro";
static char kCDFocusLensPanelKey;

static BOOL CDFocusLensActive(void) {
    if (!CDPremiumBool(CDFocusLensDomain, @"enabled", YES)) {
        return NO;
    }
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    NSInteger start = CDPremiumInteger(CDFocusLensDomain, @"quietStartHour", 21);
    NSInteger end = CDPremiumInteger(CDFocusLensDomain, @"quietEndHour", 7);
    return start > end ? (hour >= start || hour < end) : (hour >= start && hour < end);
}

static void CDFocusLensApply(UIView *view) {
    if (!view.window || !CDFocusLensActive()) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDFocusLensDomain, CDVTColor(124, 190, 255, 1.0));
    if (CDVTClassChainContains(view, @[@"Widget", @"IconList", @"Page"])) {
        view.alpha = MIN(view.alpha, 0.72);
    }
    if (CDVTLooksLikeSurface(view, @[@"Badge"], 6.0, 6.0, 64.0, 64.0)) {
        CDVTStyleSurface(view, [tint colorWithAlphaComponent:0.52], tint, MIN(16.0, CGRectGetHeight(view.bounds) / 2.0), 8.0);
        view.alpha = MIN(view.alpha, 0.68);
    }
    if (CDVTLooksLikeSurface(view, @[@"Dock"], 120.0, 40.0, 520.0, 180.0)) {
        CDVTStyleSurface(view, [UIColor colorWithWhite:0.02 alpha:0.26], tint, 28.0, 14.0);
    }
}

static void CDFocusLensShowStatus(void) {
    if (!CDFocusLensActive()) {
        return;
    }
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDFocusLensDomain, nil);
    CDPremiumPanel(window, &kCDFocusLensPanelKey, @"Focus Lens", @"Quiet profile active", tint, MAX(62.0, window.safeAreaInsets.top + 44.0), 250.0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDPremiumDismissPanel(window, &kCDFocusLensPanelKey);
    });
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CDFocusLensShowStatus();
    });
    NSLog(@"[FocusLensPro] profile engine loaded");
}
%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDFocusLensApply(self);
}
- (void)layoutSubviews {
    %orig;
    CDFocusLensApply(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[FocusLensPro] loaded");
        %init;
    }
}
