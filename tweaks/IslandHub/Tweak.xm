#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CDVisualTweakKit.h"
#import "CDPremiumTweakKit.h"

static NSString *const CDIslandHubDomain = @"com.chasedavis.islandhub";
static BOOL gCDIslandHubRefreshing = NO;

@class CDIslandHubController;
static void CDIslandHubPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@interface CDIslandHubCard : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *module;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbolName;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, strong) UIColor *tintColor;
@end

@implementation CDIslandHubCard
@end

@interface CDIslandHubWindow : UIWindow
@end

@interface CDIslandHubView : UIView
@property (nonatomic, strong) NSArray<CDIslandHubCard *> *cards;
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;
@property (nonatomic, assign) NSInteger selectedSection;
@property (nonatomic, copy) NSString *clipboardPreview;
@property (nonatomic, assign) CGSize lastLayoutSize;
- (void)reloadWithCards:(NSArray<CDIslandHubCard *> *)cards;
@end

@interface CDIslandHubController : NSObject
@property (nonatomic, strong) CDIslandHubWindow *window;
@property (nonatomic, strong) CDIslandHubView *hubView;
@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, assign) BOOL focusRunning;
@property (nonatomic, strong) NSDate *focusStartDate;
+ (instancetype)sharedController;
- (void)start;
- (void)refresh;
- (void)toggleExpanded;
- (void)expandCommandCenter;
- (void)cycleSection:(NSInteger)delta;
- (void)performAction:(UIButton *)sender;
@end

static BOOL CDIHPrefsBool(NSString *key, BOOL fallback) {
    return CDPremiumBool(CDIslandHubDomain, key, fallback);
}

static NSInteger CDIHPrefsInteger(NSString *key, NSInteger fallback) {
    return CDPremiumInteger(CDIslandHubDomain, key, fallback);
}

static CGFloat CDIHPrefsFloat(NSString *key, CGFloat fallback, CGFloat minValue, CGFloat maxValue) {
    return CDPremiumClampedFloat(CDIslandHubDomain, key, fallback, minValue, maxValue);
}

static BOOL CDIHEnabled(void) {
    return CDIHPrefsBool(@"enabled", YES);
}

static UIColor *CDIHTint(void) {
    NSInteger palette = CDIHPrefsInteger(@"palette", 4);
    switch (palette) {
        case 1: return CDVTColor(255, 192, 88, 1.0);
        case 2: return CDVTColor(113, 229, 174, 1.0);
        case 3: return CDVTColor(255, 88, 108, 1.0);
        case 4: return CDVTColor(182, 121, 255, 1.0);
        default: return CDVTColor(92, 214, 255, 1.0);
    }
}

static NSString *CDIHSectionName(NSInteger section) {
    switch (section) {
        case 1: return @"Inbox";
        case 2: return @"Controls";
        case 3: return @"Music";
        case 4: return @"Focus";
        case 5: return @"Battery";
        case 6: return @"Privacy";
        case 7: return @"Clipboard";
        default: return @"Smart";
    }
}

static NSString *CDIHCardSection(CDIslandHubCard *card) {
    if ([card.module isEqualToString:@"inbox"]) return @"Inbox";
    if ([card.module isEqualToString:@"command"]) return @"Controls";
    if ([card.module isEqualToString:@"music"]) return @"Music";
    if ([card.module isEqualToString:@"focus"]) return @"Focus";
    if ([card.module isEqualToString:@"battery"]) return @"Battery";
    if ([card.module isEqualToString:@"privacy"]) return @"Privacy";
    if ([card.module isEqualToString:@"clipboard"]) return @"Clipboard";
    return @"Live";
}

static UIImage *CDIHSymbolImage(NSString *name, CGFloat size, UIImageSymbolWeight weight) {
    UIImage *image = [UIImage systemImageNamed:name ?: @"circle.fill"];
    if (!image) {
        return nil;
    }
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:size weight:weight];
    return [image imageWithConfiguration:config];
}

static UILabel *CDIHLabel(NSString *text, UIFont *font, UIColor *color, NSInteger lines) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.74;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

static UIButton *CDIHChipButton(NSString *title, NSInteger tag, UIColor *tint) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.tag = tag;
    button.titleLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightBlack];
    button.tintColor = [UIColor whiteColor];
    button.backgroundColor = [tint colorWithAlphaComponent:0.20];
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.cornerRadius = 13.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [tint colorWithAlphaComponent:0.30].CGColor;
    [button addTarget:[CDIslandHubController sharedController] action:@selector(performAction:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

static void CDIHFeedback(UIImpactFeedbackStyle style) {
    if (!CDIHPrefsBool(@"haptics", YES)) {
        return;
    }
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [generator impactOccurred];
}

@implementation CDIslandHubWindow
@end

@implementation CDIslandHubView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cards = @[];
        _selectedSection = CDIHPrefsInteger(@"defaultSection", 0);
        _lastLayoutSize = CGSizeZero;
        self.backgroundColor = [UIColor clearColor];
        self.layer.masksToBounds = NO;
        self.accessibilityLabel = @"IslandHub";

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[CDIslandHubController sharedController] action:@selector(toggleExpanded)];
        [self addGestureRecognizer:tap];

        UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:[CDIslandHubController sharedController] action:@selector(expandCommandCenter)];
        press.minimumPressDuration = 0.36;
        [self addGestureRecognizer:press];

        UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        left.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:left];

        UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        right.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:right];
    }
    return self;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    [[CDIslandHubController sharedController] cycleSection:gesture.direction == UISwipeGestureRecognizerDirectionLeft ? 1 : -1];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.bounds.size, self.lastLayoutSize)) {
        self.lastLayoutSize = self.bounds.size;
        [self rebuild];
    }
}

- (void)reloadWithCards:(NSArray<CDIslandHubCard *> *)cards {
    self.cards = cards ?: @[];
    [self rebuild];
}

- (void)setExpanded:(BOOL)expanded {
    if (_expanded == expanded) {
        return;
    }
    _expanded = expanded;
    [self rebuild];
}

- (NSArray<CDIslandHubCard *> *)visibleCards {
    if (self.selectedSection <= 0) {
        return self.cards;
    }
    NSString *section = CDIHSectionName(self.selectedSection);
    NSMutableArray<CDIslandHubCard *> *filtered = [NSMutableArray array];
    for (CDIslandHubCard *card in self.cards) {
        if ([CDIHCardSection(card) isEqualToString:section]) {
            [filtered addObject:card];
        }
    }
    return filtered.count ? filtered : self.cards;
}

- (void)rebuild {
    if (gCDIslandHubRefreshing) {
        return;
    }
    gCDIslandHubRefreshing = YES;
    for (UIView *view in [self.subviews copy]) {
        [view removeFromSuperview];
    }
    for (CALayer *layer in [self.layer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }

    UIColor *tint = CDIHTint();
    CGFloat glow = CDIHPrefsFloat(@"glowStrength", 0.72, 0.0, 1.0);
    self.layer.shadowColor = tint.CGColor;
    self.layer.shadowOpacity = self.expanded ? 0.32 + glow * 0.32 : 0.18 + glow * 0.30;
    self.layer.shadowRadius = self.expanded ? 28.0 + glow * 16.0 : 14.0 + glow * 12.0;
    self.layer.shadowOffset = CGSizeZero;

    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    panel.frame = self.bounds;
    panel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    panel.layer.cornerCurve = kCACornerCurveContinuous;
    panel.layer.cornerRadius = self.expanded ? 28.0 : CGRectGetHeight(self.bounds) / 2.0;
    panel.layer.masksToBounds = YES;
    panel.layer.borderColor = [tint colorWithAlphaComponent:0.36].CGColor;
    panel.layer.borderWidth = 1.0;
    panel.backgroundColor = [tint colorWithAlphaComponent:0.08];
    [self addSubview:panel];

    CAGradientLayer *wash = [CAGradientLayer layer];
    wash.frame = panel.bounds;
    wash.startPoint = CGPointMake(0.0, 0.0);
    wash.endPoint = CGPointMake(1.0, 1.0);
    wash.colors = @[
        (id)[tint colorWithAlphaComponent:self.expanded ? 0.22 : 0.14].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.28].CGColor,
        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.045].CGColor
    ];
    [panel.contentView.layer insertSublayer:wash atIndex:0];

    if (self.expanded) {
        [self buildExpandedInView:panel.contentView tint:tint];
    } else {
        [self buildCompactInView:panel.contentView tint:tint];
    }
    gCDIslandHubRefreshing = NO;
}

- (void)buildCompactInView:(UIView *)contentView tint:(UIColor *)tint {
    NSArray<CDIslandHubCard *> *cards = [self visibleCards];
    CDIslandHubCard *card = cards.firstObject;
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);

    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(13.0, (height - 18.0) / 2.0, 18.0, 18.0)];
    dot.backgroundColor = card.tintColor ?: tint;
    dot.layer.cornerRadius = 9.0;
    dot.layer.shadowColor = dot.backgroundColor.CGColor;
    dot.layer.shadowOpacity = 0.60;
    dot.layer.shadowRadius = 8.0;
    dot.layer.shadowOffset = CGSizeZero;
    [contentView addSubview:dot];

    UIImageView *icon = [[UIImageView alloc] initWithImage:CDIHSymbolImage(card.symbolName ?: @"sparkles", 10.0, UIImageSymbolWeightBlack)];
    icon.tintColor = [UIColor blackColor];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.frame = CGRectInset(dot.bounds, 4.0, 4.0);
    [dot addSubview:icon];

    UILabel *title = CDIHLabel(card.title ?: @"IslandHub", [UIFont systemFontOfSize:13.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(39.0, 7.0, width - 78.0, 16.0);
    [contentView addSubview:title];

    UILabel *subtitle = CDIHLabel(card.subtitle ?: @"Priority stack ready", [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
    subtitle.frame = CGRectMake(39.0, 22.0, width - 78.0, 13.0);
    [contentView addSubview:subtitle];

    UILabel *count = CDIHLabel([NSString stringWithFormat:@"%lu", (unsigned long)self.cards.count], [UIFont monospacedDigitSystemFontOfSize:11.0 weight:UIFontWeightBlack], [UIColor blackColor], 1);
    count.textAlignment = NSTextAlignmentCenter;
    count.backgroundColor = tint;
    count.layer.cornerCurve = kCACornerCurveContinuous;
    count.layer.cornerRadius = 9.0;
    count.clipsToBounds = YES;
    count.frame = CGRectMake(width - 31.0, (height - 18.0) / 2.0, 18.0, 18.0);
    [contentView addSubview:count];
}

- (void)buildExpandedInView:(UIView *)contentView tint:(UIColor *)tint {
    CGFloat width = CGRectGetWidth(self.bounds);
    UILabel *title = CDIHLabel(@"IslandHub", [UIFont systemFontOfSize:21.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(18.0, 14.0, width - 126.0, 26.0);
    [contentView addSubview:title];

    UILabel *section = CDIHLabel(CDIHSectionName(self.selectedSection), [UIFont systemFontOfSize:11.0 weight:UIFontWeightBlack], tint, 1);
    section.textAlignment = NSTextAlignmentCenter;
    section.backgroundColor = [tint colorWithAlphaComponent:0.16];
    section.layer.cornerCurve = kCACornerCurveContinuous;
    section.layer.cornerRadius = 11.0;
    section.clipsToBounds = YES;
    section.frame = CGRectMake(width - 96.0, 16.0, 78.0, 22.0);
    [contentView addSubview:section];

    NSArray<NSString *> *tabTitles = @[@"Smart", @"Inbox", @"Controls", @"Music", @"Focus", @"Battery", @"Privacy", @"Clipboard"];
    UIScrollView *tabs = [[UIScrollView alloc] initWithFrame:CGRectMake(14.0, 48.0, width - 28.0, 32.0)];
    tabs.showsHorizontalScrollIndicator = NO;
    [contentView addSubview:tabs];

    CGFloat cursor = 0.0;
    for (NSInteger idx = 0; idx < (NSInteger)tabTitles.count; idx++) {
        NSString *tab = tabTitles[idx];
        CGFloat tabWidth = MAX(58.0, [tab sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold]}].width + 24.0);
        UILabel *pill = CDIHLabel(tab, [UIFont systemFontOfSize:11.0 weight:UIFontWeightBlack], idx == self.selectedSection ? [UIColor blackColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.74], 1);
        pill.textAlignment = NSTextAlignmentCenter;
        pill.backgroundColor = idx == self.selectedSection ? tint : [[UIColor whiteColor] colorWithAlphaComponent:0.08];
        pill.layer.cornerCurve = kCACornerCurveContinuous;
        pill.layer.cornerRadius = 13.0;
        pill.clipsToBounds = YES;
        pill.frame = CGRectMake(cursor, 3.0, tabWidth, 26.0);
        [tabs addSubview:pill];
        cursor += tabWidth + 8.0;
    }
    tabs.contentSize = CGSizeMake(cursor, 32.0);

    NSArray<CDIslandHubCard *> *cards = [self visibleCards];
    NSInteger maxRows = MAX(3, MIN(8, CDIHPrefsInteger(@"maxStackItems", 5)));
    CGFloat rowY = 90.0;
    NSInteger rows = MIN(maxRows, (NSInteger)cards.count);
    for (NSInteger index = 0; index < rows; index++) {
        CDIslandHubCard *card = cards[index];
        [contentView addSubview:[self rowForCard:card index:index y:rowY tint:tint]];
        rowY += 42.0;
    }

    CGFloat actionY = CGRectGetHeight(self.bounds) - 45.0;
    NSArray<NSArray *> *actions = @[
        @[@"Controls", @2],
        @[@"Clipboard", @7],
        @[@"Focus", @4],
        @[@"Collapse", @99]
    ];
    CGFloat gap = 8.0;
    CGFloat actionWidth = (width - 28.0 - gap * (actions.count - 1)) / actions.count;
    for (NSInteger index = 0; index < (NSInteger)actions.count; index++) {
        UIButton *button = CDIHChipButton(actions[index][0], [actions[index][1] integerValue], tint);
        button.frame = CGRectMake(14.0 + index * (actionWidth + gap), actionY, actionWidth, 28.0);
        [contentView addSubview:button];
    }
}

- (UIView *)rowForCard:(CDIslandHubCard *)card index:(NSInteger)index y:(CGFloat)y tint:(UIColor *)tint {
    CGFloat width = CGRectGetWidth(self.bounds) - 28.0;
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(14.0, y, width, 34.0)];
    row.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:index == 0 ? 0.13 : 0.075];
    row.layer.cornerCurve = kCACornerCurveContinuous;
    row.layer.cornerRadius = 13.0;
    row.layer.borderColor = [(card.tintColor ?: tint) colorWithAlphaComponent:index == 0 ? 0.34 : 0.14].CGColor;
    row.layer.borderWidth = 1.0;

    UIView *iconBack = [[UIView alloc] initWithFrame:CGRectMake(8.0, 7.0, 20.0, 20.0)];
    iconBack.backgroundColor = (card.tintColor ?: tint);
    iconBack.layer.cornerRadius = 10.0;
    [row addSubview:iconBack];

    UIImageView *icon = [[UIImageView alloc] initWithImage:CDIHSymbolImage(card.symbolName ?: @"sparkles", 10.0, UIImageSymbolWeightBlack)];
    icon.tintColor = [UIColor blackColor];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.frame = CGRectInset(iconBack.bounds, 5.0, 5.0);
    [iconBack addSubview:icon];

    UILabel *title = CDIHLabel(card.title, [UIFont systemFontOfSize:12.5 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(38.0, 4.0, width - 112.0, 15.0);
    [row addSubview:title];

    UILabel *subtitle = CDIHLabel(card.subtitle, [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
    subtitle.frame = CGRectMake(38.0, 18.0, width - 112.0, 13.0);
    [row addSubview:subtitle];

    UILabel *priority = CDIHLabel([NSString stringWithFormat:@"%ld", (long)card.priority], [UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightBlack], [[UIColor whiteColor] colorWithAlphaComponent:0.62], 1);
    priority.textAlignment = NSTextAlignmentRight;
    priority.frame = CGRectMake(width - 56.0, 9.0, 44.0, 16.0);
    [row addSubview:priority];

    return row;
}

@end

@implementation CDIslandHubController

+ (instancetype)sharedController {
    static CDIslandHubController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [CDIslandHubController new];
    });
    return controller;
}

- (void)start {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIApplicationDidBecomeActiveNotification object:nil];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CDIslandHubPrefsChanged, CFSTR("com.chasedavis.islandhub/preferences.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:12.0 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    [self refresh];
}

- (void)ensureWindow {
    if (self.window) {
        return;
    }
    self.window = [[CDIslandHubWindow alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                self.window.windowScene = (UIWindowScene *)scene;
                break;
            }
        }
    }
    self.window.windowLevel = UIWindowLevelStatusBar + 76.0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.userInteractionEnabled = YES;
    self.window.clipsToBounds = NO;

    self.rootViewController = [UIViewController new];
    self.rootViewController.view.backgroundColor = [UIColor clearColor];
    self.rootViewController.view.userInteractionEnabled = YES;
    self.window.rootViewController = self.rootViewController;

    self.hubView = [[CDIslandHubView alloc] initWithFrame:CGRectZero];
    self.hubView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.rootViewController.view addSubview:self.hubView];
    self.window.hidden = NO;
}

- (void)refresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!CDIHEnabled()) {
            self.window.hidden = YES;
            return;
        }
        [self ensureWindow];
        self.window.hidden = NO;
        [self layoutHubAnimated:YES];
        [self.hubView reloadWithCards:[self currentCards]];
    });
}

- (void)layoutHubAnimated:(BOOL)animated {
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    UIWindow *keyWindow = CDVTKeyWindow();
    if (keyWindow) {
        safeInsets = keyWindow.safeAreaInsets;
    }

    CGFloat verticalOffset = CDIHPrefsFloat(@"verticalOffset", 0.0, -18.0, 58.0);
    CGFloat top = MAX(6.0, safeInsets.top + 2.0 + verticalOffset);
    CGFloat compactWidth = CDIHPrefsFloat(@"compactWidth", 174.0, 130.0, 260.0);
    CGFloat width = self.hubView.isExpanded ? MIN(screenWidth - 20.0, 408.0) : compactWidth;
    CGFloat height = self.hubView.isExpanded ? CDIHPrefsFloat(@"expandedHeight", 266.0, 210.0, 360.0) : 38.0;
    CGRect target = CGRectMake((screenWidth - width) / 2.0, top, width, height);

    void (^changes)(void) = ^{
        self.window.frame = target;
        self.rootViewController.view.frame = self.window.bounds;
        self.hubView.frame = self.rootViewController.view.bounds;
    };
    if (animated) {
        [UIView animateWithDuration:0.22 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)toggleExpanded {
    CDIHFeedback(UIImpactFeedbackStyleLight);
    self.hubView.expanded = !self.hubView.isExpanded;
    [self layoutHubAnimated:YES];
    [self.hubView reloadWithCards:[self currentCards]];
}

- (void)expandCommandCenter {
    CDIHFeedback(UIImpactFeedbackStyleMedium);
    self.hubView.selectedSection = 2;
    self.hubView.expanded = YES;
    [self layoutHubAnimated:YES];
    [self.hubView reloadWithCards:[self currentCards]];
}

- (void)cycleSection:(NSInteger)delta {
    CDIHFeedback(UIImpactFeedbackStyleLight);
    NSInteger section = self.hubView.selectedSection + delta;
    if (section < 0) {
        section = 7;
    } else if (section > 7) {
        section = 0;
    }
    self.hubView.selectedSection = section;
    self.hubView.expanded = YES;
    [self layoutHubAnimated:YES];
    [self.hubView reloadWithCards:[self currentCards]];
}

- (void)performAction:(UIButton *)sender {
    CDIHFeedback(UIImpactFeedbackStyleMedium);
    if (sender.tag == 99) {
        self.hubView.expanded = NO;
    } else if (sender.tag == 7) {
        NSString *clip = [UIPasteboard generalPasteboard].string;
        if (!clip.length) {
            self.hubView.clipboardPreview = @"Clipboard is empty";
        } else {
            NSString *singleLine = [[clip componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
            self.hubView.clipboardPreview = singleLine.length > 48 ? [[singleLine substringToIndex:48] stringByAppendingString:@"..."] : singleLine;
        }
        self.hubView.selectedSection = 7;
        self.hubView.expanded = YES;
    } else {
        self.hubView.selectedSection = sender.tag;
        self.hubView.expanded = YES;
    }

    if (sender.tag == 4) {
        self.focusRunning = !self.focusRunning;
        self.focusStartDate = self.focusRunning ? [NSDate date] : nil;
    }

    [self layoutHubAnimated:YES];
    [self.hubView reloadWithCards:[self currentCards]];
}

- (NSArray<CDIslandHubCard *> *)currentCards {
    NSMutableArray<CDIslandHubCard *> *cards = [NSMutableArray array];
    UIColor *tint = CDIHTint();

    [cards addObject:[self cardWithIdentifier:@"dashboard" module:@"dashboard" title:@"IslandHub Core" subtitle:@"Priority engine online" symbol:@"sparkles" priority:35 tint:tint]];

    if (CDIHPrefsBool(@"moduleEmergency", YES)) {
        [cards addObject:[self cardWithIdentifier:@"emergency" module:@"emergency" title:@"Emergency Island" subtitle:@"Safety mode is ready, not armed" symbol:@"sos" priority:65 tint:CDVTColor(255, 88, 108, 1.0)]];
    }
    if (CDIHPrefsBool(@"modulePrivacy", YES)) {
        [cards addObject:[self cardWithIdentifier:@"privacy" module:@"privacy" title:@"Privacy Radar" subtitle:@"Local radar armed; live sensors deferred" symbol:@"shield.lefthalf.filled" priority:80 tint:CDVTColor(255, 88, 108, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleInbox", YES)) {
        [cards addObject:[self cardWithIdentifier:@"inbox" module:@"inbox" title:@"Island Inbox" subtitle:@"Queue surface ready" symbol:@"tray.full.fill" priority:60 tint:CDVTColor(92, 214, 255, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleCommand", YES)) {
        [cards addObject:[self cardWithIdentifier:@"command" module:@"command" title:@"Command Center" subtitle:@"Long press Island for controls" symbol:@"switch.2" priority:58 tint:CDVTColor(182, 121, 255, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleFocus", YES)) {
        NSString *subtitle = self.focusRunning ? [NSString stringWithFormat:@"Deep work %.0fm running", MAX(1.0, -[self.focusStartDate timeIntervalSinceNow] / 60.0)] : @"Tap Focus to start a local streak";
        [cards addObject:[self cardWithIdentifier:@"focus" module:@"focus" title:@"Focus Boss Bar" subtitle:subtitle symbol:@"flame.fill" priority:self.focusRunning ? 74 : 52 tint:CDVTColor(255, 154, 74, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleBattery", YES)) {
        [cards addObject:[self batteryCard]];
    }
    if (CDIHPrefsBool(@"moduleNowPlaying", YES)) {
        [cards addObject:[self cardWithIdentifier:@"music" module:@"music" title:@"Now Playing Pro" subtitle:@"Media controls shell ready" symbol:@"waveform" priority:50 tint:CDVTColor(113, 229, 174, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleClipboard", YES)) {
        NSString *subtitle = self.hubView.clipboardPreview.length ? self.hubView.clipboardPreview : @"Tap Clipboard to inspect locally";
        [cards addObject:[self cardWithIdentifier:@"clipboard" module:@"clipboard" title:@"Clipboard Island" subtitle:subtitle symbol:@"doc.on.clipboard.fill" priority:self.hubView.clipboardPreview.length ? 62 : 45 tint:CDVTColor(255, 212, 94, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleTransfers", YES)) {
        [cards addObject:[self cardWithIdentifier:@"transfers" module:@"transfers" title:@"Transfer Hub" subtitle:@"Progress widgets staged" symbol:@"arrow.up.arrow.down.circle.fill" priority:38 tint:CDVTColor(92, 214, 255, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleGym", YES)) {
        [cards addObject:[self cardWithIdentifier:@"gym" module:@"gym" title:@"Gym Island" subtitle:@"Rest timer and set HUD staged" symbol:@"figure.strengthtraining.traditional" priority:36 tint:CDVTColor(113, 229, 174, 1.0)]];
    }
    if (CDIHPrefsBool(@"modulePrayer", YES)) {
        [cards addObject:[self cardWithIdentifier:@"prayer" module:@"prayer" title:@"Prayer Focus" subtitle:@"John 15:5 reminder ready" symbol:@"book.closed.fill" priority:34 tint:CDVTColor(255, 212, 94, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleHabits", YES)) {
        [cards addObject:[self cardWithIdentifier:@"habits" module:@"habits" title:@"Habit Streaks" subtitle:@"Water, mood, gratitude cards ready" symbol:@"checkmark.seal.fill" priority:32 tint:CDVTColor(182, 121, 255, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleSwitcher", YES)) {
        [cards addObject:[self cardWithIdentifier:@"switcher" module:@"switcher" title:@"Island Switcher" subtitle:@"Recent app carousel staged" symbol:@"rectangle.stack.fill" priority:30 tint:CDVTColor(92, 214, 255, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleETA", NO)) {
        [cards addObject:[self cardWithIdentifier:@"eta" module:@"eta" title:@"Life ETA Stack" subtitle:@"Manual timers staged" symbol:@"clock.badge.checkmark.fill" priority:44 tint:CDVTColor(255, 154, 74, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleBusiness", NO)) {
        [cards addObject:[self cardWithIdentifier:@"business" module:@"business" title:@"Business & DevOps" subtitle:@"Sales/deploy cards staged locally" symbol:@"chart.line.uptrend.xyaxis" priority:42 tint:CDVTColor(255, 212, 94, 1.0)]];
    }
    if (CDIHPrefsBool(@"moduleAI", NO)) {
        [cards addObject:[self cardWithIdentifier:@"ai" module:@"ai" title:@"AI Copilot" subtitle:@"Local prompt surface only in v1" symbol:@"brain.head.profile" priority:40 tint:CDVTColor(182, 121, 255, 1.0)]];
    }

    [cards sortUsingComparator:^NSComparisonResult(CDIslandHubCard *a, CDIslandHubCard *b) {
        if (a.priority == b.priority) {
            return [a.title compare:b.title];
        }
        return a.priority > b.priority ? NSOrderedAscending : NSOrderedDescending;
    }];

    if (CDIHPrefsBool(@"hideWhenIdle", NO) && cards.count <= 1) {
        return @[];
    }
    return cards;
}

- (CDIslandHubCard *)batteryCard {
    UIDevice *device = [UIDevice currentDevice];
    CGFloat rawLevel = device.batteryLevel;
    NSInteger percent = rawLevel < 0 ? 0 : (NSInteger)round(rawLevel * 100.0);
    NSString *state = @"Battery";
    NSInteger priority = 40;
    UIColor *tint = CDVTColor(113, 229, 174, 1.0);
    if (device.batteryState == UIDeviceBatteryStateCharging || device.batteryState == UIDeviceBatteryStateFull) {
        state = @"Charging";
        priority = 68;
        tint = CDVTColor(255, 212, 94, 1.0);
    } else if (percent > 0 && percent <= 20) {
        state = @"Low Power";
        priority = 72;
        tint = CDVTColor(255, 88, 108, 1.0);
    }
    NSString *subtitle = percent > 0 ? [NSString stringWithFormat:@"%@ %ld%%", state, (long)percent] : @"Battery monitor ready";
    return [self cardWithIdentifier:@"battery" module:@"battery" title:@"Smart Battery" subtitle:subtitle symbol:@"battery.100.bolt" priority:priority tint:tint];
}

- (CDIslandHubCard *)cardWithIdentifier:(NSString *)identifier module:(NSString *)module title:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol priority:(NSInteger)priority tint:(UIColor *)tint {
    CDIslandHubCard *card = [CDIslandHubCard new];
    card.identifier = identifier;
    card.module = module;
    card.title = title;
    card.subtitle = subtitle;
    card.symbolName = symbol;
    card.priority = priority;
    card.tintColor = tint ?: CDIHTint();
    return card;
}

@end

static void CDIslandHubPrefsChanged(__unused CFNotificationCenterRef center, __unused void *observer, __unused CFStringRef name, __unused const void *object, __unused CFDictionaryRef userInfo) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)CDIslandHubDomain);
    [[CDIslandHubController sharedController] refresh];
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[CDIslandHubController sharedController] start];
    });
}
%end

%ctor {
    @autoreleasepool {
        if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
            NSLog(@"[IslandHub] loaded");
            %init;
        }
    }
}
