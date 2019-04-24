#import "NSPServiceController.h"
#import "NSPSharedSpecifiers.h"
#import "NSPCustomizeAppsController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPServiceController

- (id)initWithService:(NSString *)service isCustom:(BOOL)isCustom {
	NSPServiceController *ret = [self init];
	ret->_service = service;
	ret->_isCustom = isCustom;
	return ret;
}

- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest {
	for (id object in source) {
		[dest insertObject:object atIndex:idx];
		idx += 1;
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {

		NSMutableArray *allSpecifiers = nil;
		NSArray *sharedSpecifiers = nil;

		if (_isCustom) {
			allSpecifiers = [[NSPSharedSpecifiers getCustom:_service ref:self] mutableCopy];
			sharedSpecifiers = [NSPSharedSpecifiers getCustomShared:_service];
		} else {
			allSpecifiers = [[self loadSpecifiersFromPlistName:_service target:self] mutableCopy];
			sharedSpecifiers = [NSPSharedSpecifiers get:_service];
		}

		BOOL insertOnNext = NO;
		BOOL inserted = NO;
		int idx = 0;
		for (PSSpecifier *specifier in allSpecifiers) {
			if (insertOnNext && specifier.cellType == PSGroupCell) {
				[self addObjectsFromArray:sharedSpecifiers atIndex:idx toArray:allSpecifiers];
				inserted = YES;
				break;
			} else if (specifier.cellType == PSGroupCell && Xeq(specifier.identifier, @"Options")) { // insert at end of options group
				insertOnNext = YES;
			}
			idx += 1;
		}

		if (!inserted) {
			[allSpecifiers addObjectsFromArray:sharedSpecifiers];
		}

		PSSpecifier *sendTestNotificationGroup = [PSSpecifier emptyGroupSpecifier];
		PSSpecifier *sendTestNotification = [PSSpecifier preferenceSpecifierNamed:@"Send Test Notification" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
		[sendTestNotification setButtonAction:@selector(sendTestNotification:)];
		[sendTestNotification setProperty:@YES forKey:@"enabled"];

		[allSpecifiers addObjectsFromArray:@[sendTestNotificationGroup, sendTestNotification]];

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

- (void)sendTestNotification:(PSSpecifier *)specifier {
	XLog(@"SENDING %@", _service);
}

- (void)openPushoverAppBuild {
	Xurl(@"https://pushover.net/apps/build");
}

- (void)openPushoverDashboard {
	Xurl(@"https://pushover.net/dashboard");
}

- (void)openPushbulletAccount {
	Xurl(@"https://www.pushbullet.com/#settings/account");
}

- (void)openIFTTTAccount {
	Xurl(@"https://ifttt.com/services/maker_webhooks/settings");
}

- (void)openDateFormatInstructions {
	Xurl(@"https://nsdateformatter.com");
}

@end
