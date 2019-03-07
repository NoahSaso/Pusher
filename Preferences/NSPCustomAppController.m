#import "NSPCustomAppController.h"
#import "NSPSharedSpecifiers.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPCustomAppController

- (id)initWithService:(NSString *)service appID:(NSString *)appID {
	NSPCustomAppController *ret = [self init];
	ret->_service = service;
	ret->_appID = appID;
	return ret;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		[allSpecifiers addObject:[PSSpecifier groupSpecifierWithName:@"Customize"]];
		[allSpecifiers addObjectsFromArray:[NSPSharedSpecifiers pushover]];

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

@end
