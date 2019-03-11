#define kName @"Pusher"

#define PUSHER_PREFS_FILE @"/var/mobile/Library/Preferences/com.noahsaso.pusher.plist"
#define PUSHER_PREFS_NOTIFICATION CFSTR("com.noahsaso.pusher/prefs")

#define PUSHER_APP_ID CFSTR("com.noahsaso.pusher")

#define NSPPreferenceGlobalBLPrefix @"GlobalBL-"

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_PUSHOVER @"Pushover"
#define PUSHER_SERVICE_PUSHOVER_ID @"net.superblock.Pushover"
#define PUSHER_SERVICE_PUSHOVER_URL @"https://api.pushover.net/1/messages.json"
#define NSPPreferencePushoverTokenKey @"PushoverToken"
#define NSPPreferencePushoverUserKey @"PushoverUser"
#define NSPPreferencePushoverDevicesKey @"PushoverDevices"
#define NSPPreferencePushoverBLPrefix @"PushoverBL-"
#define NSPPreferencePushoverCustomAppsKey @"PushoverCustomApps"

#define PUSHER_SERVICES @[ PUSHER_SERVICE_PUSHOVER ]
