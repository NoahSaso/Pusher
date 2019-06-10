#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"

#import "../global.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface PusherSwitch : NSObject <FSSwitchDataSource>
@end

@implementation PusherSwitch

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier {
	return @"Pusher";
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
	NSNumber *n = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"Enabled" inDomain:(__bridge NSString *)PUSHER_APP_ID];
	BOOL enabled = (n)? [n boolValue]:YES;
	return (enabled) ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
	switch (newState) {
	case FSSwitchStateIndeterminate:
		break;
	case FSSwitchStateOn:
		[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"Enabled" inDomain:(__bridge NSString *)PUSHER_APP_ID];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PUSHER_PREFS_NOTIFICATION, NULL, NULL, YES);
		break;
	case FSSwitchStateOff:
		[[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"Enabled" inDomain:(__bridge NSString *)PUSHER_APP_ID];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PUSHER_PREFS_NOTIFICATION, NULL, NULL, YES);
		break;
	}
	return;
}

@end
