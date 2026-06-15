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
