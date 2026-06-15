THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotificationForge

NotificationForge_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
NotificationForge_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
NotificationForge_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = NotificationForgePrefs

NotificationForgePrefs_FILES = ../../shared/CDPremiumPrefsListController.m
NotificationForgePrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=NotificationForgePrefsListController
NotificationForgePrefs_FRAMEWORKS = UIKit Foundation
NotificationForgePrefs_PRIVATE_FRAMEWORKS = Preferences
NotificationForgePrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
NotificationForgePrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
