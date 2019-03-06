ARCHS = arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Pusher
Pusher_FILES = NSPRootListController.m NSPDeviceListController.m
Pusher_INSTALL_PATH = /Library/PreferenceBundles
Pusher_FRAMEWORKS = UIKit
Pusher_PRIVATE_FRAMEWORKS = Preferences
Pusher_LIBRARIES = AppList

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Pusher.plist$(ECHO_END)
