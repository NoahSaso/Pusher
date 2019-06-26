#import "NSPSNSListController.h"

@implementation NSPSNSListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SNS" target:self] retain];
	}

	return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	XLog(@"val: %@, specifier identifier: %@", value, specifier.identifier);
	if (Xeq(specifier.identifier, @"SufficientNotificationSettingsIsAnd")) {
		// if val is boolvalue true, set allow notifications on, else turn it off
	}
}

@end
