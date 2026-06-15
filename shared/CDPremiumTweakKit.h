#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

BOOL CDPremiumBool(NSString *domain, NSString *key, BOOL fallback);
NSInteger CDPremiumInteger(NSString *domain, NSString *key, NSInteger fallback);
CGFloat CDPremiumFloat(NSString *domain, NSString *key, CGFloat fallback);
UIColor *CDPremiumTint(NSString *domain, UIColor *fallback);
UIVisualEffectView *CDPremiumPanel(UIWindow *window, const void *key, NSString *title, NSString *subtitle, UIColor *tint, CGFloat y, CGFloat width);
void CDPremiumDismissPanel(UIWindow *window, const void *key);
void CDPremiumToast(NSString *title, NSString *subtitle, UIColor *tint);

#ifdef __cplusplus
}
#endif
