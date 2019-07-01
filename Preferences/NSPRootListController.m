#import "NSPRootListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

static int countAppIDsWithPrefix(NSDictionary *prefs, NSString *prefix) {
  int count = 0;
	for (id key in prefs.allKeys) {
		if (![key isKindOfClass:NSString.class]) { continue; }
		if ([key hasPrefix:prefix] && ((NSNumber *) prefs[key]).boolValue) {
      count += 1;
		}
	}
	return count;
}

@implementation NSPRootListController

- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest {
	for (id object in source) {
		[dest insertObject:object atIndex:idx];
		idx += 1;
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
		NSArray *globalServices = [self loadSpecifiersFromPlistName:@"GlobalAndServices" target:self];

		int idx = 0;
		for (PSSpecifier *specifier in allSpecifiers) {
			if (specifier.cellType == PSGroupCell && Xeq(specifier.identifier, @"Support")) {
				[self addObjectsFromArray:globalServices atIndex:idx toArray:allSpecifiers];
				break;
			}
			idx += 1;
		}

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Get preferences for counting
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	for (PSSpecifier *specifier in self.specifiers) {
		if (specifier.cellType == PSLinkCell && Xeq(specifier.name, @"Global App List")) {
			specifier.name = Xstr(@"%@ (%d total)", specifier.name, countAppIDsWithPrefix(prefs, [specifier propertyForKey:@"ALSettingsKeyPrefix"]));
			[specifier setProperty:self forKey:@"psListRef"];
			break;
		}
	}
}

- (void)openTwitter:(NSString *)username {
	NSString *appLink = Xstr(@"twitter://user?screen_name=%@", username);
	NSString *webLink = Xstr(@"https://twitter.com/%@", username);
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appLink]]) {
		Xurl(appLink);
	} else {
		Xurl(webLink);
	}
}

- (void)openTwitterNoahSaso {
	[self openTwitter:@"NoahSaso"];
}

@end
