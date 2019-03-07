#import "NSPServiceController.h"
#import "NSPSharedSpecifiers.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPServiceController

- (id)initWithService:(NSString *)service {
	NSPServiceController *ret = [self init];
	ret->_service = service;
	return ret;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [[self loadSpecifiersFromPlistName:_service target:self] mutableCopy];

		[allSpecifiers addObjectsFromArray:[NSPSharedSpecifiers get:_service withAppID:nil]];

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

- (void)openPushoverAppBuild {
	Xurl(@"https://pushover.net/apps/build");
}

- (void)openPushoverDashboard {
	Xurl(@"https://pushover.net/dashboard");
}

@end
