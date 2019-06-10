ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PusherFlipswitch
PusherFlipswitch_FILES = Switch.xm
PusherFlipswitch_FRAMEWORKS = UIKit
PusherFlipswitch_LIBRARIES = flipswitch
PusherFlipswitch_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	#PreferenceLoader plist
	$(ECHO_NOTHING)if [ -f Preferences.plist ]; then mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PusherFlipswitch; cp Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PusherFlipswitch/; fi$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
