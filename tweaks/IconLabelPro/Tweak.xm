#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char kCDIconLabelStyledKey;

static BOOL CDIconLabelChainContains(UIView *view, NSString *needle) {
    for (UIView *cursor = view; cursor != nil; cursor = cursor.superview) {
        NSString *className = NSStringFromClass(object_getClass(cursor));
        if ([className rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

static BOOL CDIconLabelLooksLikeIconLabel(UILabel *label) {
    if (!label.text.length || CGRectGetHeight(label.bounds) > 32.0) {
        return NO;
    }
    NSString *className = NSStringFromClass(object_getClass(label));
    return [className rangeOfString:@"Icon" options:NSCaseInsensitiveSearch].location != NSNotFound
        || CDIconLabelChainContains(label, @"IconView");
}

static void CDIconLabelApply(UILabel *label) {
    if (!label.window || !CDIconLabelLooksLikeIconLabel(label)) {
        return;
    }

    BOOL inDock = CDIconLabelChainContains(label, @"Dock");
    if (inDock) {
        label.alpha = 0.0;
        return;
    }

    if (!objc_getAssociatedObject(label, &kCDIconLabelStyledKey)) {
        objc_setAssociatedObject(label, &kCDIconLabelStyledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        label.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.75].CGColor;
        label.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        label.layer.shadowRadius = 2.4;
        label.layer.shadowOpacity = 0.70;
        label.layer.masksToBounds = NO;
    }

    label.alpha = 0.92;
    if (@available(iOS 13.0, *)) {
        label.textColor = [[UIColor labelColor] colorWithAlphaComponent:0.92];
    } else {
        label.textColor = [UIColor whiteColor];
    }
}

%hook UILabel

- (void)didMoveToWindow {
    %orig;
    CDIconLabelApply(self);
}

- (void)layoutSubviews {
    %orig;
    CDIconLabelApply(self);
}

- (void)setText:(NSString *)text {
    %orig(text);
    CDIconLabelApply(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[IconLabelPro] loaded");
        %init;
    }
}
