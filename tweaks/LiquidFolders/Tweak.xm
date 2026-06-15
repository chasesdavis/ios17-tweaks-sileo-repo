#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static void CDLiquidFoldersApply(UIView *view) {
    if (!CDVTLooksLikeSurface(view, @[@"Folder", @"SBFolder"], 90.0, 80.0, 520.0, 620.0)) {
        return;
    }
    CGFloat radius = MIN(32.0, MAX(18.0, CGRectGetHeight(view.bounds) * 0.05));
    CDVTStyleSurface(view, [UIColor colorWithWhite:0.08 alpha:0.28], CDVTColor(126, 218, 255, 0.44), radius, 18.0);
    CDVTAddPulse(view.layer, @"cd.liquidfolders.shimmer", 0.82, 1.0, 3.4);
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDLiquidFoldersApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDLiquidFoldersApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[LiquidFolders] loaded");
        %init;
    }
}
