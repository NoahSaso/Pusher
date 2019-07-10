#import "NSPPSViewControllerWithColoredUI.h"

@implementation NSPPSViewControllerWithColoredUI

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
  [self tintUIToPusherColor];
}

- (void)tintUIToPusherColor {
	UIColor *color = NSPTintController.sharedController.activeTintColor;

	self.navigationController.navigationController.navigationBar.tintColor = color;

  [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = color;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISlider appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
}

@end