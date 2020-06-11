#define kName @"Pusher"

#define PUSHER_PREFS_FILE @"/var/mobile/Library/Preferences/com.noahsaso.pusher.plist"
#define PUSHER_PREFS_NOTIFICATION "com.noahsaso.pusher/prefs"
#define PUSHER_APP_ID CFSTR("com.noahsaso.pusher")
#define PUSHER_LOG_PREFS_NOTIFICATION "com.noahsaso.pusher~log/prefs"
#define PUSHER_LOG_ID CFSTR("com.noahsaso.pusher~log")
#define PUSHER_BUNDLE_PATH @"/Library/PreferenceBundles/Pusher.bundle"
#define PUSHER_BUNDLE [NSBundle bundleWithPath:PUSHER_BUNDLE_PATH]
#define PUSHER_COLOR [UIColor colorWithRed:0.0 green:177/255.0 blue:79/255.0 alpha:1.0]
#define PUSHER_TRIES 5 // how many times pusher will try to send the web request
#define PUSHER_LOG_MAX_STRING_LENGTH 50
#define PUSHER_LOG_IMAGE_DATA_PROPERTIES @[@"icon", @"image"] // properties to replace with PUSHER_LOG_IMAGE_DATA_REPLACEMENT in the log
#define PUSHER_LOG_IMAGE_DATA_REPLACEMENT @"[Base64 Image String]"
#define PUSHER_DEFAULT_MAX_WIDTH 1000.0
#define PUSHER_DEFAULT_MAX_HEIGHT 1000.0
#define PUSHER_DEFAULT_SHRINK_FACTOR 2.5
#define PUSHER_DELAY_BETWEEN_RETRIES 3

#import <rocketbootstrap/rocketbootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#define PUSHER_MESSAGING_CENTER_NAME @"com.noahsaso.pusher/testpush"
#define PUSHER_TEST_PUSH_MESSAGE_NAME @"sendTest"

#define NSPPreferenceGlobalBLPrefix @"GlobalBL-"
#define NSPPreferenceSNSPrefix @"SNS-"

#define PUSHER_SEGMENT_CELL_DEFAULT -1

#define PUSHER_WHAT_NETWORK_ANY 0
#define PUSHER_WHAT_NETWORK_WIFI_ONLY 1
#define PUSHER_WHAT_NETWORK_OFF_WIFI_ONLY 2

#define PUSHER_WHEN_TO_PUSH_LOCKED 0
#define PUSHER_WHEN_TO_PUSH_EITHER 1
#define PUSHER_WHEN_TO_PUSH_UNLOCKED 2

#define PUSHER_TEST_NOTIFICATION_TITLE @"Title"
#define PUSHER_TEST_NOTIFICATION_SUBTITLE @"Subtitle"
#define PUSHER_TEST_NOTIFICATION_MESSAGE @"Message"
#define PUSHER_TEST_NOTIFICATION_APP_NAME @"Settings"
#define PUSHER_TEST_NOTIFICATION_SECTION_ID @"com.apple.Preferences"

#define PUSHER_TEST_PUSH_RESULT_PREFIX @"Test Notification Result: "

typedef NS_OPTIONS(NSUInteger, BBActualSectionInfoPushSettings) {
	BBActualSectionInfoPushSettingsBadges = 1 << 3, // was 0
	BBActualSectionInfoPushSettingsSounds = 1 << 4, // was 1
	// BBSectionInfoPushSettingsAlerts = 1 << 2 // wrong
};

#define PUSHER_SUFFICIENT_ALLOW_NOTIFICATIONS_KEY @"AllowNotifications"
#define PUSHER_SUFFICIENT_LOCK_SCREEN_KEY @"LockScreen"
#define PUSHER_SUFFICIENT_NOTIFICATION_CENTER_KEY @"NotificationCenter"
#define PUSHER_SUFFICIENT_BANNERS_KEY @"Banners"
#define PUSHER_SUFFICIENT_BADGES_KEY @"Badges"
// #define PUSHER_SUFFICIENT_SOUNDS_KEY @"Sounds"
#define PUSHER_SUFFICIENT_SHOWS_PREVIEWS_KEY @"ShowsPreviews"

#define PUSHER_SNS_KEYS @{ PUSHER_SUFFICIENT_ALLOW_NOTIFICATIONS_KEY: @YES, PUSHER_SUFFICIENT_LOCK_SCREEN_KEY: @NO, PUSHER_SUFFICIENT_NOTIFICATION_CENTER_KEY: @NO, PUSHER_SUFFICIENT_BANNERS_KEY: @NO, PUSHER_SUFFICIENT_BADGES_KEY: @NO, PUSHER_SUFFICIENT_SHOWS_PREVIEWS_KEY: @NO }

#define NSPPreferenceCustomServicesKey @"CustomServices"
#define NSPPreferenceCustomServiceCustomAppsKey(service) Xstr(@"CustomService_%@_CustomApps", service)
#define NSPPreferenceCustomServiceBLPrefix(service) Xstr(@"CustomServiceBL_%@-", service)
// IF ADDING MORE CUSTOM SERVICE KEY CALCULATORS, REMEMBER TO RENAME THEM UPON CUSTOM SERVICE RENAME IN SERVICE LIST

#define NSPPreferenceBuiltInServiceCustomAppsKey(service) Xstr(@"%@CustomApps", service)

typedef enum {
	PusherAuthorizationTypeNone,
	PusherAuthorizationTypeHeader, // credentials dictionary needs value and headerName
	PusherAuthorizationTypeCredentials,
	PusherAuthorizationTypeReplaceKey
} PusherAuthorizationType;

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_PUSHOVER @"Pushover"
#define PUSHER_SERVICE_PUSHOVER_APP_ID @"net.superblock.Pushover"
#define PUSHER_SERVICE_PUSHOVER_URL @"https://api.pushover.net/1/messages.json"
#define NSPPreferencePushoverTokenKey @"PushoverToken"
#define NSPPreferencePushoverUserKey @"PushoverUser"
#define NSPPreferencePushoverDevicesKey @"PushoverDevices"
#define NSPPreferencePushoverSoundsKey @"PushoverSounds"
#define NSPPreferencePushoverBLPrefix @"PushoverBL-"
#define NSPPreferencePushoverCustomAppsKey @"PushoverCustomApps"

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_PUSHBULLET @"Pushbullet"
#define PUSHER_SERVICE_PUSHBULLET_APP_ID @"com.pushbullet.client"
#define PUSHER_SERVICE_PUSHBULLET_URL @"https://api.pushbullet.com/v2/pushes"
#define NSPPreferencePushbulletTokenKey @"PushbulletToken"
#define NSPPreferencePushbulletDevicesKey @"PushbulletDevices"
#define NSPPreferencePushbulletBLPrefix @"PushbulletBL-"
#define NSPPreferencePushbulletCustomAppsKey @"PushbulletCustomApps"

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_IFTTT @"IFTTT"
#define PUSHER_SERVICE_IFTTT_URL @"https://maker.ifttt.com/trigger/REPLACE_EVENT_NAME/with/key/REPLACE_KEY"
#define NSPPreferenceIFTTTKeyKey @"IFTTTKey"
#define NSPPreferenceIFTTTEventNameKey @"IFTTTEventName"
#define NSPPreferenceIFTTTDateFormatKey @"IFTTTDateFormat"
#define NSPPreferenceIFTTTBLPrefix @"IFTTTBL-"
#define NSPPreferenceIFTTTCustomAppsKey @"IFTTTCustomApps"
#define NSPPreferenceIFTTTIncludeIconKey @"IFTTTIncludeIcon"
#define NSPPreferenceIFTTTCurateDataKey @"IFTTTCurateData"

// All keys MUST HAVE the prefix equal to the name of the service
#define PUSHER_SERVICE_PUSHER_RECEIVER @"Pusher Receiver"
#define PUSHER_SERVICE_PUSHER_RECEIVER_URL @"https://REPLACE_DB_NAME.restdb.io/rest/notifications"
#define NSPPreferencePusherReceiverDBNameKey @"Pusher ReceiverDBName"
#define NSPPreferencePusherReceiverAPIKeyKey @"Pusher ReceiverKey"
#define NSPPreferencePusherReceiverDateFormatKey @"Pusher ReceiverDateFormat"
#define NSPPreferencePusherReceiverBLPrefix @"Pusher ReceiverBL-"
#define NSPPreferencePusherReceiverCustomAppsKey @"Pusher ReceiverCustomApps"
#define NSPPreferencePusherReceiverIncludeIconKey @"Pusher ReceiverIncludeIcon"
#define NSPPreferencePusherReceiverIncludeImageKey @"Pusher ReceiverIncludeImage"
#define NSPPreferencePusherReceiverImageMaxWidthKey @"Pusher ReceiverImageMaxWidth"
#define NSPPreferencePusherReceiverImageMaxHeightKey @"Pusher ReceiverImageMaxHeight"
#define NSPPreferencePusherReceiverImageShrinkFactorKey @"Pusher ReceiverImageShrinkFactor"

#define BUILTIN_PUSHER_SERVICES @[ PUSHER_SERVICE_PUSHOVER, PUSHER_SERVICE_PUSHBULLET, PUSHER_SERVICE_IFTTT, PUSHER_SERVICE_PUSHER_RECEIVER ]

#import <Preferences/PSSpecifier.h>
#import <BulletinBoard/BBBulletin.h>
#import <BulletinBoard/BBSectionInfo.h> // imports BBSectionInfoSettings
#import <UserNotifications/UserNotifications.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <Preferences/PSTableCell.h>
#import "UIImage+ReplaceColor.h"
#import <objc/runtime.h>
#import "Preferences/NSPusherManager.h"

#define CURRENT_TINT_COLOR_KEY @"CurrentTintColor"

@interface PSSpecifier (Pusher)
@property (nonatomic, retain) NSArray *values;
- (void)performSetterWithValue:(id)arg1;
- (BOOL)hasValidSetter;
- (void)setValues:(id)arg1 titles:(id)arg2;
@end

@interface SBLockScreenManager
+ (id)sharedInstance;
@property(readonly) BOOL isUILocked;
@end

@interface BBAttachmentMetadata : NSObject
@property (nonatomic, readonly) long long type;
@property (nonatomic, copy, readonly) NSURL *URL;
- (id)_initWithUUID:(id)arg1 type:(long long)arg2 URL:(id)arg3;
@end

@interface BBBulletin (Pusher)
@property (nonatomic, readonly) BOOL showsSubtitle;
@property (nonatomic, copy) BBAttachmentMetadata *primaryAttachment;
// @property (nonatomic, copy) NSArray *additionalAttachments;
@end

@interface BBServer : NSObject
- (BBSectionInfo *)_sectionInfoForSectionID:(id)arg1 effective:(BOOL)arg2;
+ (BBServer *)pusherSharedInstance;
- (void)sendBulletinToPusher:(BBBulletin *)bulletin;
- (void)makePusherRequest:(NSString *)urlString infoDict:(NSDictionary *)infoDict credentials:(NSDictionary *)credentials authType:(PusherAuthorizationType)authType method:(NSString *)method logString:(NSString *)logString service:(NSString *)service bulletin:(BBBulletin *)bulletin;
- (NSDictionary *)getPusherInfoDictionaryForService:(NSString *)service withDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)getPusherCredentialsForService:(NSString *)service withDictionary:(NSDictionary *)dictionary;
- (void)sendToPusherService:(NSString *)service bulletin:(BBBulletin *)bulletin appID:(NSString *)appID appName:(NSString *)appName title:(NSString *)title message:(NSString *)message isTest:(BOOL)isTest;
- (NSString *)base64IconDataForBundleID:(NSString *)bundleID;
@end

// iOS 13
typedef struct SBIconImageInfo {
	CGSize size;
	CGFloat scale;
	CGFloat continuousCornerRadius;
} SBIconImageInfo;

@interface SBApplicationIcon : NSObject
// iOS 12 and below
- (UIImage *)generateIconImage:(int)arg1;
// iOS 13
- (id)generateIconImageWithInfo:(SBIconImageInfo)arg1;
@end

@interface SBIconModel : NSObject
- (SBApplicationIcon *)expectedIconForDisplayIdentifier:(id)arg1;
@end

@interface SBIconController : UIViewController
@property (nonatomic, retain) SBIconModel *model;
+ (id)sharedInstance;
@end

@interface SBWiFiManager : NSObject
+ (id)sharedInstance;
- (NSString *)currentNetworkName;
@end

@interface PSTableCell (Pusher)
- (UIImageView *)iconImageView;
@end

@interface UIView (Pusher)
- (id)_viewDelegate;
@end

@interface UIImage (Pusher)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end
