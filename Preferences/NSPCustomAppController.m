#import "NSPCustomAppController.h"
#import "NSPSharedSpecifiers.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPCustomAppController

- (id)initWithService:(NSString *)service appID:(NSString *)appID appTitle:(NSString *)appTitle isCustomService:(BOOL)isCustomService {
	if (self = [super init]) {
		_service = service;
		_appID = appID;
		_appTitle = appTitle;
		_isCustomService = isCustomService;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.title = _appTitle;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		[allSpecifiers addObject:[PSSpecifier groupSpecifierWithName:@"Customize"]];
		[allSpecifiers addObjectsFromArray:[NSPSharedSpecifiers get:_service withAppID:_appID isCustomService:_isCustomService]];

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

@end
