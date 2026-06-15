#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static BOOL CDSignalBloomLooksLikeSignal(UIView *view) {
    return CDVTLooksLikeSurface(view, @[@"Signal", @"WiFi", @"Cellular", @"StatusBar"], 4.0, 4.0, 92.0, 42.0);
}

static void CDSignalBloomApply(UIView *view) {
    if (!CDSignalBloomLooksLikeSignal(view)) {
        return;
    }
    view.tintColor = CDVTColor(93, 221, 255, 0.96);
    view.layer.shadowColor = CDVTColor(93, 221, 255, 0.66).CGColor;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 4.5;
    view.layer.shadowOpacity = 0.75;
    CDVTAddPulse(view.layer, @"cd.signalbloom.pulse", 0.62, 1.0, 2.2);
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDSignalBloomApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDSignalBloomApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[SignalBloom] loaded");
        %init;
    }
}
