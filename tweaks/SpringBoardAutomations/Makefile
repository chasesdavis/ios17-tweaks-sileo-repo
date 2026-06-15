THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpringBoardAutomations

SpringBoardAutomations_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
SpringBoardAutomations_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
SpringBoardAutomations_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = SpringBoardAutomationsPrefs

SpringBoardAutomationsPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
SpringBoardAutomationsPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=SpringBoardAutomationsPrefsListController
SpringBoardAutomationsPrefs_FRAMEWORKS = UIKit Foundation
SpringBoardAutomationsPrefs_PRIVATE_FRAMEWORKS = Preferences
SpringBoardAutomationsPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
SpringBoardAutomationsPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
