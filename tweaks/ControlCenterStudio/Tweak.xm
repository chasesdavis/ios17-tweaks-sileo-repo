#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDControlStudioDomain = @"com.chasedavis.controlcenterstudio";

static BOOL CDControlStudioIsModule(UIView *view) {
    return CDVTLooksLikeSurface(view, @[@"ControlCenter", @"CCUI", @"Module"], 28.0, 24.0, 420.0, 300.0);
}

static void CDControlStudioApplyModule(UIView *view) {
    if (!CDPremiumBool(CDControlStudioDomain, @"enabled", NO) || !CDControlStudioIsModule(view)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDControlStudioDomain, CDVTColor(112, 229, 168, 1.0));
    CGFloat radius = MIN(26.0, MAX(12.0, CGRectGetHeight(view.bounds) * 0.20));
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.025 alpha:0.34], tint, radius, 13.0);
    CDVTAddPulse(view.layer, @"cd.controlstudio.modulePulse", 0.88, 1.0, 3.2);
}

static void CDControlStudioApplyGlyph(UIImageView *imageView) {
    if (!CDPremiumBool(CDControlStudioDomain, @"enabled", NO) || !CDPremiumBool(CDControlStudioDomain, @"glyphsEnabled", YES) || !CDControlStudioIsModule(imageView)) {
        return;
    }
    UIColor *tint = CDPremiumTint(CDControlStudioDomain, CDVTColor(112, 229, 168, 1.0));
    imageView.tintColor = tint;
    imageView.layer.shadowColor = tint.CGColor;
    imageView.layer.shadowOffset = CGSizeZero;
    imageView.layer.shadowRadius = 5.0;
    imageView.layer.shadowOpacity = 0.62;
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
