THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ControlCenterStudio

ControlCenterStudio_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
ControlCenterStudio_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
ControlCenterStudio_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = ControlCenterStudioPrefs

ControlCenterStudioPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
ControlCenterStudioPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=ControlCenterStudioPrefsListController
ControlCenterStudioPrefs_FRAMEWORKS = UIKit Foundation
ControlCenterStudioPrefs_PRIVATE_FRAMEWORKS = Preferences
ControlCenterStudioPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
ControlCenterStudioPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
