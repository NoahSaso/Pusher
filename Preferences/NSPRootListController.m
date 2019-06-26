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

- (void)viewDidLoad {
	[super viewDidLoad];
	// _priorBarTintColor = self.navigationController.navigationController.navigationBar.barTintColor;
	// _priorTintColor = self.navigationController.navigationController.navigationBar.tintColor;
	// self.navigationController.navigationController.navigationBar.barTintColor = PUSHER_COLOR;
	// self.navigationController.navigationController.navigationBar.tintColor = UIColor.blackColor;

	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = PUSHER_COLOR;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = PUSHER_COLOR;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = PUSHER_COLOR;
	[UISlider appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = PUSHER_COLOR;
}

// - (void)willMoveToParentViewController:(UIViewController *)parent {
	// [super willMoveToParentViewController:parent];
	// if (!parent) {
		// self.navigationController.navigationBar.barTintColor = _priorBarTintColor;
		// self.navigationController.navigationBar.tintColor = _priorTintColor;
	// }
// }

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
