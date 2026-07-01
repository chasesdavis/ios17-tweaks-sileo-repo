export TARGET = iphone:clang:latest:15.0
export ARCHS = arm64 arm64e

# RootHide Bootstrap packaging (repo convention). Installs under /var/jb.
export THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppGuardPro

AppGuardPro_FILES = Tweak.x
# LocalAuthentication = biometric/passcode. MobileCoreServices/CoreServices for LSApplicationWorkspace lookups.
AppGuardPro_FRAMEWORKS = UIKit Foundation LocalAuthentication
AppGuardPro_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk

# Build the preferences bundle after the tweak.
SUBPROJECTS += prefs
include $(THEOS)/makefiles/aggregate.mk
