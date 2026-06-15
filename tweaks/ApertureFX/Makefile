THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ApertureFX

ApertureFX_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
ApertureFX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
ApertureFX_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = ApertureFXPrefs

ApertureFXPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
ApertureFXPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=ApertureFXPrefsListController
ApertureFXPrefs_FRAMEWORKS = UIKit Foundation
ApertureFXPrefs_PRIVATE_FRAMEWORKS = Preferences
ApertureFXPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
ApertureFXPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
