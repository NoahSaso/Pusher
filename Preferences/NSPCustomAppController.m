#import "NSPCustomAppController.h"
#import "NSPSharedSpecifiers.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPCustomAppController

- (id)initWithService:(NSString *)service appID:(NSString *)appID {
	NSPCustomAppController *ret = [self init];
	_service = service;
	_appID = appID;
	return ret;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		[allSpecifiers addObject:[PSSpecifier groupSpecifierWithName:@"Customize"]];
		XLog(@"_service: %@", _service);
		XLog(@"_appID: %@", _appID);
		[allSpecifiers addObjectsFromArray:[NSPSharedSpecifiers get:_service withAppID:_appID]];

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

@end
