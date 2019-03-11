#import "NSPRootListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)openTwitter {
	NSString *appLink = @"twitter://user?screen_name=NoahSaso";
	NSString *webLink = @"https://twitter.com/NoahSaso";
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appLink]]) {
		Xurl(appLink);
	} else {
		Xurl(webLink);
	}
}

@end
