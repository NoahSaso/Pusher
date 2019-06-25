ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Pusher
Pusher_FILES = Switch.xm
Pusher_FRAMEWORKS = UIKit
Pusher_LIBRARIES = flipswitch
Pusher_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	#PreferenceLoader plist
	$(ECHO_NOTHING)if [ -f Preferences.plist ]; then mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Pusher; cp Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Pusher/; fi$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
