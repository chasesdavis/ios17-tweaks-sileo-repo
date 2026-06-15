#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDControlGlyphsApply(UIImageView *imageView) {
    if (!CDVTLooksLikeSurface(imageView, @[@"ControlCenter", @"CCUI", @"Module"], 8.0, 8.0, 76.0, 76.0)) {
        return;
    }
    imageView.tintColor = CDVTColor(126, 220, 255, 0.98);
    imageView.layer.shadowColor = CDVTColor(126, 220, 255, 0.58).CGColor;
    imageView.layer.shadowOffset = CGSizeZero;
    imageView.layer.shadowRadius = 5.5;
    imageView.layer.shadowOpacity = 0.55;
    CDVTAddPop(imageView.layer, @"cd.controlglyphs.pop");
}

%hook UIImageView

- (void)didMoveToWindow {
    %orig;
    CDControlGlyphsApply(self);
}

- (void)setHighlighted:(BOOL)highlighted {
    %orig(highlighted);
    if (highlighted) {
        CDVTAddPop(self.layer, @"cd.controlglyphs.highlight");
    }
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[ControlGlyphs] loaded");
        %init;
    }
}
