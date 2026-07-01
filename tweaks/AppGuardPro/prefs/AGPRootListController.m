#import "AGPRootListController.h"
#import <notify.h>

// Global settings page. Per-app lock/hide toggles live in AGPAppListController,
// reached via the "Choose Apps" link cell defined in Root.plist.
@implementation AGPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

// PSListController writes toggle/threshold values to our domain automatically
// (each specifier declares defaults=com.chasedavis.appguardpro + PostNotification).
// This hook fires on every change so the tweak reloads immediately.
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    notify_post("com.chasedavis.appguardpro/reload");
}

@end
