#import "SpotifyReframePlayerView.h"
#import <QuartzCore/QuartzCore.h>

@interface CDSpotifyReframePlayerView : UIView
@property (nonatomic, copy) void (^closeHandler)(void);
@property (nonatomic, copy) void (^settingsHandler)(void);
@property (nonatomic, assign) CGSize lastLayoutSize;
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) NSMutableArray<UIButton *> *playButtons;
@property (nonatomic, strong) UILabel *stateLabel;
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
    label.minimumScaleFactor = 0.74;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

static UIImage *CDSPSymbolImage(NSString *name, CGFloat pointSize, UIImageSymbolWeight weight) {
    UIImage *image = [UIImage systemImageNamed:name];
    if (!image) {
        return nil;
    }
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:pointSize weight:weight];
    return [image imageWithConfiguration:config];
}

static UIImageView *CDSPSymbol(NSString *name, CGFloat pointSize, UIColor *color) {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:CDSPSymbolImage(name, pointSize, UIImageSymbolWeightBold)];
    imageView.tintColor = color;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
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

static void CDSPApplyStroke(UIView *view, UIColor *color, CGFloat width) {
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = width;
}

static UILabel *CDSPPill(NSString *text, UIColor *textColor, UIColor *fillColor) {
    UILabel *label = CDSPLabel(text, [UIFont systemFontOfSize:10.5 weight:UIFontWeightBlack], textColor, 1);
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = fillColor;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.layer.cornerRadius = 9.0;
    label.clipsToBounds = YES;
    return label;
}

static UIButton *CDSPIconButton(NSString *symbolName, CGFloat pointSize, UIColor *tint, UIColor *fill) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *image = CDSPSymbolImage(symbolName, pointSize, UIImageSymbolWeightBold);
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    button.tintColor = tint;
    button.backgroundColor = fill;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    return button;
}

@implementation CDSpotifyReframePlayerView

- (instancetype)initWithCloseHandler:(void (^)(void))closeHandler settingsHandler:(void (^)(void))settingsHandler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _closeHandler = [closeHandler copy];
        _settingsHandler = [settingsHandler copy];
        _lastLayoutSize = CGSizeZero;
        _playing = YES;
        _playButtons = [NSMutableArray array];
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.accessibilityLabel = @"SpotifyReframe player shell";
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGSizeEqualToSize(self.bounds.size, self.lastLayoutSize)) {
        return;
    }
    self.lastLayoutSize = self.bounds.size;
    [self rebuildPlayer];
}

- (void)rebuildPlayer {
    for (UIView *view in [self.subviews copy]) {
        [view removeFromSuperview];
    }
    for (CALayer *layer in [self.layer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    self.playButton = nil;
    [self.playButtons removeAllObjects];
    self.stateLabel = nil;

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    if (width < 260.0 || height < 420.0) {
        return;
    }

    CAGradientLayer *base = [CAGradientLayer layer];
    base.frame = self.bounds;
    base.colors = @[
        (id)CDSPColor(3, 4, 3, 1.0).CGColor,
        (id)CDSPColor(8, 24, 14, 1.0).CGColor,
        (id)CDSPColor(9, 8, 14, 1.0).CGColor,
        (id)[UIColor blackColor].CGColor
    ];
    base.locations = @[@0.0, @0.34, @0.70, @1.0];
    [self.layer insertSublayer:base atIndex:0];

    CAGradientLayer *greenGlow = [CAGradientLayer layer];
    greenGlow.type = kCAGradientLayerRadial;
    greenGlow.frame = CGRectMake(width * 0.18, -height * 0.18, width * 0.88, height * 0.56);
    greenGlow.colors = @[
        (id)CDSPColor(30, 215, 96, 0.36).CGColor,
        (id)CDSPColor(30, 215, 96, 0.08).CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    greenGlow.locations = @[@0.0, @0.56, @1.0];
    [self.layer insertSublayer:greenGlow above:base];

    CAGradientLayer *violetGlow = [CAGradientLayer layer];
    violetGlow.type = kCAGradientLayerRadial;
    violetGlow.frame = CGRectMake(-width * 0.22, height * 0.44, width * 0.92, height * 0.46);
    violetGlow.colors = @[
        (id)CDSPColor(134, 75, 255, 0.26).CGColor,
        (id)CDSPColor(134, 75, 255, 0.06).CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    violetGlow.locations = @[@0.0, @0.58, @1.0];
    [self.layer insertSublayer:violetGlow above:greenGlow];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.alwaysBounceVertical = YES;
    [self addSubview:scrollView];

    CGFloat safeTop = self.safeAreaInsets.top;
    CGFloat safeBottom = self.safeAreaInsets.bottom;
    CGFloat contentWidth = MIN(width - 32.0, 430.0);
    CGFloat x = (width - contentWidth) / 2.0;
    CGFloat y = MAX(22.0, safeTop + 18.0);

    [self addHeaderToScrollView:scrollView x:x y:y width:contentWidth];
    y += 92.0;

    [self addArtworkStageToScrollView:scrollView x:x y:y width:contentWidth];
    CGFloat artSize = MIN(contentWidth - 42.0, height < 720.0 ? 250.0 : 292.0);
    y += artSize + 54.0;

    [self addTrackBlockToScrollView:scrollView x:x y:y width:contentWidth];
    y += 78.0;

    [self addProgressToScrollView:scrollView x:x y:y width:contentWidth];
    y += 58.0;

    [self addTransportToScrollView:scrollView x:x y:y width:contentWidth];
    y += 104.0;

    [self addModeCardsToScrollView:scrollView x:x y:y width:contentWidth];
    y += 116.0;

    [self addQueueToScrollView:scrollView x:x y:y width:contentWidth];
    y += 184.0;

    UILabel *footnote = CDSPLabel(@"Visual shell only. Spotify still owns playback and account state.", [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium], [[UIColor whiteColor] colorWithAlphaComponent:0.44], 2);
    footnote.textAlignment = NSTextAlignmentCenter;
    footnote.frame = CGRectMake(x, y, contentWidth, 38.0);
    [scrollView addSubview:footnote];
    y += 60.0;

    scrollView.contentSize = CGSizeMake(width, y + safeBottom + 18.0);
    [self addTopButtonsWithSafeTop:safeTop width:width];
}

- (void)addHeaderToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UILabel *eyebrow = CDSPLabel(@"SPOTIFYREFRAME", [UIFont systemFontOfSize:11.0 weight:UIFontWeightHeavy], CDSPColor(30, 215, 96, 1.0), 1);
    eyebrow.frame = CGRectMake(x, y, width - 96.0, 18.0);
    [scrollView addSubview:eyebrow];

    UILabel *title = CDSPLabel(@"Reframe Player", [UIFont systemFontOfSize:34.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(x, y + 20.0, width - 82.0, 42.0);
    [scrollView addSubview:title];

    UILabel *subtitle = CDSPLabel(@"A custom player shell built over the native app.", [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold], [[UIColor whiteColor] colorWithAlphaComponent:0.64], 1);
    subtitle.frame = CGRectMake(x, y + 61.0, width - 18.0, 22.0);
    [scrollView addSubview:subtitle];

    UIView *avatar = CDSPRoundedGradient(CGRectMake(x + width - 58.0, y + 16.0, 54.0, 54.0), @[CDSPColor(30, 215, 96, 1.0), CDSPColor(111, 82, 255, 1.0), CDSPColor(8, 8, 10, 1.0)], 27.0);
    CDSPApplyStroke(avatar, [[UIColor whiteColor] colorWithAlphaComponent:0.16], 1.0);
    UIImageView *person = CDSPSymbol(@"headphones", 25.0, [UIColor whiteColor]);
    person.frame = CGRectInset(avatar.bounds, 13.0, 13.0);
    [avatar addSubview:person];
    [scrollView addSubview:avatar];
}

- (void)addTopButtonsWithSafeTop:(CGFloat)safeTop width:(CGFloat)width {
    UIButton *settings = CDSPIconButton(@"slider.horizontal.3", 17.0, [UIColor whiteColor], [[UIColor whiteColor] colorWithAlphaComponent:0.10]);
    settings.accessibilityLabel = @"Open SpotifyReframe settings";
    settings.layer.cornerRadius = 18.0;
    settings.frame = CGRectMake(width - 96.0, MAX(12.0, safeTop + 10.0), 36.0, 36.0);
    [settings addTarget:self action:@selector(settingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:settings];

    UIButton *close = CDSPIconButton(@"xmark", 16.0, [UIColor whiteColor], [[UIColor whiteColor] colorWithAlphaComponent:0.10]);
    close.accessibilityLabel = @"Close Reframe player";
    close.layer.cornerRadius = 18.0;
    close.frame = CGRectMake(width - 52.0, MAX(12.0, safeTop + 10.0), 36.0, 36.0);
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];
}

- (void)addArtworkStageToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    CGFloat artSize = MIN(width - 42.0, CGRectGetHeight(self.bounds) < 720.0 ? 250.0 : 292.0);
    CGFloat artX = x + (width - artSize) / 2.0;

    UIView *halo = CDSPRoundedGradient(CGRectMake(artX - 18.0, y - 18.0, artSize + 36.0, artSize + 36.0), @[
        CDSPColor(30, 215, 96, 0.40),
        CDSPColor(126, 77, 255, 0.32),
        CDSPColor(252, 151, 83, 0.26)
    ], 34.0);
    halo.alpha = 0.46;
    [scrollView addSubview:halo];

    UIView *art = CDSPRoundedGradient(CGRectMake(artX, y, artSize, artSize), @[
        CDSPColor(250, 156, 82, 1.0),
        CDSPColor(224, 80, 134, 1.0),
        CDSPColor(113, 73, 246, 1.0),
        CDSPColor(4, 6, 8, 1.0)
    ], 28.0);
    CDSPApplyStroke(art, [[UIColor whiteColor] colorWithAlphaComponent:0.18], 1.0);
    art.layer.shadowColor = CDSPColor(30, 215, 96, 0.52).CGColor;
    art.layer.shadowOpacity = 0.34;
    art.layer.shadowRadius = 28.0;
    art.layer.shadowOffset = CGSizeMake(0.0, 18.0);
    [scrollView addSubview:art];

    CAGradientLayer *sun = [CAGradientLayer layer];
    sun.type = kCAGradientLayerRadial;
    sun.frame = CGRectMake(artSize * 0.15, artSize * 0.14, artSize * 0.70, artSize * 0.70);
    sun.colors = @[
        (id)CDSPColor(255, 243, 156, 0.96).CGColor,
        (id)CDSPColor(30, 215, 96, 0.40).CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    sun.locations = @[@0.0, @0.42, @1.0];
    [art.layer addSublayer:sun];

    for (NSInteger index = 0; index < 7; index++) {
        CGFloat ringSize = artSize * (0.28 + index * 0.095);
        CAShapeLayer *ring = [CAShapeLayer layer];
        ring.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake((artSize - ringSize) / 2.0, (artSize - ringSize) / 2.0, ringSize, ringSize)].CGPath;
        ring.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:index % 2 == 0 ? 0.12 : 0.06].CGColor;
        ring.fillColor = [UIColor clearColor].CGColor;
        ring.lineWidth = index == 0 ? 2.0 : 1.0;
        [art.layer addSublayer:ring];
    }

    UILabel *badge = CDSPPill(@"LIVE SHELL", [UIColor blackColor], CDSPColor(30, 215, 96, 1.0));
    badge.frame = CGRectMake(16.0, 16.0, 82.0, 28.0);
    [art addSubview:badge];

    UILabel *mix = CDSPLabel(@"NEON DRIVE", [UIFont systemFontOfSize:17.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    mix.frame = CGRectMake(18.0, artSize - 60.0, artSize - 36.0, 22.0);
    [art addSubview:mix];

    UILabel *hint = CDSPLabel(@"Session shell", [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold], [[UIColor whiteColor] colorWithAlphaComponent:0.70], 1);
    hint.frame = CGRectMake(18.0, artSize - 36.0, artSize - 36.0, 18.0);
    [art addSubview:hint];

    UIButton *play = CDSPIconButton(@"play.fill", 24.0, [UIColor whiteColor], CDSPColor(30, 215, 96, 1.0));
    play.layer.cornerRadius = 34.0;
    play.frame = CGRectMake(CGRectGetMaxX(art.frame) - 82.0, CGRectGetMaxY(art.frame) - 82.0, 68.0, 68.0);
    play.layer.shadowColor = CDSPColor(30, 215, 96, 0.80).CGColor;
    play.layer.shadowOpacity = 0.58;
    play.layer.shadowRadius = 20.0;
    play.layer.shadowOffset = CGSizeZero;
    [play addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:play];
    self.playButton = play;
    [self.playButtons addObject:play];
    [self updatePlayButton];
}

- (void)addTrackBlockToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UILabel *title = CDSPLabel(@"Black Hole - Acoustic Version", [UIFont systemFontOfSize:27.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.textAlignment = NSTextAlignmentCenter;
    title.frame = CGRectMake(x, y, width, 34.0);
    [scrollView addSubview:title];

    UILabel *artist = CDSPLabel(@"Griff", [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold], CDSPColor(30, 215, 96, 1.0), 1);
    artist.textAlignment = NSTextAlignmentCenter;
    artist.frame = CGRectMake(x, y + 35.0, width, 24.0);
    [scrollView addSubview:artist];

    UILabel *state = CDSPLabel(@"VISUAL PLAYING", [UIFont monospacedDigitSystemFontOfSize:11.0 weight:UIFontWeightBlack], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
    state.textAlignment = NSTextAlignmentCenter;
    state.frame = CGRectMake(x, y + 62.0, width, 16.0);
    [scrollView addSubview:state];
    self.stateLabel = state;
    [self updatePlayButton];
}

- (void)addProgressToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UIView *track = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, 6.0)];
    track.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.13];
    track.layer.cornerRadius = 3.0;
    [scrollView addSubview:track];

    UIView *fill = CDSPRoundedGradient(CGRectMake(0.0, 0.0, width * 0.44, 6.0), @[CDSPColor(30, 215, 96, 1.0), CDSPColor(128, 85, 255, 1.0)], 3.0);
    [track addSubview:fill];

    UIView *thumb = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(fill.frame) - 5.0, -4.0, 14.0, 14.0)];
    thumb.backgroundColor = [UIColor whiteColor];
    thumb.layer.cornerRadius = 7.0;
    [track addSubview:thumb];

    UILabel *elapsed = CDSPLabel(@"1:12", [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightBold], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
    elapsed.frame = CGRectMake(x, y + 14.0, 64.0, 18.0);
    [scrollView addSubview:elapsed];

    UILabel *remaining = CDSPLabel(@"3:48", [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightBold], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
    remaining.textAlignment = NSTextAlignmentRight;
    remaining.frame = CGRectMake(x + width - 64.0, y + 14.0, 64.0, 18.0);
    [scrollView addSubview:remaining];
}

- (void)addTransportToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    CGFloat centerX = x + width / 2.0;
    NSArray<NSArray *> *buttons = @[
        @[@"shuffle", @(-122.0), @(42.0), @NO],
        @[@"backward.fill", @(-64.0), @(50.0), @NO],
        @[@"forward.fill", @(64.0), @(50.0), @NO],
        @[@"list.bullet", @(122.0), @(42.0), @NO]
    ];
    for (NSArray *spec in buttons) {
        CGFloat size = [spec[2] doubleValue];
        UIButton *button = CDSPIconButton(spec[0], 20.0, [UIColor whiteColor], [[UIColor whiteColor] colorWithAlphaComponent:0.08]);
        button.layer.cornerRadius = size / 2.0;
        button.frame = CGRectMake(centerX + [spec[1] doubleValue] - size / 2.0, y + (78.0 - size) / 2.0, size, size);
        [scrollView addSubview:button];
    }

    UIButton *main = CDSPIconButton(@"pause.fill", 28.0, [UIColor blackColor], CDSPColor(30, 215, 96, 1.0));
    main.layer.cornerRadius = 39.0;
    main.frame = CGRectMake(centerX - 39.0, y, 78.0, 78.0);
    main.layer.shadowColor = CDSPColor(30, 215, 96, 0.72).CGColor;
    main.layer.shadowOpacity = 0.48;
    main.layer.shadowRadius = 20.0;
    main.layer.shadowOffset = CGSizeZero;
    [main addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:main];
    self.playButton = main;
    [self.playButtons addObject:main];
    [self updatePlayButton];
}

- (void)addModeCardsToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    NSArray<NSArray *> *items = @[
        @[@"Focus", @"Quiet queue", @"moon.fill", CDSPColor(94, 96, 255, 1.0)],
        @[@"Replay", @"Smart repeat", @"repeat", CDSPColor(30, 215, 96, 1.0)],
        @[@"Lyrics", @"Ready panel", @"quote.bubble.fill", CDSPColor(245, 137, 77, 1.0)]
    ];
    CGFloat gap = 10.0;
    CGFloat cardW = (width - gap * 2.0) / 3.0;
    for (NSInteger index = 0; index < (NSInteger)items.count; index++) {
        NSArray *item = items[index];
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(x + index * (cardW + gap), y, cardW, 94.0)];
        card.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.075];
        card.layer.cornerCurve = kCACornerCurveContinuous;
        card.layer.cornerRadius = 18.0;
        CDSPApplyStroke(card, [[UIColor whiteColor] colorWithAlphaComponent:0.10], 1.0);
        [scrollView addSubview:card];

        UIImageView *icon = CDSPSymbol(item[2], 20.0, item[3]);
        icon.frame = CGRectMake(12.0, 12.0, 24.0, 24.0);
        [card addSubview:icon];

        UILabel *title = CDSPLabel(item[0], [UIFont systemFontOfSize:15.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
        title.frame = CGRectMake(12.0, 48.0, cardW - 24.0, 20.0);
        [card addSubview:title];

        UILabel *subtitle = CDSPLabel(item[1], [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
        subtitle.frame = CGRectMake(12.0, 68.0, cardW - 24.0, 16.0);
        [card addSubview:subtitle];
    }
}

- (void)addQueueToScrollView:(UIScrollView *)scrollView x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    UILabel *title = CDSPLabel(@"Up Next", [UIFont systemFontOfSize:21.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
    title.frame = CGRectMake(x, y, width, 28.0);
    [scrollView addSubview:title];

    NSArray<NSArray *> *items = @[
        @[@"Neon Drive", @"LIVE mix · 82% matched", CDSPColor(205, 66, 188, 1.0), CDSPColor(33, 214, 198, 1.0)],
        @[@"Golden Hour", @"Made for this session", CDSPColor(251, 181, 73, 1.0), CDSPColor(227, 94, 122, 1.0)],
        @[@"Low Light", @"Chill queue", CDSPColor(66, 105, 246, 1.0), CDSPColor(83, 74, 125, 1.0)]
    ];

    CGFloat rowY = y + 42.0;
    for (NSArray *item in items) {
        UIVisualEffectView *row = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        row.frame = CGRectMake(x, rowY, width, 48.0);
        row.layer.cornerCurve = kCACornerCurveContinuous;
        row.layer.cornerRadius = 14.0;
        row.layer.masksToBounds = YES;
        CDSPApplyStroke(row, [[UIColor whiteColor] colorWithAlphaComponent:0.10], 1.0);
        [scrollView addSubview:row];

        UIView *thumb = CDSPRoundedGradient(CGRectMake(8.0, 8.0, 32.0, 32.0), @[item[2], item[3]], 8.0);
        [row.contentView addSubview:thumb];

        UILabel *track = CDSPLabel(item[0], [UIFont systemFontOfSize:14.0 weight:UIFontWeightBlack], [UIColor whiteColor], 1);
        track.frame = CGRectMake(52.0, 8.0, width - 106.0, 18.0);
        [row.contentView addSubview:track];

        UILabel *subtitle = CDSPLabel(item[1], [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold], [[UIColor whiteColor] colorWithAlphaComponent:0.58], 1);
        subtitle.frame = CGRectMake(52.0, 25.0, width - 106.0, 16.0);
        [row.contentView addSubview:subtitle];

        UIImageView *dots = CDSPSymbol(@"ellipsis", 18.0, [[UIColor whiteColor] colorWithAlphaComponent:0.58]);
        dots.frame = CGRectMake(width - 38.0, 15.0, 24.0, 18.0);
        [row.contentView addSubview:dots];

        rowY += 56.0;
    }
}

- (void)updatePlayButton {
    if (!self.playButton && self.playButtons.count == 0) {
        return;
    }
    NSString *symbol = self.playing ? @"pause.fill" : @"play.fill";
    UIImage *image = CDSPSymbolImage(symbol, 28.0, UIImageSymbolWeightBold);
    if (image) {
        for (UIButton *button in self.playButtons) {
            [button setImage:image forState:UIControlStateNormal];
        }
    }
    self.stateLabel.text = self.playing ? @"VISUAL PLAYING" : @"VISUAL PAUSED";
}

- (void)togglePlay {
    self.playing = !self.playing;
    [self updatePlayButton];
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

UIView *CDSpotifyCreateReframePlayerView(void (^closeHandler)(void), void (^settingsHandler)(void)) {
    return [[CDSpotifyReframePlayerView alloc] initWithCloseHandler:closeHandler settingsHandler:settingsHandler];
}
