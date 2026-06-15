#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDStatusLabDomain = @"com.chasedavis.statuslabpro";

static void CDStatusLabApplyView(UIView *view) {
    if (!CDPremiumBool(CDStatusLabDomain, @"enabled", YES) || !CDVTLooksLikeSurface(view, @[@"StatusBar", @"Signal", @"Cellular", @"Battery", @"WiFi", @"Indicator"], 3.0, 3.0, 110.0, 44.0)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDStatusLabDomain, CDVTColor(126, 220, 255, 1.0));
    view.tintColor = tint;
    view.layer.shadowColor = tint.CGColor;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 4.2;
    view.layer.shadowOpacity = 0.64;
}

static void CDStatusLabApplyLabel(UILabel *label) {
    if (!label.window || !label.text.length || !CDVTClassChainContains(label, @[@"StatusBar", @"Time", @"Battery"])) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDStatusLabDomain, CDVTColor(126, 220, 255, 1.0));
    label.textColor = tint;
    label.layer.shadowColor = tint.CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = 3.0;
    label.layer.shadowOpacity = 0.48;
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDStatusLabApplyView(self);
}
- (void)layoutSubviews {
    %orig;
    CDStatusLabApplyView(self);
}
%end

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    CDStatusLabApplyLabel(self);
}
- (void)setText:(NSString *)text {
    %orig(text);
    CDStatusLabApplyLabel(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[StatusLabPro] loaded");
        %init;
    }
}
