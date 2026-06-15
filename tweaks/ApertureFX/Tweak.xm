#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDApertureFXDomain = @"com.chasedavis.aperturefx";

static BOOL CDApertureFXShouldStyle(UIView *view) {
    if (CDPremiumBool(CDApertureFXDomain, @"styleFolders", YES) && CDVTClassChainContains(view, @[@"Folder"])) {
        return YES;
    }
    if (CDPremiumBool(CDApertureFXDomain, @"styleIsland", YES) && CDVTClassChainContains(view, @[@"SystemAperture", @"Island"])) {
        return YES;
    }
    if (CDPremiumBool(CDApertureFXDomain, @"styleBanners", YES) && CDVTClassChainContains(view, @[@"Banner", @"Platter"])) {
        return YES;
    }
    return NO;
}

static void CDApertureFXApply(UIView *view) {
    if (!CDPremiumBool(CDApertureFXDomain, @"enabled", NO)) {
        return;
    }
    if (CDPremiumBool(CDApertureFXDomain, @"respectReduceMotion", YES) && UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDApertureFXDomain, CDVTColor(184, 118, 255, 1.0));
    if (CDVTLooksLikeSurface(view, @[@"Folder", @"SystemAperture", @"Island", @"Banner", @"Platter"], 40.0, 20.0, 560.0, 620.0) && CDApertureFXShouldStyle(view)) {
        CGFloat glow = CDPremiumClampedFloat(CDApertureFXDomain, @"glowStrength", 0.36, 0.0, 1.0);
        view.layer.shadowColor = tint.CGColor;
        view.layer.shadowOffset = CGSizeZero;
        view.layer.shadowRadius = CDPremiumClampedFloat(CDApertureFXDomain, @"shadowRadius", 13.0, 0.0, 32.0);
        view.layer.shadowOpacity = glow;
        if (CDPremiumBool(CDApertureFXDomain, @"surfacePulse", YES)) {
            CGFloat duration = CDPremiumClampedFloat(CDApertureFXDomain, @"pulseSeconds", 2.6, 1.0, 8.0);
            CDVTAddPulse(view.layer, @"cd.aperturefx.surfacePulse", 0.82, 1.0, duration);
        } else {
            [view.layer removeAnimationForKey:@"cd.aperturefx.surfacePulse"];
        }
    }
}

static void CDApertureFXIconEcho(UIView *view) {
    if (!CDPremiumBool(CDApertureFXDomain, @"enabled", NO) || !CDPremiumBool(CDApertureFXDomain, @"launchEcho", YES) || !CDVTClassChainContains(view, @[@"IconView"])) {
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
