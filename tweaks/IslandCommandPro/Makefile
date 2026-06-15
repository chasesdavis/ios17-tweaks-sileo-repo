THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IslandCommandPro

IslandCommandPro_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
IslandCommandPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
IslandCommandPro_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = IslandCommandProPrefs

IslandCommandProPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
IslandCommandProPrefs_CFLAGS = -fobjc-arc -DPREFS_CLASS=IslandCommandProPrefsListController
IslandCommandProPrefs_FRAMEWORKS = UIKit Foundation
IslandCommandProPrefs_PRIVATE_FRAMEWORKS = Preferences
IslandCommandProPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
IslandCommandProPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
