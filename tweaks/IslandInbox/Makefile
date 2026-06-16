THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IslandInbox

IslandInbox_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
IslandInbox_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
IslandInbox_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = IslandInboxPrefs

IslandInboxPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
IslandInboxPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=IslandInboxPrefsListController
IslandInboxPrefs_FRAMEWORKS = UIKit Foundation
IslandInboxPrefs_PRIVATE_FRAMEWORKS = Preferences
IslandInboxPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
IslandInboxPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
