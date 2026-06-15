THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockScreenAtmosphere

LockScreenAtmosphere_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
LockScreenAtmosphere_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
LockScreenAtmosphere_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = LockScreenAtmospherePrefs

LockScreenAtmospherePrefs_FILES = ../../shared/CDPremiumPrefsListController.m
LockScreenAtmospherePrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=LockScreenAtmospherePrefsListController
LockScreenAtmospherePrefs_FRAMEWORKS = UIKit Foundation
LockScreenAtmospherePrefs_PRIVATE_FRAMEWORKS = Preferences
LockScreenAtmospherePrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
LockScreenAtmospherePrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
