#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static UIColor *CDWallpaperDepthTintColor(void) {
    CGFloat brightness = [UIScreen mainScreen].brightness;
    if (brightness < 0.35) {
        return CDVTColor(190, 226, 255, 0.96);
    }
    if (brightness > 0.75) {
        return CDVTColor(54, 70, 92, 0.95);
    }
    return CDVTColor(126, 205, 255, 0.94);
}

static void CDWallpaperDepthTintApply(UILabel *label) {
    if (!label.window || !label.text.length || !CDVTClassChainContains(label, @[@"IconView", @"IconLabel"])) {
        return;
    }
    label.textColor = CDWallpaperDepthTintColor();
    label.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.68].CGColor;
    label.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    label.layer.shadowRadius = 2.2;
    label.layer.shadowOpacity = 0.68;
}

%hook UILabel

- (void)didMoveToWindow {
    %orig;
    CDWallpaperDepthTintApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDWallpaperDepthTintApply(self);
}

- (void)setText:(NSString *)text {
    %orig(text);
    CDWallpaperDepthTintApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[WallpaperDepthTint] loaded");
        %init;
    }
}
