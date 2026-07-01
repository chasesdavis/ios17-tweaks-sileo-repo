export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0
export THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AppGuardProPrefs

AppGuardProPrefs_FILES = AGPRootListController.m AGPAppListController.m
AppGuardProPrefs_FRAMEWORKS = UIKit
AppGuardProPrefs_PRIVATE_FRAMEWORKS = Preferences
# The Preferences private-framework stub isn't in the "latest" SDK; point the
# linker at the Theos-bundled iOS 17.0 SDK's PrivateFrameworks (repo convention).
AppGuardProPrefs_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS17.0.sdk/System/Library/PrivateFrameworks
AppGuardProPrefs_INSTALL_PATH = /Library/PreferenceBundles
AppGuardProPrefs_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AppGuardPro.plist$(ECHO_END)
