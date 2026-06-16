#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

UIView *CDSpotifyCreateReframePlayerView(void (^closeHandler)(void), void (^settingsHandler)(void));

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
