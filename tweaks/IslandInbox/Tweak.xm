#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDIslandInboxDomain = @"com.chasedavis.islandinbox";
static char kCDIslandInboxCapturedKey;
static char kCDIslandInboxOverlayKey;
static BOOL gCDIslandInboxRefreshing = NO;

@class CDIslandInboxOverlay;

@interface CDIslandInboxItem : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) UIView *sourceView;
@property (nonatomic, strong) UIColor *accentColor;
@end

@implementation CDIslandInboxItem
@end

@interface CDIslandInboxOverlay : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) NSMutableArray<CDIslandInboxItem *> *items;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDate *> *fingerprints;
@property (nonatomic, strong) UIView *replyView;
@property (nonatomic, strong) UITextField *replyField;
@property (nonatomic, strong) CDIslandInboxItem *replyItem;
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;
- (void)addItem:(CDIslandInboxItem *)item;
- (void)collapse;
@end

static UIColor *CDIIAccent(void) {
    return CDPremiumTint(CDIslandInboxDomain, CDVTColor(93, 214, 255, 1.0));
}

static BOOL CDIIEnabled(void) {
    return CDPremiumBool(CDIslandInboxDomain, @"enabled", NO);
}

static void CDIIHaptic(UIImpactFeedbackStyle style) {
    if (!CDPremiumBool(CDIslandInboxDomain, @"haptics", YES)) {
        return;
    }
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [generator impactOccurred];
}

static NSString *CDIITrim(NSString *text) {
    if (![text isKindOfClass:[NSString class]]) {
        return @"";
    }
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL CDIIStringLooksLikeBundleID(NSString *value) {
    if (![value isKindOfClass:[NSString class]] || value.length < 5 || value.length > 96) {
        return NO;
    }
    return [value containsString:@"."] && [value rangeOfString:@" "].location == NSNotFound;
}

static void CDIICollectLabels(UIView *view, NSMutableArray<NSString *> *labels) {
    if (!view || labels.count >= 8) {
        return;
    }
    if ([view isKindOfClass:[UILabel class]]) {
        NSString *text = CDIITrim(((UILabel *)view).text);
        if (text.length && ![labels containsObject:text]) {
            [labels addObject:text];
        }
    }
    for (UIView *subview in view.subviews) {
        CDIICollectLabels(subview, labels);
    }
}

static UIImage *CDIIFindIcon(UIView *view) {
    if (!view) {
        return nil;
    }
    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        CGFloat width = CGRectGetWidth(imageView.bounds);
        CGFloat height = CGRectGetHeight(imageView.bounds);
        if (imageView.image && width >= 14.0 && height >= 14.0 && width <= 92.0 && height <= 92.0) {
            return imageView.image;
        }
    }
    for (UIView *subview in view.subviews) {
        UIImage *image = CDIIFindIcon(subview);
        if (image) {
            return image;
        }
    }
    return nil;
}

static UIColor *CDIIColorForText(NSString *text) {
    NSUInteger hash = text.length ? text.hash : 0x51A7;
    CGFloat hue = (CGFloat)(hash % 255) / 255.0;
    return [UIColor colorWithHue:hue saturation:0.64 brightness:0.96 alpha:1.0];
}

static NSString *CDIIFindBundleIdentifierInObject(id object, NSInteger depth, NSMutableSet<NSNumber *> *visited) {
    if (!object || depth > 4) {
        return nil;
    }
    if ([object isKindOfClass:[NSString class]]) {
        return CDIIStringLooksLikeBundleID(object) ? object : nil;
    }

    NSNumber *pointer = @((uintptr_t)(__bridge const void *)object);
    if ([visited containsObject:pointer]) {
        return nil;
    }
    [visited addObject:pointer];

    NSArray<NSString *> *selectors = @[
        @"bundleIdentifier",
        @"applicationBundleIdentifier",
        @"sectionIdentifier",
        @"publisherBulletinID",
        @"threadIdentifier",
        @"request",
        @"notificationRequest",
        @"notification",
        @"bulletin",
        @"alertItem",
        @"representedObject",
        @"content"
    ];

    for (NSString *selectorName in selectors) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![object respondsToSelector:selector]) {
            continue;
        }
        id value = nil;
        @try {
            value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
        } @catch (__unused NSException *exception) {
            value = nil;
        }
        NSString *found = CDIIFindBundleIdentifierInObject(value, depth + 1, visited);
        if (found.length) {
            return found;
        }
    }

    return nil;
}

static NSString *CDIIBundleIdentifierForView(UIView *view) {
    NSMutableSet<NSNumber *> *visited = [NSMutableSet set];
    for (UIResponder *responder = view; responder; responder = responder.nextResponder) {
        NSString *found = CDIIFindBundleIdentifierInObject(responder, 0, visited);
        if (found.length) {
            return found;
        }
        if (![responder isKindOfClass:[UIView class]]) {
            break;
        }
    }
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        NSString *found = CDIIFindBundleIdentifierInObject(cursor, 0, visited);
        if (found.length) {
            return found;
        }
    }
    return nil;
}

static BOOL CDIIInvokeNoArgumentSelector(id target, NSArray<NSString *> *selectorNames) {
    for (NSString *selectorName in selectorNames) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![target respondsToSelector:selector]) {
            continue;
        }
        NSMethodSignature *signature = [target methodSignatureForSelector:selector];
        if (signature.numberOfArguments != 2) {
            continue;
        }
        @try {
            ((void (*)(id, SEL))objc_msgSend)(target, selector);
            return YES;
        } @catch (__unused NSException *exception) {
        }
    }
    return NO;
}

static BOOL CDIIActivateViewTree(UIView *view) {
    if (!view) {
        return NO;
    }
    NSArray<NSString *> *selectors = @[
        @"activate",
        @"_activate",
        @"performPrimaryAction",
        @"_performPrimaryAction",
        @"open",
        @"_open",
        @"dismissAndOpen",
        @"_dismissAndOpen"
    ];

    if (CDIIInvokeNoArgumentSelector(view, selectors)) {
        return YES;
    }
    for (UIView *subview in view.subviews) {
        if (CDIIActivateViewTree(subview)) {
            return YES;
        }
    }
    for (UIView *cursor = view.superview; cursor; cursor = cursor.superview) {
        if (CDIIInvokeNoArgumentSelector(cursor, selectors)) {
            return YES;
        }
    }
    return NO;
}

static BOOL CDIILaunchBundleIdentifier(NSString *bundleIdentifier) {
    if (!bundleIdentifier.length) {
        return NO;
    }
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    if (!workspaceClass || ![workspaceClass respondsToSelector:defaultSelector]) {
        return NO;
    }
    id workspace = ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultSelector);
    NSArray<NSString *> *selectors = @[@"openApplicationWithBundleID:", @"openApplicationWithBundleID:options:"];
    for (NSString *selectorName in selectors) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![workspace respondsToSelector:selector]) {
            continue;
        }
        NSMethodSignature *signature = [workspace methodSignatureForSelector:selector];
        @try {
            if (signature.numberOfArguments == 3) {
                return ((BOOL (*)(id, SEL, NSString *))objc_msgSend)(workspace, selector, bundleIdentifier);
            }
            if (signature.numberOfArguments == 4) {
                return ((BOOL (*)(id, SEL, NSString *, NSDictionary *))objc_msgSend)(workspace, selector, bundleIdentifier, @{});
            }
        } @catch (__unused NSException *exception) {
        }
    }
    return NO;
}

static CDIslandInboxOverlay *CDIIOverlay(void) {
    UIWindow *window = CDVTKeyWindow();
    if (!window) {
        return nil;
    }

    CDIslandInboxOverlay *overlay = objc_getAssociatedObject(window, &kCDIslandInboxOverlayKey);
    if (!overlay) {
        overlay = [[CDIslandInboxOverlay alloc] initWithFrame:CGRectZero];
        overlay.alpha = 0.0;
        [window addSubview:overlay];
        objc_setAssociatedObject(window, &kCDIslandInboxOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [window bringSubviewToFront:overlay];
    return overlay;
}

static NSArray<NSString *> *CDIINotificationNeedles(void) {
    return @[@"Notification", @"Banner", @"ShortLook", @"Platter", @"NCNotification", @"SBBanner"];
}

static BOOL CDIIHasNotificationAncestor(UIView *view) {
    for (UIView *cursor = view.superview; cursor; cursor = cursor.superview) {
        if (CDVTLooksLikeSurface(cursor, CDIINotificationNeedles(), 220.0, 44.0, 620.0, 340.0)) {
            return YES;
        }
    }
    return NO;
}

static BOOL CDIIIsOwnView(UIView *view) {
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        if ([cursor isKindOfClass:[CDIslandInboxOverlay class]] || [NSStringFromClass(object_getClass(cursor)) containsString:@"CDIslandInbox"]) {
            return YES;
        }
    }
    return NO;
}

static BOOL CDIILooksLikeIncomingBanner(UIView *view) {
    if (!CDIIEnabled() || gCDIslandInboxRefreshing || !view.window || CDIIIsOwnView(view)) {
        return NO;
    }
    if (objc_getAssociatedObject(view, &kCDIslandInboxCapturedKey) || CDIIHasNotificationAncestor(view)) {
        return NO;
    }
    if (!CDVTLooksLikeSurface(view, CDIINotificationNeedles(), 220.0, 44.0, 620.0, 340.0)) {
        return NO;
    }

    CGRect frame = [view convertRect:view.bounds toView:view.window];
    CGFloat topLimit = MAX(170.0, view.window.safeAreaInsets.top + 140.0);
    if (CGRectGetMinY(frame) > topLimit) {
        return NO;
    }

    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    CDIICollectLabels(view, labels);
    return labels.count > 0;
}

static CDIslandInboxItem *CDIIItemFromView(UIView *view) {
    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    CDIICollectLabels(view, labels);

    CDIslandInboxItem *item = [CDIslandInboxItem new];
    item.title = labels.count > 0 ? labels[0] : @"Notification";
    if (labels.count > 1) {
        NSMutableArray<NSString *> *bodyParts = [NSMutableArray array];
        for (NSUInteger index = 1; index < labels.count && index < 4; index++) {
            [bodyParts addObject:labels[index]];
        }
        item.message = [bodyParts componentsJoinedByString:@"  "];
    } else {
        item.message = @"New alert";
    }
    item.icon = CDIIFindIcon(view);
    item.date = [NSDate date];
    item.sourceView = view;
    item.bundleIdentifier = CDIIBundleIdentifierForView(view);
    item.accentColor = item.icon ? CDIIAccent() : CDIIColorForText(item.title);
    item.identifier = [NSString stringWithFormat:@"%lu-%@", (unsigned long)item.title.hash, item.message ?: @""];
    return item;
}

static void CDIISuppressBannerView(UIView *view) {
    if (!CDPremiumBool(CDIslandInboxDomain, @"suppressBanners", YES)) {
        return;
    }
    view.userInteractionEnabled = NO;
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0.08 : 0.18 animations:^{
        view.alpha = 0.0;
        view.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(__unused BOOL finished) {
        view.hidden = YES;
    }];
}

static void CDIICaptureIfNeeded(UIView *view) {
    if (!CDIILooksLikeIncomingBanner(view)) {
        return;
    }
    objc_setAssociatedObject(view, &kCDIslandInboxCapturedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CDIslandInboxItem *item = CDIIItemFromView(view);
    CDIslandInboxOverlay *overlay = CDIIOverlay();
    [overlay addItem:item];
    CDIISuppressBannerView(view);
}

@implementation CDIslandInboxOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.items = [NSMutableArray array];
        self.fingerprints = [NSMutableDictionary dictionary];
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;

        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
        self.blurView.userInteractionEnabled = NO;
        self.blurView.layer.cornerCurve = kCACornerCurveContinuous;
        self.blurView.layer.cornerRadius = 21.0;
        self.blurView.layer.masksToBounds = YES;
        [self addSubview:self.blurView];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)addItem:(CDIslandInboxItem *)item {
    if (!item.title.length) {
        return;
    }

    NSDate *lastSeen = self.fingerprints[item.identifier];
    if (lastSeen && fabs([lastSeen timeIntervalSinceNow]) < 2.2) {
        return;
    }
    self.fingerprints[item.identifier] = [NSDate date];

    NSInteger maxItems = MAX(1, CDPremiumInteger(CDIslandInboxDomain, @"maxItems", 7));
    [self.items insertObject:item atIndex:0];
    while (self.items.count > (NSUInteger)maxItems) {
        [self.items removeLastObject];
    }

    [self refreshAnimated:YES];
    CDIIHaptic(UIImpactFeedbackStyleLight);

    if (CDPremiumBool(CDIslandInboxDomain, @"autoCollapse", YES) && self.isExpanded) {
        NSInteger seconds = CDPremiumInteger(CDIslandInboxDomain, @"autoCollapseSeconds", 5);
        if (seconds > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.items.count > 0) {
                    [self collapse];
                }
            });
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.blurView.frame = self.bounds;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded || self.items.count == 0) {
        return;
    }
    if (!self.isExpanded) {
        [self expand];
    }
}

- (void)expand {
    self.expanded = YES;
    [self refreshAnimated:YES];
    CDIIHaptic(UIImpactFeedbackStyleMedium);
}

- (void)collapse {
    self.expanded = NO;
    [self endEditing:YES];
    [self.replyView removeFromSuperview];
    self.replyView = nil;
    self.replyItem = nil;
    [self refreshAnimated:YES];
}

- (void)archiveItem:(CDIslandInboxItem *)item {
    if (!item) {
        return;
    }
    [self.items removeObject:item];
    CDIIHaptic(UIImpactFeedbackStyleLight);
    if (self.items.count == 0) {
        [self dismiss];
    } else {
        [self refreshAnimated:YES];
    }
}

- (void)openItem:(CDIslandInboxItem *)item {
    if (!item) {
        return;
    }
    BOOL opened = CDIIActivateViewTree(item.sourceView);
    if (!opened) {
        opened = CDIILaunchBundleIdentifier(item.bundleIdentifier);
    }
    CDIIHaptic(opened ? UIImpactFeedbackStyleMedium : UIImpactFeedbackStyleLight);
    [self archiveItem:item];
    if (!opened) {
        CDVTShowToast(@"Island Inbox could not open this notification", CDIIAccent());
    }
}

- (void)dismiss {
    UIWindow *hostWindow = self.window;
    [UIView animateWithDuration:0.18 animations:^{
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeTranslation(0.0, -8.0);
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
        objc_setAssociatedObject(hostWindow, &kCDIslandInboxOverlayKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }];
}

- (void)refreshAnimated:(BOOL)animated {
    UIWindow *window = CDVTKeyWindow();
    if (!window || self.items.count == 0) {
        return;
    }

    gCDIslandInboxRefreshing = YES;
    [self.replyView removeFromSuperview];
    self.replyView = nil;
    for (UIView *subview in self.subviews.copy) {
        if (subview != self.blurView) {
            [subview removeFromSuperview];
        }
    }

    CGFloat width = self.isExpanded ? MIN(CGRectGetWidth(window.bounds) - 24.0, 356.0) : MIN(CGRectGetWidth(window.bounds) - 96.0, 198.0);
    BOOL replyMode = self.isExpanded && self.replyItem && CDPremiumBool(CDIslandInboxDomain, @"quickReplies", YES);
    CGFloat rowLimit = replyMode ? 3.0 : 4.0;
    CGFloat rowCount = MIN((CGFloat)self.items.count, rowLimit);
    CGFloat height = self.isExpanded ? (82.0 + rowCount * 58.0 + (replyMode ? 68.0 : 0.0)) : 38.0;
    CGFloat y = MAX(7.0, window.safeAreaInsets.top + 4.0 + CDPremiumClampedFloat(CDIslandInboxDomain, @"verticalOffset", 0.0, -12.0, 60.0));
    CGRect targetFrame = CGRectMake((CGRectGetWidth(window.bounds) - width) / 2.0, y, width, height);

    self.layer.shadowColor = CDIIAccent().CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 10.0 + CDPremiumClampedFloat(CDIslandInboxDomain, @"glowStrength", 0.55, 0.0, 1.0) * 24.0;
    self.layer.shadowOpacity = 0.18 + CDPremiumClampedFloat(CDIslandInboxDomain, @"glowStrength", 0.55, 0.0, 1.0) * 0.38;
    self.blurView.backgroundColor = [CDIIAccent() colorWithAlphaComponent:CDPremiumClampedFloat(CDIslandInboxDomain, @"panelFill", 0.18, 0.04, 0.36)];
    self.blurView.layer.borderWidth = 1.0;
    self.blurView.layer.borderColor = [CDIIAccent() colorWithAlphaComponent:0.32].CGColor;
    self.blurView.layer.cornerRadius = self.isExpanded ? 26.0 : 19.0;

    void (^layoutBlock)(void) = ^{
        self.frame = targetFrame;
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1.0;
        [self buildContent];
    };

    if (animated) {
        [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0.08 : 0.22 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:layoutBlock completion:^(__unused BOOL finished) {
            gCDIslandInboxRefreshing = NO;
            CDVTAddPop(self.layer, @"cd.islandinbox.pop");
        }];
    } else {
        layoutBlock();
        gCDIslandInboxRefreshing = NO;
    }
}

- (void)buildContent {
    if (self.isExpanded) {
        [self buildExpandedContent];
    } else {
        [self buildCollapsedContent];
    }
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color frame:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:label];
    return label;
}

- (UIView *)chipForItem:(CDIslandInboxItem *)item index:(NSUInteger)index {
    CGFloat size = 28.0;
    UIView *chip = [[UIView alloc] initWithFrame:CGRectMake(13.0 + index * 31.0, 5.0, size, size)];
    chip.layer.cornerCurve = kCACornerCurveContinuous;
    chip.layer.cornerRadius = size / 2.0;
    chip.layer.borderWidth = 1.0;
    chip.layer.borderColor = [item.accentColor colorWithAlphaComponent:0.66].CGColor;
    chip.backgroundColor = [item.accentColor colorWithAlphaComponent:0.18];
    chip.clipsToBounds = YES;
    chip.tag = 9000 + index;

    if (item.icon) {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:item.icon];
        iconView.frame = CGRectInset(chip.bounds, 3.0, 3.0);
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        iconView.layer.cornerCurve = kCACornerCurveContinuous;
        iconView.layer.cornerRadius = 8.0;
        iconView.clipsToBounds = YES;
        [chip addSubview:iconView];
    } else {
        UILabel *monogram = [[UILabel alloc] initWithFrame:chip.bounds];
        monogram.text = item.title.length ? [[item.title substringToIndex:1] uppercaseString] : @"!";
        monogram.textAlignment = NSTextAlignmentCenter;
        monogram.textColor = [UIColor whiteColor];
        monogram.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
        [chip addSubview:monogram];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandFromChip:)];
    [chip addGestureRecognizer:tap];
    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(archiveFromGesture:)];
    left.direction = UISwipeGestureRecognizerDirectionLeft;
    [chip addGestureRecognizer:left];
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openFromGesture:)];
    right.direction = UISwipeGestureRecognizerDirectionRight;
    [chip addGestureRecognizer:right];
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(replyFromGesture:)];
    press.minimumPressDuration = 0.42;
    [chip addGestureRecognizer:press];

    return chip;
}

- (CDIslandInboxItem *)itemForGesture:(UIGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag - 9000;
    if (index >= 0 && index < (NSInteger)self.items.count) {
        return self.items[(NSUInteger)index];
    }
    return nil;
}

- (void)buildCollapsedContent {
    NSUInteger visible = MIN(self.items.count, 4);
    for (NSUInteger index = 0; index < visible; index++) {
        [self addSubview:[self chipForItem:self.items[index] index:index]];
    }

    NSString *count = [NSString stringWithFormat:@"%lu", (unsigned long)self.items.count];
    UILabel *countLabel = [self labelWithText:count font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold] color:[UIColor whiteColor] frame:CGRectMake(CGRectGetWidth(self.bounds) - 38.0, 7.0, 24.0, 24.0)];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    countLabel.layer.cornerCurve = kCACornerCurveContinuous;
    countLabel.layer.cornerRadius = 12.0;
    countLabel.layer.masksToBounds = YES;
}

- (UIView *)rowForItem:(CDIslandInboxItem *)item index:(NSUInteger)index y:(CGFloat)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(12.0, y, CGRectGetWidth(self.bounds) - 24.0, 52.0)];
    row.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.075];
    row.layer.cornerCurve = kCACornerCurveContinuous;
    row.layer.cornerRadius = 16.0;
    row.tag = 9000 + index;

    UIView *iconContainer = [[UIView alloc] initWithFrame:CGRectMake(10.0, 10.0, 32.0, 32.0)];
    iconContainer.backgroundColor = [item.accentColor colorWithAlphaComponent:0.20];
    iconContainer.layer.cornerCurve = kCACornerCurveContinuous;
    iconContainer.layer.cornerRadius = 10.0;
    iconContainer.clipsToBounds = YES;
    [row addSubview:iconContainer];

    if (item.icon) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:item.icon];
        imageView.frame = CGRectInset(iconContainer.bounds, 3.0, 3.0);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerCurve = kCACornerCurveContinuous;
        imageView.layer.cornerRadius = 7.0;
        imageView.clipsToBounds = YES;
        [iconContainer addSubview:imageView];
    } else {
        UILabel *monogram = [[UILabel alloc] initWithFrame:iconContainer.bounds];
        monogram.text = item.title.length ? [[item.title substringToIndex:1] uppercaseString] : @"!";
        monogram.textAlignment = NSTextAlignmentCenter;
        monogram.textColor = [UIColor whiteColor];
        monogram.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
        [iconContainer addSubview:monogram];
    }

    CGFloat textX = 52.0;
    CGFloat buttonReserve = 72.0;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(textX, 8.0, CGRectGetWidth(row.bounds) - textX - buttonReserve, 18.0)];
    title.text = item.title;
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    title.lineBreakMode = NSLineBreakByTruncatingTail;
    [row addSubview:title];

    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(textX, 27.0, CGRectGetWidth(row.bounds) - textX - buttonReserve, 17.0)];
    message.text = item.message;
    message.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.68];
    message.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium];
    message.lineBreakMode = NSLineBreakByTruncatingTail;
    [row addSubview:message];

    UIButton *archive = [UIButton buttonWithType:UIButtonTypeSystem];
    archive.frame = CGRectMake(CGRectGetWidth(row.bounds) - 64.0, 10.0, 26.0, 32.0);
    archive.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.70];
    [archive setImage:[UIImage systemImageNamed:@"archivebox"] forState:UIControlStateNormal];
    archive.tag = 9000 + index;
    [archive addTarget:self action:@selector(archiveFromButton:) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:archive];

    UIButton *open = [UIButton buttonWithType:UIButtonTypeSystem];
    open.frame = CGRectMake(CGRectGetWidth(row.bounds) - 34.0, 10.0, 26.0, 32.0);
    open.tintColor = CDIIAccent();
    [open setImage:[UIImage systemImageNamed:@"arrow.up.right"] forState:UIControlStateNormal];
    open.tag = 9000 + index;
    [open addTarget:self action:@selector(openFromButton:) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:open];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openFromGesture:)];
    [row addGestureRecognizer:tap];
    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(archiveFromGesture:)];
    left.direction = UISwipeGestureRecognizerDirectionLeft;
    [row addGestureRecognizer:left];
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openFromGesture:)];
    right.direction = UISwipeGestureRecognizerDirectionRight;
    [row addGestureRecognizer:right];
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(replyFromGesture:)];
    press.minimumPressDuration = 0.42;
    [row addGestureRecognizer:press];

    return row;
}

- (void)buildExpandedContent {
    [self labelWithText:@"Island Inbox" font:[UIFont systemFontOfSize:15.0 weight:UIFontWeightBold] color:[UIColor whiteColor] frame:CGRectMake(16.0, 13.0, 160.0, 22.0)];
    NSString *subtitle = [NSString stringWithFormat:@"%lu queued", (unsigned long)self.items.count];
    [self labelWithText:subtitle font:[UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold] color:[[UIColor whiteColor] colorWithAlphaComponent:0.62] frame:CGRectMake(16.0, 33.0, 160.0, 18.0)];

    UIButton *collapse = [UIButton buttonWithType:UIButtonTypeSystem];
    collapse.frame = CGRectMake(CGRectGetWidth(self.bounds) - 48.0, 12.0, 34.0, 34.0);
    collapse.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    [collapse setImage:[UIImage systemImageNamed:@"chevron.up"] forState:UIControlStateNormal];
    [collapse addTarget:self action:@selector(collapseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:collapse];

    NSUInteger visible = MIN(self.items.count, (self.replyItem && CDPremiumBool(CDIslandInboxDomain, @"quickReplies", YES)) ? 3 : 4);
    CGFloat y = 60.0;
    for (NSUInteger index = 0; index < visible; index++) {
        [self addSubview:[self rowForItem:self.items[index] index:index y:y]];
        y += 58.0;
    }
}

- (void)expandFromChip:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self expand];
    }
}

- (void)archiveFromButton:(UIButton *)button {
    NSInteger index = button.tag - 9000;
    if (index >= 0 && index < (NSInteger)self.items.count) {
        [self archiveItem:self.items[(NSUInteger)index]];
    }
}

- (void)openFromButton:(UIButton *)button {
    NSInteger index = button.tag - 9000;
    if (index >= 0 && index < (NSInteger)self.items.count) {
        [self openItem:self.items[(NSUInteger)index]];
    }
}

- (void)archiveFromGesture:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateEnded) {
        [self archiveItem:[self itemForGesture:gesture]];
    }
}

- (void)openFromGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]] && !CDPremiumBool(CDIslandInboxDomain, @"openOnSwipe", YES)) {
        return;
    }
    [self openItem:[self itemForGesture:gesture]];
}

- (void)replyFromGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan || !CDPremiumBool(CDIslandInboxDomain, @"quickReplies", YES)) {
        return;
    }
    CDIslandInboxItem *item = [self itemForGesture:gesture];
    if (item) {
        [self showReplyForItem:item];
    }
}

- (void)collapseButtonTapped:(__unused UIButton *)button {
    [self collapse];
}

- (void)showReplyForItem:(CDIslandInboxItem *)item {
    self.expanded = YES;
    self.replyItem = item;
    [self refreshAnimated:YES];

    CGFloat y = CGRectGetHeight(self.bounds) - 68.0;
    UIView *reply = [[UIView alloc] initWithFrame:CGRectMake(12.0, y, CGRectGetWidth(self.bounds) - 24.0, 56.0)];
    reply.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.30];
    reply.layer.cornerCurve = kCACornerCurveContinuous;
    reply.layer.cornerRadius = 18.0;
    [self addSubview:reply];
    self.replyView = reply;

    self.replyField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 10.0, CGRectGetWidth(reply.bounds) - 112.0, 36.0)];
    self.replyField.delegate = self;
    self.replyField.placeholder = @"Quick reply";
    self.replyField.textColor = [UIColor whiteColor];
    self.replyField.tintColor = CDIIAccent();
    self.replyField.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    self.replyField.returnKeyType = UIReturnKeySend;
    self.replyField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    self.replyField.layer.cornerCurve = kCACornerCurveContinuous;
    self.replyField.layer.cornerRadius = 12.0;
    self.replyField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 1.0)];
    self.replyField.leftViewMode = UITextFieldViewModeAlways;
    [reply addSubview:self.replyField];

    NSArray<NSString *> *canned = @[@"Got it", @"Later"];
    for (NSUInteger index = 0; index < canned.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(CGRectGetWidth(reply.bounds) - 92.0 + index * 43.0, 10.0, 39.0, 36.0);
        button.titleLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightBold];
        button.tintColor = [UIColor whiteColor];
        button.backgroundColor = [CDIIAccent() colorWithAlphaComponent:0.22];
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.layer.cornerRadius = 12.0;
        [button setTitle:canned[index] forState:UIControlStateNormal];
        button.tag = 9100 + index;
        [button addTarget:self action:@selector(cannedReplyTapped:) forControlEvents:UIControlEventTouchUpInside];
        [reply addSubview:button];
    }

    [self.replyField becomeFirstResponder];
    CDIIHaptic(UIImpactFeedbackStyleMedium);
}

- (void)cannedReplyTapped:(UIButton *)button {
    self.replyField.text = [button titleForState:UIControlStateNormal];
    [self sendReplyText:self.replyField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendReplyText:textField.text];
    return YES;
}

- (void)sendReplyText:(NSString *)text {
    NSString *trimmed = CDIITrim(text);
    if (!trimmed.length || !self.replyItem) {
        return;
    }
    [self endEditing:YES];
    CDVTShowToast([NSString stringWithFormat:@"Reply staged: %@", trimmed], CDIIAccent());
    CDIIHaptic(UIImpactFeedbackStyleMedium);
    CDIslandInboxItem *item = self.replyItem;
    self.replyItem = nil;
    if (CDPremiumBool(CDIslandInboxDomain, @"archiveOnReply", YES)) {
        [self archiveItem:item];
    } else {
        [self collapse];
    }
}

@end

static void CDIIPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!CDIIEnabled()) {
            UIWindow *window = CDVTKeyWindow();
            CDIslandInboxOverlay *overlay = objc_getAssociatedObject(window, &kCDIslandInboxOverlayKey);
            [overlay dismiss];
        }
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CDIIPreferencesChanged, CFSTR("com.chasedavis.islandinbox/preferences.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    NSLog(@"[IslandInbox] loaded observers");
}

%end

%hook UIView

- (void)didMoveToWindow {
    %orig;
    CDIICaptureIfNeeded(self);
}

- (void)layoutSubviews {
    %orig;
    CDIICaptureIfNeeded(self);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[IslandInbox] loaded");
        %init;
    }
}
