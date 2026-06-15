#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDControlStudioDomain = @"com.chasedavis.controlcenterstudio";

static BOOL CDControlStudioIsModule(UIView *view) {
    return CDVTLooksLikeSurface(view, @[@"ControlCenter", @"CCUI", @"Module"], 28.0, 24.0, 420.0, 300.0);
}

static CGFloat CDControlStudioRadius(UIView *view) {
    NSInteger style = CDPremiumInteger(CDControlStudioDomain, @"cornerStyle", 0);
    if (style == 1) {
        return 12.0;
    }
    if (style == 2) {
        return 22.0;
    }
    if (style == 3) {
        return CGRectGetHeight(view.bounds) / 2.0;
    }
    return MIN(26.0, MAX(12.0, CGRectGetHeight(view.bounds) * 0.20));
}

static void CDControlStudioApplyModule(UIView *view) {
    if (!CDPremiumBool(CDControlStudioDomain, @"enabled", NO) || !CDControlStudioIsModule(view)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDControlStudioDomain, CDVTColor(112, 229, 168, 1.0));
    if (CDPremiumBool(CDControlStudioDomain, @"moduleSurface", YES)) {
        CGFloat fill = CDPremiumClampedFloat(CDControlStudioDomain, @"surfaceFill", 0.34, 0.04, 0.68);
        CGFloat shadow = CDPremiumClampedFloat(CDControlStudioDomain, @"moduleShadow", 0.55, 0.0, 1.0);
        CDVTStyleSurface(view, [UIColor colorWithWhite:0.025 alpha:fill], tint, CDControlStudioRadius(view), 4.0 + shadow * 18.0);
    }
    if (CDPremiumBool(CDControlStudioDomain, @"modulePulse", YES)) {
        CGFloat duration = CDPremiumClampedFloat(CDControlStudioDomain, @"pulseSeconds", 3.2, 1.2, 8.0);
        CDVTAddPulse(view.layer, @"cd.controlstudio.modulePulse", 0.88, 1.0, duration);
    } else {
        [view.layer removeAnimationForKey:@"cd.controlstudio.modulePulse"];
    }
}

static void CDControlStudioApplyGlyph(UIImageView *imageView) {
    if (!CDPremiumBool(CDControlStudioDomain, @"enabled", NO) || !CDPremiumBool(CDControlStudioDomain, @"glyphsEnabled", YES) || !CDControlStudioIsModule(imageView)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDControlStudioDomain, CDVTColor(112, 229, 168, 1.0));
    if (CDPremiumBool(CDControlStudioDomain, @"tintGlyphs", YES)) {
        imageView.tintColor = tint;
    }
    imageView.layer.shadowColor = tint.CGColor;
    imageView.layer.shadowOffset = CGSizeZero;
    imageView.layer.shadowRadius = CDPremiumClampedFloat(CDControlStudioDomain, @"glyphRadius", 5.0, 0.0, 14.0);
    imageView.layer.shadowOpacity = CDPremiumClampedFloat(CDControlStudioDomain, @"glyphGlow", 0.62, 0.0, 1.0);
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    CDControlStudioApplyModule(self);
}
- (void)layoutSubviews {
    %orig;
    CDControlStudioApplyModule(self);
}
%end

%hook UIImageView
- (void)didMoveToWindow {
    %orig;
    CDControlStudioApplyGlyph(self);
}
- (void)setHighlighted:(BOOL)highlighted {
    %orig(highlighted);
    if (highlighted) {
        CDVTAddPop(self.layer, @"cd.controlstudio.highlight");
    }
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[ControlCenterStudio] loaded");
        %init;
    }
}
