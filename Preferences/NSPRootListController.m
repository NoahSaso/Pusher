#import "NSPRootListController.h"

@implementation NSPRootListController

- (void)viewDidLoad {
	[super viewDidLoad];
	if (!_priorTintColor) {
		UINavigationController *navController = self.navigationController;
		if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) { navController = navController.navigationController; }
		_priorTintColor = [navController.navigationBar.tintColor retain];
	}

	// Get the banner image
	UIImage *image = [UIImage imageNamed:@"banner" inBundle:PUSHER_BUNDLE];
	UIImageView *headerImage = [[UIImageView alloc] initWithImage:image];
	// Resize header image
	CGFloat paneWidth = UIScreen.mainScreen.bounds.size.width;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		paneWidth = self.rootController.view.frame.size.width;
	}
	// Resize frame to fit
	CGRect newFrame = headerImage.frame;
	CGFloat ratio = paneWidth / newFrame.size.width;
	newFrame.size.width = paneWidth;
	newFrame.size.height *= ratio;
	headerImage.frame = newFrame;
	// Add header container
	UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.table.frame.size.width, newFrame.size.height)];
	headerContainer.backgroundColor = UIColor.clearColor;
	[headerContainer addSubview:headerImage];
	[self.table setTableHeaderView:headerContainer];

	self.title = nil; // banner takes care of name
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[NSPusherManager.sharedController setActiveTintColor:nil];
	[self tintUIToPusherColor];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	UINavigationController *navController = self.navigationController;
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) { navController = navController.navigationController; }
	navController.navigationBar.tintColor = _priorTintColor;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)openTwitterNoahSaso {
	[NSPusherManager.sharedController openTwitter:@"NoahSaso"];
}

@end
