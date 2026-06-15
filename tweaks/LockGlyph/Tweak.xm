#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDLockGlyphApply(UIImageView *imageView) {
    if (!CDVTLooksLikeSurface(imageView, @[@"Lock", @"LockGlyph", @"Passcode"], 8.0, 8.0, 90.0, 90.0)) {
        return;
    }
    imageView.tintColor = CDVTColor(192, 230, 255, 0.98);
    imageView.layer.shadowColor = CDVTColor(116, 210, 255, 0.74).CGColor;
    imageView.layer.shadowOffset = CGSizeZero;
    imageView.layer.shadowRadius = 7.0;
    imageView.layer.shadowOpacity = 0.72;
    CDVTAddPulse(imageView.layer, @"cd.lockglyph.pulse", 0.70, 1.0, 2.6);
}

%hook UIImageView

- (void)didMoveToWindow {
    %orig;
    CDLockGlyphApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDLockGlyphApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[LockGlyph] loaded");
        %init;
    }
}
