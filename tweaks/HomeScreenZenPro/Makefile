THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HomeScreenZenPro

HomeScreenZenPro_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
HomeScreenZenPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
HomeScreenZenPro_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = HomeScreenZenProPrefs

HomeScreenZenProPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
HomeScreenZenProPrefs_CFLAGS = -fobjc-arc -DPREFS_CLASS=HomeScreenZenProPrefsListController
HomeScreenZenProPrefs_FRAMEWORKS = UIKit Foundation
HomeScreenZenProPrefs_PRIVATE_FRAMEWORKS = Preferences
HomeScreenZenProPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
HomeScreenZenProPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
