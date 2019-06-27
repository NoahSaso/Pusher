#import "NSPRootListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

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
