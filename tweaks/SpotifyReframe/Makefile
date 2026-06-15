THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Spotify

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpotifyReframe

SpotifyReframe_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m ../../shared/CDPremiumTweakKit.m
SpotifyReframe_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
SpotifyReframe_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = SpotifyReframePrefs

SpotifyReframePrefs_FILES = ../../shared/CDPremiumPrefsListController.m
SpotifyReframePrefs_CFLAGS = -fobjc-arc -DCDPREFS_CLASS=SpotifyReframePrefsListController
SpotifyReframePrefs_FRAMEWORKS = UIKit Foundation
SpotifyReframePrefs_PRIVATE_FRAMEWORKS = Preferences
SpotifyReframePrefs_LDFLAGS = -F/Users/chase/theos/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
SpotifyReframePrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
