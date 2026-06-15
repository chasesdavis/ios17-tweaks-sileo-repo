#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CDVisualTweakKit.h"

static BOOL CDDimInactivePagesLooksLikeIconScroll(UIScrollView *scrollView) {
    return scrollView.window && CGRectGetWidth(scrollView.bounds) > 240.0 && CDVTClassChainContains(scrollView, @[@"IconScroll", @"RootFolder", @"IconList", @"SBIcon"]);
}

static void CDDimInactivePagesApply(UIScrollView *scrollView) {
    if (!CDDimInactivePagesLooksLikeIconScroll(scrollView)) {
        return;
    }
    CGFloat centerX = scrollView.contentOffset.x + CGRectGetWidth(scrollView.bounds) / 2.0;
    CGFloat pageWidth = MAX(CGRectGetWidth(scrollView.bounds), 1.0);
    for (UIView *subview in scrollView.subviews) {
        CGFloat distance = fabs(CGRectGetMidX(subview.frame) - centerX) / pageWidth;
        CGFloat alpha = MAX(0.42, 1.0 - distance * 0.72);
        if (subview.alpha > alpha || distance < 0.15) {
            subview.alpha = distance < 0.15 ? 1.0 : alpha;
        }
    }
}

%hook UIScrollView

- (void)setContentOffset:(CGPoint)contentOffset {
    %orig(contentOffset);
    CDDimInactivePagesApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDDimInactivePagesApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[DimInactivePages] loaded");
        %init;
    }
}
