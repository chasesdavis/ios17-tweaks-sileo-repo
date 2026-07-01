#import "AGPAppListController.h"
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>
#import <notify.h>

static NSString *const kPrefsDomain = @"com.chasedavis.appguardpro";

// Private LSApplicationWorkspace surface for enumerating installed apps.
@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *applicationType;   // User / System
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allApplications;
@end

@interface AGPAppListController ()
@property (nonatomic, copy) NSString *prefKey;   // "lockedApps" or "hiddenApps"
@end

@implementation AGPAppListController

// The Root.plist link passes userInfo = { mode = "lock" | "hide" }.
- (NSString *)prefKey {
    if (!_prefKey) {
        NSString *mode = [self.specifier propertyForKey:@"mode"] ?: @"lock";
        _prefKey = [mode isEqualToString:@"hide"] ? @"hiddenApps" : @"lockedApps";
    }
    return _prefKey;
}

- (NSMutableSet<NSString *> *)currentSet {
    CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)self.prefKey,
                                                    (__bridge CFStringRef)kPrefsDomain);
    NSArray *arr = (__bridge_transfer NSArray *)v;
    if ([arr isKindOfClass:[NSArray class]]) return [NSMutableSet setWithArray:arr];
    return [NSMutableSet set];
}

- (void)saveSet:(NSSet<NSString *> *)set {
    CFPreferencesSetAppValue((__bridge CFStringRef)self.prefKey,
                             (__bridge CFArrayRef)set.allObjects,
                             (__bridge CFStringRef)kPrefsDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefsDomain);
    notify_post("com.chasedavis.appguardpro/reload");
}

- (NSArray<LSApplicationProxy *> *)userApps {
    LSApplicationWorkspace *ws = [objc_getClass("LSApplicationWorkspace") defaultWorkspace];
    NSMutableArray *out = [NSMutableArray array];
    for (LSApplicationProxy *app in [ws allApplications]) {
        // Only user-installed apps; skip system/hidden bookkeeping apps.
        if ([app.applicationType isEqualToString:@"User"] && app.localizedName.length) {
            [out addObject:app];
        }
    }
    [out sortUsingComparator:^NSComparisonResult(LSApplicationProxy *a, LSApplicationProxy *b) {
        return [a.localizedName localizedCaseInsensitiveCompare:b.localizedName];
    }];
    return out;
}

// Build one switch specifier per installed app; state reflects membership in the set.
- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];
        NSString *title = [self.prefKey isEqualToString:@"hiddenApps"] ? @"Hidden Apps" : @"Locked Apps";

        PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:title
                                                            target:self
                                                               set:NULL
                                                               get:NULL
                                                            detail:Nil
                                                              cell:PSGroupCell
                                                              edit:Nil];
        [group setProperty:@"Toggle apps to include. Changes apply immediately." forKey:@"footerText"];
        [specs addObject:group];

        for (LSApplicationProxy *app in [self userApps]) {
            PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:app.localizedName
                                                            target:self
                                                               set:@selector(setValue:forApp:)
                                                               get:@selector(valueForApp:)
                                                            detail:Nil
                                                              cell:PSSwitchCell
                                                              edit:Nil];
            [s setProperty:app.applicationIdentifier forKey:@"bundleID"];
            [specs addObject:s];
        }
        _specifiers = specs;
    }
    return _specifiers;
}

- (id)valueForApp:(PSSpecifier *)specifier {
    NSString *bid = [specifier propertyForKey:@"bundleID"];
    return @([[self currentSet] containsObject:bid]);
}

- (void)setValue:(id)value forApp:(PSSpecifier *)specifier {
    NSString *bid = [specifier propertyForKey:@"bundleID"];
    if (!bid) return;
    NSMutableSet *set = [self currentSet];
    if ([value boolValue]) [set addObject:bid];
    else [set removeObject:bid];
    [self saveSet:set];
}

@end
