THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DockShelfPro

DockShelfPro_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
DockShelfPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
DockShelfPro_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = DockShelfProPrefs

DockShelfProPrefs_FILES = ../../shared/CDPremiumPrefsListController.m
DockShelfProPrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=DockShelfProPrefsListController
DockShelfProPrefs_FRAMEWORKS = UIKit Foundation
DockShelfProPrefs_PRIVATE_FRAMEWORKS = Preferences
DockShelfProPrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
DockShelfProPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
