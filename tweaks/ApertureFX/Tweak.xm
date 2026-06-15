#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDApertureFXDomain = @"com.chasedavis.aperturefx";

static void CDApertureFXApply(UIView *view) {
    if (!CDPremiumBool(CDApertureFXDomain, @"enabled", YES) || UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDApertureFXDomain, CDVTColor(184, 118, 255, 1.0));
    if (CDVTLooksLikeSurface(view, @[@"Folder", @"SystemAperture", @"Island", @"Banner", @"Platter"], 40.0, 20.0, 560.0, 620.0)) {
        view.layer.shadowColor = tint.CGColor;
        view.layer.shadowOffset = CGSizeZero;
        view.layer.shadowRadius = 13.0;
        view.layer.shadowOpacity = 0.36;
        CDVTAddPulse(view.layer, @"cd.aperturefx.surfacePulse", 0.82, 1.0, 2.6);
    }
}

static void CDApertureFXIconEcho(UIView *view) {
    if (!CDPremiumBool(CDApertureFXDomain, @"launchEcho", YES) || !CDVTClassChainContains(view, @[@"IconView"])) {
        return;
    }
    CDVTAddPop(view.layer, @"cd.aperturefx.iconPop");
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDApertureFXApply(self);
}
- (void)layoutSubviews {
    %orig;
    CDApertureFXApply(self);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    CDApertureFXIconEcho(self);
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[ApertureFX] loaded");
        %init;
    }
}
