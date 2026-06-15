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
