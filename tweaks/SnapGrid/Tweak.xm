#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"

static char kCDSnapGridViewKey;

static void CDSnapGridShow(void) {
    UIWindow *window = CDVTKeyWindow();
    if (!window || objc_getAssociatedObject(window, &kCDSnapGridViewKey)) {
        return;
    }

    UIView *grid = [[UIView alloc] initWithFrame:window.bounds];
    grid.userInteractionEnabled = NO;
    grid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    grid.alpha = 0.0;

    CAShapeLayer *lines = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat width = CGRectGetWidth(window.bounds);
    CGFloat height = CGRectGetHeight(window.bounds);
    CGFloat stepX = width / 4.0;
    CGFloat stepY = height / 8.0;
    for (CGFloat x = stepX; x < width; x += stepX) {
        [path moveToPoint:CGPointMake(x, 0)];
        [path addLineToPoint:CGPointMake(x, height)];
    }
    for (CGFloat y = stepY; y < height; y += stepY) {
        [path moveToPoint:CGPointMake(0, y)];
        [path addLineToPoint:CGPointMake(width, y)];
    }
    lines.path = path.CGPath;
    lines.strokeColor = CDVTColor(126, 220, 255, 0.24).CGColor;
    lines.lineWidth = 1.0;
    [grid.layer addSublayer:lines];
    [window addSubview:grid];
    objc_setAssociatedObject(window, &kCDSnapGridViewKey, grid, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [UIView animateWithDuration:0.16 animations:^{
        grid.alpha = 1.0;
    }];
}

static void CDSnapGridHide(void) {
    UIWindow *window = CDVTKeyWindow();
    UIView *grid = objc_getAssociatedObject(window, &kCDSnapGridViewKey);
    if (!grid) {
        return;
    }
    [UIView animateWithDuration:0.20 animations:^{
        grid.alpha = 0.0;
    } completion:^(__unused BOOL finished) {
        [grid removeFromSuperview];
        objc_setAssociatedObject(window, &kCDSnapGridViewKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }];
}

%hook UIView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    if (CDVTClassChainContains(self, @[@"IconView"])) {
        CDSnapGridShow();
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    CDSnapGridHide();
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    CDSnapGridHide();
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[SnapGrid] loaded");
        %init;
    }
}
