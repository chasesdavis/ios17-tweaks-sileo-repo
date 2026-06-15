#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDStatusLabDomain = @"com.chasedavis.statuslabpro";

static void CDStatusLabApplyView(UIView *view) {
    if (!CDPremiumBool(CDStatusLabDomain, @"enabled", NO) || !CDVTLooksLikeSurface(view, @[@"StatusBar", @"Signal", @"Cellular", @"Battery", @"WiFi", @"Indicator"], 3.0, 3.0, 110.0, 44.0)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDStatusLabDomain, CDVTColor(126, 220, 255, 1.0));
    if (CDPremiumBool(CDStatusLabDomain, @"tintSymbols", YES)) {
        view.tintColor = tint;
    }
    if (CDPremiumBool(CDStatusLabDomain, @"glowSymbols", YES)) {
        view.layer.shadowColor = tint.CGColor;
        view.layer.shadowOffset = CGSizeZero;
        view.layer.shadowRadius = CDPremiumClampedFloat(CDStatusLabDomain, @"symbolRadius", 4.2, 0.0, 14.0);
        view.layer.shadowOpacity = CDPremiumClampedFloat(CDStatusLabDomain, @"symbolGlow", 0.64, 0.0, 1.0);
    }
}

static void CDStatusLabApplyLabel(UILabel *label) {
    if (!CDPremiumBool(CDStatusLabDomain, @"enabled", NO) || !label.window || !label.text.length || !CDVTClassChainContains(label, @[@"StatusBar", @"Time", @"Battery"])) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDStatusLabDomain, CDVTColor(126, 220, 255, 1.0));
    if (CDPremiumBool(CDStatusLabDomain, @"tintText", YES)) {
        CGFloat textAlpha = CDPremiumClampedFloat(CDStatusLabDomain, @"textAlpha", 1.0, 0.2, 1.0);
        label.textColor = [tint colorWithAlphaComponent:textAlpha];
    }
    if (CDPremiumBool(CDStatusLabDomain, @"glowText", YES)) {
        label.layer.shadowColor = tint.CGColor;
        label.layer.shadowOffset = CGSizeZero;
        label.layer.shadowRadius = CDPremiumClampedFloat(CDStatusLabDomain, @"textRadius", 3.0, 0.0, 12.0);
        label.layer.shadowOpacity = CDPremiumClampedFloat(CDStatusLabDomain, @"textGlow", 0.48, 0.0, 1.0);
    }
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
