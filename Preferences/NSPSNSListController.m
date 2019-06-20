#import "NSPSNSListController.h"

@implementation NSPSNSListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SNS" target:self] retain];
	}

	return _specifiers;
}

@end
