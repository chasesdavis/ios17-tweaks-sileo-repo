THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FocusLensPro

FocusLensPro_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
FocusLensPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
FocusLensPro_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = FocusLensProPrefs

FocusLensProPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
FocusLensProPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=FocusLensProPrefsListController
FocusLensProPrefs_FRAMEWORKS = UIKit Foundation
FocusLensProPrefs_PRIVATE_FRAMEWORKS = Preferences
FocusLensProPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
FocusLensProPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
