#import "NSPPSViewControllerWithColoredUI.h"

@implementation NSPPSViewControllerWithColoredUI

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
  [self tintUIToPusherColor];
}

- (void)tintUIToPusherColor {
	UIColor *color = NSPusherManager.sharedController.activeTintColor;

	UINavigationController *navController = self.navigationController;
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) { navController = navController.navigationController; }
	navController.navigationBar.tintColor = color;

  [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = color;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISlider appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
}

@end