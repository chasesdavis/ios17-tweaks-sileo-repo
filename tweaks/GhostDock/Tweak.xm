#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDGhostDockConfiguredKey;
static char kCDGhostDockTokenKey;
static char kCDGhostDockTargetKey;

static BOOL CDGhostDockIsDockView(UIView *view) {
    NSString *className = NSStringFromClass(object_getClass(view));
    return ([className containsString:@"Dock"] && ([className containsString:@"SB"] || [className containsString:@"Home"]));
}

static void CDGhostDockReveal(UIView *dock);
static void CDGhostDockScheduleHide(UIView *dock);

@interface CDGhostDockGestureTarget : NSObject
@end

@implementation CDGhostDockGestureTarget

- (void)cdGhostDockHandleGesture:(UIGestureRecognizer *)gesture {
    UIView *dock = gesture.view;
    if (!dock) {
        return;
    }
    CDGhostDockReveal(dock);
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
        CDGhostDockScheduleHide(dock);
    }
}

@end

static void CDGhostDockReveal(UIView *dock) {
    if (!dock.window) {
        return;
    }
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        dock.alpha = 1.0;
        dock.transform = CGAffineTransformIdentity;
    } completion:nil];
}

static void CDGhostDockScheduleHide(UIView *dock) {
    if (!dock.window) {
        return;
    }
    NSUInteger token = arc4random();
    objc_setAssociatedObject(dock, &kCDGhostDockTokenKey, @(token), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    __weak UIView *weakDock = dock;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *strongDock = weakDock;
        NSNumber *stored = objc_getAssociatedObject(strongDock, &kCDGhostDockTokenKey);
        if (!strongDock.window || !stored || stored.unsignedIntegerValue != token) {
            return;
        }
        [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
            strongDock.alpha = 0.18;
            strongDock.transform = CGAffineTransformMakeTranslation(0.0, 14.0);
        } completion:nil];
    });
}

static void CDGhostDockConfigure(UIView *dock) {
    if (!dock.window || objc_getAssociatedObject(dock, &kCDGhostDockConfiguredKey)) {
        return;
    }
    objc_setAssociatedObject(dock, &kCDGhostDockConfiguredKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    dock.userInteractionEnabled = YES;
    CDGhostDockGestureTarget *target = [CDGhostDockGestureTarget new];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(cdGhostDockHandleGesture:)];
    tap.cancelsTouchesInView = NO;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:target action:@selector(cdGhostDockHandleGesture:)];
    pan.cancelsTouchesInView = NO;
    [dock addGestureRecognizer:tap];
    [dock addGestureRecognizer:pan];
    objc_setAssociatedObject(dock, &kCDGhostDockTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CDGhostDockScheduleHide(dock);
}

%hook UIView

- (void)didMoveToWindow {
    %orig;
    if (CDGhostDockIsDockView(self)) {
        CDGhostDockConfigure(self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (CDGhostDockIsDockView(self)) {
        CDGhostDockConfigure(self);
    }
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[GhostDock] loaded");
        %init;
    }
}
