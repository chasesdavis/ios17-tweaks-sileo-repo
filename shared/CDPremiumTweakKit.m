#import "CDPremiumTweakKit.h"
#import "CDVisualTweakKit.h"
#import <objc/runtime.h>

static id CDPremiumValue(NSString *domain, NSString *key) {
    if (!domain.length || !key.length) {
        return nil;
    }
    return (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)domain);
}

BOOL CDPremiumBool(NSString *domain, NSString *key, BOOL fallback) {
    id value = CDPremiumValue(domain, key);
    return value ? [value boolValue] : fallback;
}

NSInteger CDPremiumInteger(NSString *domain, NSString *key, NSInteger fallback) {
    id value = CDPremiumValue(domain, key);
    return value ? [value integerValue] : fallback;
}

CGFloat CDPremiumFloat(NSString *domain, NSString *key, CGFloat fallback) {
    id value = CDPremiumValue(domain, key);
    return value ? [value doubleValue] : fallback;
}

CGFloat CDPremiumClampedFloat(NSString *domain, NSString *key, CGFloat fallback, CGFloat minimum, CGFloat maximum) {
    CGFloat value = CDPremiumFloat(domain, key, fallback);
    if (minimum > maximum) {
        CGFloat swap = minimum;
        minimum = maximum;
        maximum = swap;
    }
    return MIN(MAX(value, minimum), maximum);
}

UIColor *CDPremiumTint(NSString *domain, UIColor *fallback) {
    NSInteger palette = CDPremiumInteger(domain, @"palette", 0);
    switch (palette) {
        case 1: return CDVTColor(255, 94, 126, 1.0);
        case 2: return CDVTColor(112, 229, 168, 1.0);
        case 3: return CDVTColor(255, 186, 82, 1.0);
        case 4: return CDVTColor(184, 118, 255, 1.0);
        default: return fallback ?: CDVTColor(116, 220, 255, 1.0);
    }
}

UIVisualEffectView *CDPremiumPanel(UIWindow *window, const void *key, NSString *title, NSString *subtitle, UIColor *tint, CGFloat y, CGFloat width) {
    if (!window || !key) {
        return nil;
    }

    UIVisualEffectView *panel = objc_getAssociatedObject(window, key);
    if (!panel) {
        panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
        panel.userInteractionEnabled = NO;
        panel.layer.cornerCurve = kCACornerCurveContinuous;
        panel.layer.cornerRadius = 22.0;
        panel.layer.masksToBounds = YES;
        panel.layer.borderWidth = 1.0;
        panel.alpha = 0.0;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.tag = 7001;
        titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [panel.contentView addSubview:titleLabel];

        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.tag = 7002;
        subtitleLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium];
        subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        [panel.contentView addSubview:subtitleLabel];

        [window addSubview:panel];
        objc_setAssociatedObject(window, key, panel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat safeWidth = MIN(MAX(width, 180.0), CGRectGetWidth(window.bounds) - 32.0);
    panel.frame = CGRectMake((CGRectGetWidth(window.bounds) - safeWidth) / 2.0, y, safeWidth, 58.0);
    panel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    panel.layer.borderColor = [tint colorWithAlphaComponent:0.35].CGColor;
    panel.backgroundColor = [tint colorWithAlphaComponent:0.08];

    UILabel *titleLabel = [panel.contentView viewWithTag:7001];
    UILabel *subtitleLabel = [panel.contentView viewWithTag:7002];
    titleLabel.text = title;
    subtitleLabel.text = subtitle;
    titleLabel.frame = CGRectMake(14.0, 10.0, CGRectGetWidth(panel.bounds) - 28.0, 20.0);
    subtitleLabel.frame = CGRectMake(14.0, 31.0, CGRectGetWidth(panel.bounds) - 28.0, 17.0);

    [window bringSubviewToFront:panel];
    if (panel.alpha < 0.99) {
        [UIView animateWithDuration:0.18 animations:^{
            panel.alpha = 1.0;
            panel.transform = CGAffineTransformIdentity;
        }];
    }
    return panel;
}

void CDPremiumDismissPanel(UIWindow *window, const void *key) {
    UIVisualEffectView *panel = objc_getAssociatedObject(window, key);
    if (!panel) {
        return;
    }
    [UIView animateWithDuration:0.20 animations:^{
        panel.alpha = 0.0;
        panel.transform = CGAffineTransformMakeTranslation(0.0, -8.0);
    } completion:^(__unused BOOL finished) {
        [panel removeFromSuperview];
        objc_setAssociatedObject(window, key, nil, OBJC_ASSOCIATION_ASSIGN);
    }];
}

void CDPremiumToast(NSString *title, NSString *subtitle, UIColor *tint) {
    NSString *message = subtitle.length ? [NSString stringWithFormat:@"%@ - %@", title ?: @"Premium", subtitle] : (title ?: @"Premium");
    CDVTShowToast(message, tint ?: CDVTColor(116, 220, 255, 1.0));
}
