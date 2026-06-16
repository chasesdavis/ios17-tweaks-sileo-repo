THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IslandHub

IslandHub_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
IslandHub_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
IslandHub_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = IslandHubPrefs

IslandHubPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
IslandHubPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=IslandHubPrefsListController
IslandHubPrefs_FRAMEWORKS = UIKit Foundation
IslandHubPrefs_PRIVATE_FRAMEWORKS = Preferences
IslandHubPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
IslandHubPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
