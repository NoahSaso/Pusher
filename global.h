#define kName @"Pusher"

#define PUSHER_PREFS_FILE @"/var/mobile/Library/Preferences/com.noahsaso.pusher.plist"
#define PUSHER_PREFS_NOTIFICATION CFSTR("com.noahsaso.pusher/prefs")

#define PUSHER_APP_ID CFSTR("com.noahsaso.pusher")

#define NSPPreferenceGlobalBLPrefix @"GlobalBL-"

#define PUSHER_WHEN_TO_PUSH_LOCKED 0
#define PUSHER_WHEN_TO_PUSH_ALWAYS 1
#define PUSHER_WHEN_TO_PUSH_UNLOCKED 2

typedef enum {
	PusherAuthorizationTypeCredentials,
	PusherAuthorizationTypeHeader
} PusherAuthorizationType;

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_PUSHOVER @"Pushover"
// #define PUSHER_SERVICE_PUSHOVER_ID @"net.superblock.Pushover"
#define PUSHER_SERVICE_PUSHOVER_URL @"https://api.pushover.net/1/messages.json"
#define NSPPreferencePushoverTokenKey @"PushoverToken"
#define NSPPreferencePushoverUserKey @"PushoverUser"
#define NSPPreferencePushoverDevicesKey @"PushoverDevices"
#define NSPPreferencePushoverSoundsKey @"PushoverSounds"
#define NSPPreferencePushoverBLPrefix @"PushoverBL-"
#define NSPPreferencePushoverCustomAppsKey @"PushoverCustomApps"

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_PUSHBULLET @"Pushbullet"
// #define PUSHER_SERVICE_PUSHBULLET_ID @"com.pushbullet.client"
#define PUSHER_SERVICE_PUSHBULLET_URL @"https://api.pushbullet.com/v2/pushes"
#define NSPPreferencePushbulletTokenKey @"PushbulletToken"
#define NSPPreferencePushbulletUserKey @"PushbulletUser"
#define NSPPreferencePushbulletDevicesKey @"PushbulletDevices"
#define NSPPreferencePushbulletBLPrefix @"PushbulletBL-"
#define NSPPreferencePushbulletCustomAppsKey @"PushbulletCustomApps"

#define PUSHER_SERVICES @[ PUSHER_SERVICE_PUSHOVER, PUSHER_SERVICE_PUSHBULLET ]

#import <Preferences/PSSpecifier.h>

@interface PSSpecifier (Pusher)
+ (id)emptyGroupSpecifier;
@end
