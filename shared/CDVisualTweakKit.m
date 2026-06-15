#import "CDVisualTweakKit.h"
#import <objc/runtime.h>

BOOL CDVTClassChainContains(UIView *view, NSArray<NSString *> *needles) {
    for (UIView *cursor = view; cursor != nil; cursor = cursor.superview) {
        NSString *className = NSStringFromClass(object_getClass(cursor));
        for (NSString *needle in needles) {
            if ([className rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return YES;
            }
        }
    }
    return NO;
}

BOOL CDVTLooksLikeSurface(UIView *view, NSArray<NSString *> *needles, CGFloat minWidth, CGFloat minHeight, CGFloat maxWidth, CGFloat maxHeight) {
    if (!view || !view.window) {
        return NO;
    }
    CGFloat width = CGRectGetWidth(view.bounds);
    CGFloat height = CGRectGetHeight(view.bounds);
    if (width < minWidth || height < minHeight) {
        return NO;
    }
    if (maxWidth > 0 && width > maxWidth) {
        return NO;
    }
    if (maxHeight > 0 && height > maxHeight) {
        return NO;
    }
    return CDVTClassChainContains(view, needles);
}

UIColor *CDVTColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha];
}

void CDVTStyleSurface(UIView *view, UIColor *backgroundColor, UIColor *shadowColor, CGFloat cornerRadius, CGFloat shadowRadius) {
    if (!view) {
        return;
    }
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.cornerRadius = cornerRadius;
    view.layer.masksToBounds = NO;
    if (backgroundColor) {
        view.backgroundColor = backgroundColor;
    }
    view.layer.shadowColor = (shadowColor ?: [UIColor blackColor]).CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, shadowRadius * 0.22);
    view.layer.shadowRadius = shadowRadius;
    view.layer.shadowOpacity = shadowRadius > 0 ? 0.28 : 0.0;
}

void CDVTAddPulse(CALayer *layer, NSString *key, CGFloat fromOpacity, CGFloat toOpacity, CFTimeInterval duration) {
    if (!layer || [layer animationForKey:key]) {
        return;
    }
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulse.fromValue = @(fromOpacity);
    pulse.toValue = @(toOpacity);
    pulse.duration = UIAccessibilityIsReduceMotionEnabled() ? duration * 1.45 : duration;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [layer addAnimation:pulse forKey:key];
}

void CDVTAddPop(CALayer *layer, NSString *key) {
    if (!layer || UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }
    CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pop.values = @[@0.96, @1.08, @1.0];
    pop.keyTimes = @[@0.0, @0.55, @1.0];
    pop.duration = 0.24;
    pop.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [layer addAnimation:pop forKey:key];
}

UIWindow *CDVTKeyWindow(void) {
    UIApplication *application = [UIApplication sharedApplication];
    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return application.windows.firstObject;
}

void CDVTShowToast(NSString *message, UIColor *tintColor) {
    UIWindow *window = CDVTKeyWindow();
    if (!window || message.length == 0) {
        return;
    }

    UIVisualEffectView *toast = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    toast.userInteractionEnabled = NO;
    toast.layer.cornerCurve = kCACornerCurveContinuous;
    toast.layer.cornerRadius = 18.0;
    toast.layer.masksToBounds = YES;
    toast.alpha = 0.0;
    toast.backgroundColor = [tintColor colorWithAlphaComponent:0.18];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    [toast.contentView addSubview:label];

    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 48.0, 238.0);
    CGFloat height = 38.0;
    toast.frame = CGRectMake((CGRectGetWidth(window.bounds) - width) / 2.0, MAX(54.0, window.safeAreaInsets.top + 14.0), width, height);
    label.frame = toast.contentView.bounds;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window addSubview:toast];

    [UIView animateWithDuration:0.18 animations:^{
        toast.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.20 animations:^{
                toast.alpha = 0.0;
                toast.transform = CGAffineTransformMakeTranslation(0.0, -8.0);
            } completion:^(__unused BOOL done) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

void CDVTAddEdgeGlow(UIWindow *window, const void *key, UIColor *color, NSString *animationKey, CGFloat opacity) {
    if (!window || !key) {
        return;
    }
    UIView *glow = objc_getAssociatedObject(window, key);
    if (!glow) {
        glow = [[UIView alloc] initWithFrame:window.bounds];
        glow.userInteractionEnabled = NO;
        glow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        glow.backgroundColor = [UIColor clearColor];
        glow.layer.cornerCurve = kCACornerCurveContinuous;
        glow.layer.cornerRadius = 34.0;
        glow.layer.borderWidth = 3.0;
        [window addSubview:glow];
        objc_setAssociatedObject(window, key, glow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    glow.frame = window.bounds;
    glow.layer.borderColor = color.CGColor;
    glow.layer.shadowColor = color.CGColor;
    glow.layer.shadowOffset = CGSizeZero;
    glow.layer.shadowRadius = 20.0;
    glow.layer.shadowOpacity = opacity;
    [window bringSubviewToFront:glow];
    CDVTAddPulse(glow.layer, animationKey, MAX(0.18, opacity * 0.36), opacity, 1.8);
}

void CDVTRemoveAssociatedView(UIWindow *window, const void *key) {
    UIView *view = objc_getAssociatedObject(window, key);
    [view removeFromSuperview];
    objc_setAssociatedObject(window, key, nil, OBJC_ASSOCIATION_ASSIGN);
}
