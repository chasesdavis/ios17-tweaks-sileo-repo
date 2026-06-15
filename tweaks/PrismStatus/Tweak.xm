#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static BOOL CDPrismStatusLooksLikeStatusLabel(UILabel *label) {
    if (!label.window || CGRectGetHeight(label.bounds) > 34.0 || label.text.length == 0) {
        return NO;
    }
    return CDVTClassChainContains(label, @[@"StatusBar", @"StatusBarString", @"Battery", @"Pill"]);
}

static void CDPrismStatusApply(UILabel *label) {
    if (!CDPrismStatusLooksLikeStatusLabel(label)) {
        return;
    }
    label.textColor = CDVTColor(142, 226, 255, 0.96);
    label.layer.shadowColor = CDVTColor(180, 102, 255, 0.70).CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = 3.0;
    label.layer.shadowOpacity = 0.60;
}

%hook UILabel

- (void)didMoveToWindow {
    %orig;
    CDPrismStatusApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDPrismStatusApply(self);
}

- (void)setText:(NSString *)text {
    %orig(text);
    CDPrismStatusApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[PrismStatus] loaded");
        %init;
    }
}
