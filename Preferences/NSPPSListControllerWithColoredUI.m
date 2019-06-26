#import "NSPPSListControllerWithColoredUI.h"

@implementation NSPPSListControllerWithColoredUI

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setPusherUIColor:PUSHER_COLOR];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.navigationController.navigationController.navigationBar.tintColor = _priorTintColor;
}

- (void)setPusherUIColor:(UIColor *)color {
	_priorTintColor = [self.navigationController.navigationController.navigationBar.tintColor retain];
	self.navigationController.navigationController.navigationBar.tintColor = color;

	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = color;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISlider appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
}

@end