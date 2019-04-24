ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Pusher
Pusher_FILES = Tweak.xm NSPTestPush.m
Pusher_LIBRARIES = rocketbootstrap
Pusher_PRIVATE_FRAMEWORKS = AppSupport BulletinBoard

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	# install.exec "killall -9 SpringBoard"
	install.exec "killall -9 Preferences"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
