#import "SpotifyUIKitHomePreview.h"
#import <QuartzCore/QuartzCore.h>

@interface CDSpotifyUIKitHomePreviewView : UIView
@property (nonatomic, copy) void (^closeHandler)(void);
@property (nonatomic, copy) void (^settingsHandler)(void);
@property (nonatomic, assign) CGSize lastLayoutSize;
@end

static UIColor *CDSPColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha];
}

static UILabel *CDSPLabel(NSString *text, UIFont *font, UIColor *color, NSInteger lines) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.78;
    return label;
}

static UIView *CDSPRoundedGradient(CGRect frame, NSArray<UIColor *> *colors, CGFloat radius) {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    gradient.colors = cgColors;
    [view.layer insertSublayer:gradient atIndex:0];
    return view;
}

static UIImageView *CDSPSymbol(NSString *name, CGFloat pointSize, UIColor *color) {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:pointSize weight:UIImageSymbolWeightBold];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:name] imageWithConfiguration:config]];
    imageView.tintColor = color;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

@implementation CDSpotifyUIKitHomePreviewView

- (instancetype)initWithCloseHandler:(void (^)(void))closeHandler settingsHandler:(void (^)(void))settingsHandler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _closeHandler = [closeHandler copy];
        _settingsHandler = [settingsHandler copy];
        _lastLayoutSize = CGSizeZero;
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.accessibilityLabel = @"SpotifyReframe AI home preview";
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGSizeEqualToSize(self.bounds.size, self.lastLayoutSize)) {
        return;
    }
    self.lastLayoutSize = self.bounds.size;
    [self rebuildPreview];
}

- (void)rebuildPreview {
    for (UIView *view in [self.subviews copy]) {
        [view removeFromSuperview];
    }
    for (CALayer *layer in [self.layer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    if (width < 260.0 || height < 420.0) {
        return;
    }

    CAGradientLayer *base = [CAGradientLayer layer];
    base.frame = self.bounds;
    base.colors = @[
        (id)[UIColor blackColor].CGColor,
        (id)CDSPColor(5, 22, 14, 1.0).CGColor,
        (id)[UIColor blackColor].CGColor
    ];
    base.locations = @[@0.0, @0.42, @1.0];
    [self.layer insertSublayer:base atIndex:0];

    CAGradientLayer *glow = [CAGradientLayer layer];
    glow.type = kCAGradientLayerRadial;
    glow.frame = CGRectMake(width * 0.42, -height * 0.12, width * 0.88, height * 0.46);
    glow.colors = @[
        (id)CDSPColor(30, 215, 96, 0.46).CGColor,
        (id)CDSPColor(30, 215, 96, 0.06).CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    glow.locations = @[@0.0, @0.58, @1.0];
    [self.layer insertSublayer:glow above:base];

    CGFloat safeTop = self.safeAreaInsets.top;
    CGFloat safeBottom = self.safeAreaInsets.bottom;
    CGFloat contentWidth = MIN(width - 40.0, 430.0);
    CGFloat x = (width - contentWidth) / 2.0;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.alwaysBounceVertical = YES;
    [self addSubview:scrollView];

    CGFloat y = MAX(54.0, safeTop + 28.0);

    UILabel *title = CDSPLabel(@"Good morning, Chase", [UIFont systemFontOfSize:34.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(x, y, contentWidth - 128.0, 44.0);
    [scrollView addSubview:title];

    UILabel *aiPill = CDSPLabel(@"Spotify AI", [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold], CDSPColor(30, 215, 96, 1.0), 1);
    aiPill.textAlignment = NSTextAlignmentCenter;
    aiPill.frame = CGRectMake(x + contentWidth - 118.0, y + 2.0, 80.0, 32.0);
    aiPill.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.11];
    aiPill.layer.cornerCurve = kCACornerCurveContinuous;
    aiPill.layer.cornerRadius = 16.0;
    aiPill.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16].CGColor;
    aiPill.layer.borderWidth = 1.0;
    aiPill.clipsToBounds = YES;
    [scrollView addSubview:aiPill];

    UIView *avatar = CDSPRoundedGradient(CGRectMake(x + contentWidth - 54.0, y + 18.0, 50.0, 50.0), @[CDSPColor(38, 76, 54, 1.0), CDSPColor(218, 236, 222, 1.0)], 25.0);
    UIImageView *avatarIcon = CDSPSymbol(@"person.fill", 26.0, [[UIColor blackColor] colorWithAlphaComponent:0.70]);
    avatarIcon.frame = CGRectInset(avatar.bounds, 10.0, 9.0);
    [avatar addSubview:avatarIcon];
    [scrollView addSubview:avatar];

    y += 84.0;

    UIVisualEffectView *search = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    search.frame = CGRectMake(x, y, contentWidth, 52.0);
    search.layer.cornerCurve = kCACornerCurveContinuous;
    search.layer.cornerRadius = 26.0;
    search.layer.masksToBounds = YES;
    search.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor;
    search.layer.borderWidth = 1.0;
    [scrollView addSubview:search];

    UIImageView *searchIcon = CDSPSymbol(@"magnifyingglass", 19.0, [[UIColor whiteColor] colorWithAlphaComponent:0.70]);
    searchIcon.frame = CGRectMake(16.0, 16.0, 20.0, 20.0);
    [search.contentView addSubview:searchIcon];
    UILabel *searchText = CDSPLabel(@"What do you want to listen to?", [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium], [[UIColor whiteColor] colorWithAlphaComponent:0.72], 1);
    searchText.frame = CGRectMake(50.0, 0.0, contentWidth - 102.0, 52.0);
    [search.contentView addSubview:searchText];
    UIImageView *mic = CDSPSymbol(@"mic.fill", 19.0, CDSPColor(30, 215, 96, 1.0));
    mic.frame = CGRectMake(contentWidth - 42.0, 16.0, 20.0, 20.0);
    [search.contentView addSubview:mic];

    y += 94.0;

    [self addHeroToScrollView:scrollView x:x y:y width:contentWidth];
    y += 184.0;

    [self addSectionTitle:@"Jump back in" toScrollView:scrollView x:x y:y width:contentWidth];
    y += 32.0;
    [self addJumpBackToScrollView:scrollView x:x y:y width:contentWidth];
    y += 146.0;

    [self addSectionTitle:@"Made for you" toScrollView:scrollView x:x y:y width:contentWidth];
    y += 32.0;
    [self addMixesToScrollView:scrollView x:x y:y width:contentWidth];
    y += 120.0;

    [self addSectionTitle:@"AI Daily Picks" toScrollView:scrollView x:x y:y width:contentWidth];
    y += 32.0;
    [self addAIPicksToScrollView:scrollView x:x y:y width:contentWidth];
    y += 158.0;

    [self addSectionTitle:@"Live Moments" toScrollView:scrollView x:x y:y width:contentWidth];
    y += 32.0;
    [self addLiveMomentsToScrollView:scrollView x:x y:y width:contentWidth];
    y += 136.0;

    scrollView.contentSize = CGSizeMake(width, y + 150.0);

    [self addBottomChromeWithWidth:width height:height safeBottom:safeBottom contentWidth:contentWidth x:x];
    [self addTopButtonsWithSafeTop:safeTop width:width];
}

- (void)addTopButtonsWithSafeTop:(CGFloat)safeTop width:(CGFloat)width {
    UIButton *settings = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *settingsImage = [UIImage systemImageNamed:@"slider.horizontal.3"];
    if (settingsImage) {
        [settings setImage:settingsImage forState:UIControlStateNormal];
    } else {
        [settings setTitle:@"Settings" forState:UIControlStateNormal];
    }
    settings.accessibilityLabel = @"Open SpotifyReframe settings";
    settings.tintColor = [UIColor whiteColor];
    settings.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    settings.layer.cornerCurve = kCACornerCurveContinuous;
    settings.layer.cornerRadius = 17.0;
    settings.frame = CGRectMake(width - 92.0, MAX(14.0, safeTop + 10.0), 34.0, 34.0);
    [settings addTarget:self action:@selector(settingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:settings];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *closeImage = [UIImage systemImageNamed:@"xmark"];
    if (closeImage) {
        [close setImage:closeImage forState:UIControlStateNormal];
    } else {
        [close setTitle:@"Close" forState:UIControlStateNormal];
    }
    close.accessibilityLabel = @"Close AI home preview";
    close.tintColor = [UIColor whiteColor];
    close.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    close.layer.cornerCurve = kCACornerCurveContinuous;
    close.layer.cornerRadius = 17.0;
    close.frame = CGRectMake(width - 50.0, MAX(14.0, safeTop + 10.0), 34.0, 34.0);
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];
}

- (void)addHeroToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    CGFloat artW = MIN(204.0, width * 0.45);
    UIView *art = CDSPRoundedGradient(CGRectMake(x, y, artW, 150.0), @[CDSPColor(252, 151, 83, 1.0), CDSPColor(205, 78, 134, 1.0), [UIColor blackColor]], 14.0);
    UIImageView *sun = CDSPSymbol(@"sunset.fill", 58.0, [[UIColor whiteColor] colorWithAlphaComponent:0.28]);
    sun.frame = CGRectMake(16.0, 78.0, 64.0, 54.0);
    [art addSubview:sun];
    [scrollView addSubview:art];

    UIButton *play = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *playImage = [UIImage systemImageNamed:@"play.fill"];
    if (playImage) {
        [play setImage:playImage forState:UIControlStateNormal];
    }
    play.tintColor = [UIColor whiteColor];
    play.backgroundColor = CDSPColor(30, 215, 96, 1.0);
    play.layer.cornerRadius = 31.0;
    play.layer.shadowColor = CDSPColor(30, 215, 96, 0.72).CGColor;
    play.layer.shadowOpacity = 0.55;
    play.layer.shadowRadius = 18.0;
    play.frame = CGRectMake(CGRectGetMaxX(art.frame) - 42.0, y + 106.0, 62.0, 62.0);
    [scrollView addSubview:play];

    CGFloat textX = x + artW + 28.0;
    UILabel *headline = CDSPLabel(@"Good Vibes,\nBetter Days", [UIFont systemFontOfSize:30.0 weight:UIFontWeightBlack], [UIColor whiteColor], 2);
    headline.frame = CGRectMake(textX, y + 20.0, width - (textX - x), 74.0);
    [scrollView addSubview:headline];

    UILabel *sub = CDSPLabel(@"A playlist for you, Chase", [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium], [[UIColor whiteColor] colorWithAlphaComponent:0.76], 1);
    sub.frame = CGRectMake(textX, y + 98.0, width - (textX - x), 22.0);
    [scrollView addSubview:sub];

    UILabel *made = CDSPLabel(@"•  Made for you", [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold], CDSPColor(30, 215, 96, 1.0), 1);
    made.frame = CGRectMake(textX, y + 122.0, width - (textX - x), 22.0);
    [scrollView addSubview:made];
}

- (void)addSectionTitle:(NSString *)title toScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UILabel *label = CDSPLabel(title, [UIFont systemFontOfSize:20.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    label.frame = CGRectMake(x, y, width, 26.0);
    [scrollView addSubview:label];
}

- (void)addJumpBackToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UIScrollView *rail = [[UIScrollView alloc] initWithFrame:CGRectMake(x, y, width, 126.0)];
    rail.showsHorizontalScrollIndicator = NO;
    [scrollView addSubview:rail];

    NSArray<NSArray *> *items = @[
        @[@"The Weeknd", @"Blinding Lights · 3:20", CDSPColor(190, 34, 43, 1.0), CDSPColor(18, 18, 18, 1.0)],
        @[@"Chill Hits", @"Mood: Relaxed", CDSPColor(229, 194, 86, 1.0), CDSPColor(40, 120, 87, 1.0)],
        @[@"Tame Impala", @"Let It Happen · 3:45", CDSPColor(112, 61, 232, 1.0), CDSPColor(79, 38, 132, 1.0)],
        @[@"Summer Drive", @"Mood: Sunny", CDSPColor(63, 185, 202, 1.0), CDSPColor(232, 141, 67, 1.0)]
    ];
    CGFloat tx = 0.0;
    for (NSArray *item in items) {
        UIView *cover = CDSPRoundedGradient(CGRectMake(tx, 0.0, 112.0, 92.0), @[item[2], item[3]], 12.0);
        UIImageView *note = CDSPSymbol(@"music.note", 28.0, [[UIColor whiteColor] colorWithAlphaComponent:0.48]);
        note.frame = CGRectMake(12.0, 52.0, 30.0, 28.0);
        [cover addSubview:note];
        [rail addSubview:cover];

        UILabel *title = CDSPLabel(item[0], [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold], [UIColor whiteColor], 1);
        title.frame = CGRectMake(tx, 98.0, 112.0, 18.0);
        [rail addSubview:title];

        UILabel *sub = CDSPLabel(item[1], [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold], CDSPColor(30, 215, 96, 1.0), 1);
        sub.frame = CGRectMake(tx, 116.0, 112.0, 16.0);
        [rail addSubview:sub];
        tx += 126.0;
    }
    rail.contentSize = CGSizeMake(tx, 126.0);
}

- (void)addMixesToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UIScrollView *rail = [[UIScrollView alloc] initWithFrame:CGRectMake(x, y, width, 104.0)];
    rail.showsHorizontalScrollIndicator = NO;
    [scrollView addSubview:rail];

    NSArray<NSArray *> *items = @[
        @[@"Daily Mix 1", @"Your daily mix of new music", CDSPColor(48, 172, 94, 1.0), CDSPColor(35, 137, 156, 1.0)],
        @[@"Daily Mix 2", @"More of what you love", CDSPColor(83, 78, 178, 1.0), CDSPColor(141, 63, 197, 1.0)],
        @[@"On Repeat", @"Songs you love right now", CDSPColor(212, 88, 139, 1.0), CDSPColor(125, 72, 175, 1.0)]
    ];
    CGFloat tx = 0.0;
    for (NSArray *item in items) {
        UIView *card = CDSPRoundedGradient(CGRectMake(tx, 0.0, 158.0, 94.0), @[item[2], item[3]], 13.0);
        UILabel *title = CDSPLabel(item[0], [UIFont systemFontOfSize:17.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
        title.frame = CGRectMake(14.0, 48.0, 130.0, 22.0);
        [card addSubview:title];
        UILabel *sub = CDSPLabel(item[1], [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium], [[UIColor whiteColor] colorWithAlphaComponent:0.78], 1);
        sub.frame = CGRectMake(14.0, 70.0, 130.0, 17.0);
        [card addSubview:sub];
        CAShapeLayer *ring = [CAShapeLayer layer];
        ring.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(116.0, 12.0, 28.0, 28.0)].CGPath;
        ring.strokeColor = CDSPColor(30, 215, 96, 0.88).CGColor;
        ring.fillColor = [UIColor clearColor].CGColor;
        ring.lineWidth = 4.0;
        [card.layer addSublayer:ring];
        [rail addSubview:card];
        tx += 172.0;
    }
    rail.contentSize = CGSizeMake(tx, 104.0);
}

- (void)addAIPicksToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UIVisualEffectView *card = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    card.frame = CGRectMake(x, y, width, 126.0);
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.cornerRadius = 16.0;
    card.layer.masksToBounds = YES;
    [scrollView addSubview:card];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = card.bounds;
    gradient.colors = @[
        (id)CDSPColor(30, 215, 96, 0.48).CGColor,
        (id)CDSPColor(122, 64, 214, 0.46).CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.12].CGColor
    ];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    [card.contentView.layer insertSublayer:gradient atIndex:0];

    UILabel *title = CDSPLabel(@"AI Daily Picks", [UIFont systemFontOfSize:22.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(18.0, 18.0, width * 0.46, 28.0);
    [card.contentView addSubview:title];
    UILabel *sub = CDSPLabel(@"Smart picks, just for you", [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium], [[UIColor whiteColor] colorWithAlphaComponent:0.82], 1);
    sub.frame = CGRectMake(18.0, 48.0, width * 0.50, 20.0);
    [card.contentView addSubview:sub];
    UILabel *badge = CDSPLabel(@"AI", [UIFont systemFontOfSize:13.0 weight:UIFontWeightBlack], [UIColor blackColor], 1);
    badge.textAlignment = NSTextAlignmentCenter;
    badge.frame = CGRectMake(18.0, 78.0, 36.0, 26.0);
    badge.backgroundColor = CDSPColor(30, 215, 96, 1.0);
    badge.layer.cornerRadius = 7.0;
    badge.clipsToBounds = YES;
    [card.contentView addSubview:badge];

    NSArray<NSArray *> *pills = @[
        @[@"Neon Drive", @"LIVE", CDSPColor(230, 61, 182, 1.0)],
        @[@"Chill Vibes Lounge", @"82% MATCHED", CDSPColor(39, 202, 214, 1.0)],
        @[@"Global Trending", @"HOT", CDSPColor(247, 139, 45, 1.0)]
    ];
    CGFloat px = MAX(width - 218.0, 132.0);
    CGFloat py = 22.0;
    for (NSArray *pill in pills) {
        UIView *pillView = [[UIView alloc] initWithFrame:CGRectMake(px, py, MIN(198.0, width - px - 16.0), 34.0)];
        pillView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.40];
        pillView.layer.cornerCurve = kCACornerCurveContinuous;
        pillView.layer.cornerRadius = 9.0;
        pillView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor;
        pillView.layer.borderWidth = 1.0;
        [card.contentView addSubview:pillView];

        UIView *thumb = CDSPRoundedGradient(CGRectMake(7.0, 6.0, 22.0, 22.0), @[pill[2], [UIColor blackColor]], 5.0);
        [pillView addSubview:thumb];
        UILabel *ptitle = CDSPLabel(pill[0], [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold], [UIColor whiteColor], 1);
        ptitle.frame = CGRectMake(36.0, 5.0, CGRectGetWidth(pillView.bounds) - 44.0, 14.0);
        [pillView addSubview:ptitle];
        UILabel *psub = CDSPLabel(pill[1], [UIFont systemFontOfSize:9.0 weight:UIFontWeightBlack], pill[2], 1);
        psub.frame = CGRectMake(36.0, 18.0, CGRectGetWidth(pillView.bounds) - 44.0, 12.0);
        [pillView addSubview:psub];
        py += 38.0;
    }
}

- (void)addLiveMomentsToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    CGFloat gap = 14.0;
    CGFloat tileW = (width - gap) / 2.0;
    UIView *left = CDSPRoundedGradient(CGRectMake(x, y, tileW, 92.0), @[CDSPColor(48, 86, 178, 0.80), [UIColor blackColor]], 14.0);
    UILabel *leftTitle = CDSPLabel(@"Die With A Smile", [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold], [UIColor whiteColor], 1);
    leftTitle.frame = CGRectMake(12.0, 58.0, tileW - 24.0, 20.0);
    [left addSubview:leftTitle];
    [scrollView addSubview:left];

    UIView *right = CDSPRoundedGradient(CGRectMake(x + tileW + gap, y, tileW, 92.0), @[CDSPColor(212, 78, 148, 0.80), [UIColor blackColor]], 14.0);
    UILabel *rightTitle = CDSPLabel(@"Sabrina Live", [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold], [UIColor whiteColor], 1);
    rightTitle.frame = CGRectMake(12.0, 58.0, tileW - 24.0, 20.0);
    [right addSubview:rightTitle];
    [scrollView addSubview:right];
}

- (void)addBottomChromeWithWidth:(CGFloat)width height:(CGFloat)height safeBottom:(CGFloat)safeBottom contentWidth:(CGFloat)contentWidth x:(CGFloat)x {
    CGFloat tabHeight = 88.0 + safeBottom;
    UIVisualEffectView *tab = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    tab.frame = CGRectMake(0.0, height - tabHeight, width, tabHeight);
    tab.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:tab];

    NSArray<NSArray *> *tabs = @[
        @[@"house.fill", @"Home", @YES],
        @[@"magnifyingglass", @"Search", @NO],
        @[@"books.vertical", @"Your Library", @NO]
    ];
    CGFloat itemW = contentWidth / 3.0;
    for (NSInteger index = 0; index < (NSInteger)tabs.count; index++) {
        NSArray *tabItem = tabs[index];
        BOOL selected = [tabItem[2] boolValue];
        UIColor *color = selected ? CDSPColor(30, 215, 96, 1.0) : [[UIColor whiteColor] colorWithAlphaComponent:0.72];
        CGFloat tx = x + itemW * index;
        UIImageView *icon = CDSPSymbol(tabItem[0], 22.0, color);
        icon.frame = CGRectMake(tx + (itemW - 28.0) / 2.0, 13.0, 28.0, 26.0);
        [tab.contentView addSubview:icon];
        UILabel *label = CDSPLabel(tabItem[1], [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold], color, 1);
        label.textAlignment = NSTextAlignmentCenter;
        label.frame = CGRectMake(tx, 42.0, itemW, 18.0);
        [tab.contentView addSubview:label];
    }

    UIVisualEffectView *mini = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    mini.frame = CGRectMake(x, height - tabHeight - 74.0, contentWidth, 62.0);
    mini.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    mini.layer.cornerCurve = kCACornerCurveContinuous;
    mini.layer.cornerRadius = 17.0;
    mini.layer.masksToBounds = YES;
    mini.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor;
    mini.layer.borderWidth = 1.0;
    [self addSubview:mini];

    UIView *cover = CDSPRoundedGradient(CGRectMake(10.0, 8.0, 46.0, 46.0), @[CDSPColor(252, 151, 83, 1.0), CDSPColor(205, 78, 134, 1.0), [UIColor blackColor]], 8.0);
    [mini.contentView addSubview:cover];
    UILabel *song = CDSPLabel(@"Levitating", [UIFont systemFontOfSize:17.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    song.frame = CGRectMake(68.0, 12.0, contentWidth - 136.0, 22.0);
    [mini.contentView addSubview:song];
    UILabel *artist = CDSPLabel(@"Dua Lipa", [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold], CDSPColor(30, 215, 96, 1.0), 1);
    artist.frame = CGRectMake(68.0, 34.0, contentWidth - 136.0, 18.0);
    [mini.contentView addSubview:artist];
    UIButton *pause = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *pauseImage = [UIImage systemImageNamed:@"pause.fill"];
    if (pauseImage) {
        [pause setImage:pauseImage forState:UIControlStateNormal];
    }
    pause.tintColor = [UIColor whiteColor];
    pause.backgroundColor = CDSPColor(30, 215, 96, 1.0);
    pause.layer.cornerRadius = 23.0;
    pause.frame = CGRectMake(contentWidth - 56.0, 8.0, 46.0, 46.0);
    [mini.contentView addSubview:pause];
}

- (void)settingsTapped {
    if (self.settingsHandler) {
        self.settingsHandler();
    }
}

- (void)closeTapped {
    if (self.closeHandler) {
        self.closeHandler();
    }
}

@end

UIView *CDSpotifyCreateUIKitHomePreviewView(void (^closeHandler)(void), void (^settingsHandler)(void)) {
    return [[CDSpotifyUIKitHomePreviewView alloc] initWithCloseHandler:closeHandler settingsHandler:settingsHandler];
}
