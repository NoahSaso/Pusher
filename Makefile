ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Pusher
Pusher_FILES = Tweak.xm NSPTestPush.xm UIImage+ReplaceColor.m
Pusher_LIBRARIES = rocketbootstrap
Pusher_FRAMEWORKS = UIKit Foundation
Pusher_PRIVATE_FRAMEWORKS = AppSupport BulletinBoard

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
	# install.exec "killall -9 Preferences"
SUBPROJECTS += Preferences
SUBPROJECTS += Flipswitch
include $(THEOS_MAKE_PATH)/aggregate.mk
