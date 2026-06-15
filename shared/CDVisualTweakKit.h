#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#ifdef __cplusplus
extern "C" {
#endif

BOOL CDVTClassChainContains(UIView *view, NSArray<NSString *> *needles);
BOOL CDVTLooksLikeSurface(UIView *view, NSArray<NSString *> *needles, CGFloat minWidth, CGFloat minHeight, CGFloat maxWidth, CGFloat maxHeight);
UIColor *CDVTColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
void CDVTStyleSurface(UIView *view, UIColor *backgroundColor, UIColor *shadowColor, CGFloat cornerRadius, CGFloat shadowRadius);
void CDVTAddPulse(CALayer *layer, NSString *key, CGFloat fromOpacity, CGFloat toOpacity, CFTimeInterval duration);
void CDVTAddPop(CALayer *layer, NSString *key);
UIWindow *CDVTKeyWindow(void);
void CDVTShowToast(NSString *message, UIColor *tintColor);
void CDVTAddEdgeGlow(UIWindow *window, const void *key, UIColor *color, NSString *animationKey, CGFloat opacity);
void CDVTRemoveAssociatedView(UIWindow *window, const void *key);

#ifdef __cplusplus
}
#endif
