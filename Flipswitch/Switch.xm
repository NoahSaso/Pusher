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
	return kName;
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
	NSNumber *n = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"Enabled" inDomain:(__bridge NSString *)PUSHER_APP_ID];
	BOOL enabled = n ? n.boolValue : YES;
	return enabled ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
	switch (newState) {
	case FSSwitchStateIndeterminate:
		break;
	default:
		[[NSUserDefaults standardUserDefaults] setObject:@(newState == FSSwitchStateOn) forKey:@"Enabled" inDomain:(__bridge NSString *)PUSHER_APP_ID];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PUSHER_PREFS_NOTIFICATION), NULL, NULL, YES);
		break;
	}
	return;
}

@end
