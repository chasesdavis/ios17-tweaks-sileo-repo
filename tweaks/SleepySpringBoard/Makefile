THEOS ?= /Users/chase/theos
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SleepySpringBoard

SleepySpringBoard_FILES = Tweak.xm ../../shared/CDVisualTweakKit.m
SleepySpringBoard_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../../shared
SleepySpringBoard_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
