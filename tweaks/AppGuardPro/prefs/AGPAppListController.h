#import <Preferences/PSListController.h>

// Two modes: "lock" edits the lockedApps set, "hide" edits the hiddenApps set.
// The mode is passed via the specifier's userInfo from Root.plist.
@interface AGPAppListController : PSListController
@end
