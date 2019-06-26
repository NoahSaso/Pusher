#import "NSPPSListControllerWithColoredUI.h"

@implementation NSPPSListControllerWithColoredUI

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setPusherUIColor:PUSHER_COLOR override:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.navigationController.navigationController.navigationBar.tintColor = _priorTintColor;
}

// override so we can dynamically set ui color later for each service to match icon
- (void)setPusherUIColor:(UIColor *)color override:(BOOL)override {
	if (override || !_priorTintColor) { // only set once on load
		_priorTintColor = [self.navigationController.navigationController.navigationBar.tintColor retain];
	}
	self.navigationController.navigationController.navigationBar.tintColor = color;

	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = color;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISlider appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
}

@end