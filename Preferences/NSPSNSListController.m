#import "NSPSNSListController.h"
#import "NSPSharedSpecifiers.h"

@implementation NSPSNSListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SNS" target:self] retain];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_isService = (BOOL)[self.specifier propertyForKey:@"service"];
	if (_isService) {
		_service = [[self.specifier propertyForKey:@"service"] retain];
		_isCustomService = [self.specifier propertyForKey:@"isCustomService"] && ((NSNumber *)[self.specifier propertyForKey:@"isCustomService"]).boolValue;
		for (PSSpecifier *specifier in self.specifiers) {
			[specifier setProperty:_service forKey:@"service"];
			if (!_isCustomService) {
				[specifier setProperty:[specifier propertyForKey:@"key"] forKey:@"globalKey"];
				[specifier setProperty:Xstr(@"%@%@", _service, [specifier propertyForKey:@"key"]) forKey:@"key"];
			}
		}
	}
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	if (!_isService) { [super setPreferenceValue:value specifier:specifier]; }
	if (value && [specifier.identifier containsString:@"SufficientNotificationSettingsIsAnd"]) {
		// if val is bool value true, set allow notifications on, else turn it off
		PSSpecifier *allowNotificationsSpecifier = [self specifierForID:@"Allow Notifications"];
		if (allowNotificationsSpecifier) {
			[allowNotificationsSpecifier performSetterWithValue:value];
			[self reloadSpecifier:allowNotificationsSpecifier animated:YES];
		}
		if (!((NSNumber *) value).boolValue) {
			PSSpecifier *requireANWithORSpecifier = [self specifierForID:@"Require Allow Notifications with OR"];
			if (requireANWithORSpecifier) {
				[requireANWithORSpecifier performSetterWithValue:@YES];
				[self reloadSpecifier:requireANWithORSpecifier animated:YES];
			}
		}
	}
	if (!_isService) { return; }
	if (_isCustomService) {
		[NSPSharedSpecifiers setPreferenceValue:value forCustomSpecifier:specifier];
	} else {
		[NSPSharedSpecifiers setPreferenceValue:value forBuiltInServiceSpecifier:specifier];
	}
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	if (!_isService) {
		return [super readPreferenceValue:specifier];
	}
	if (_isCustomService) {
		return [NSPSharedSpecifiers readCustomPreferenceValue:specifier];
	} else {
		return [NSPSharedSpecifiers readBuiltInServicePreferenceValue:specifier];
	}
}

@end
