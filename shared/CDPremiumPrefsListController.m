#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <spawn.h>

extern char **environ;

#ifndef CDPREFS_CLASS
#define CDPREFS_CLASS CDPremiumPrefsListController
#endif

static NSString *CDPremiumPrefsDomainFromSpecifier(PSSpecifier *specifier) {
    id domain = [specifier propertyForKey:@"defaults"];
    return [domain isKindOfClass:[NSString class]] ? domain : nil;
}

static void CDPremiumPrefsPostChange(NSString *domain) {
    if (!domain.length) {
        return;
    }
    CFPreferencesAppSynchronize((__bridge CFStringRef)domain);
    NSString *notification = [domain stringByAppendingString:@"/preferences.changed"];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)notification, NULL, NULL, true);
}

@interface CDPREFS_CLASS : PSListController
@end

@implementation CDPREFS_CLASS

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    CDPremiumPrefsPostChange(CDPremiumPrefsDomainFromSpecifier(specifier));
}

- (void)setSafeDefaults {
    NSString *domain = nil;
    for (PSSpecifier *specifier in [self specifiers]) {
        domain = CDPremiumPrefsDomainFromSpecifier(specifier);
        if (domain.length) {
            break;
        }
    }
    if (!domain.length) {
        return;
    }

    CFStringRef cfDomain = (__bridge CFStringRef)domain;
    CFPreferencesSetAppValue(CFSTR("enabled"), kCFBooleanFalse, cfDomain);
    CFPreferencesAppSynchronize(cfDomain);
    CDPremiumPrefsPostChange(domain);
    [self reloadSpecifiers];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Safe Defaults Applied" message:@"The tweak is disabled. Enable it again when you are ready to test." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)respring {
    pid_t pid = 0;
    char *sbreloadArgs[] = {"sbreload", NULL};
    if (posix_spawnp(&pid, "sbreload", NULL, NULL, sbreloadArgs, environ) == 0) {
        return;
    }

    char *killallArgs[] = {"killall", "SpringBoard", NULL};
    posix_spawnp(&pid, "killall", NULL, NULL, killallArgs, environ);
}

@end
