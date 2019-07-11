#import "NSPPSListControllerWithColoredUI.h"

@implementation NSPPSListControllerWithColoredUI

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self tintUIToPusherColor];
}

// override so we can dynamically set ui color later for each service to match icon
- (void)tintUIToPusherColor {
	UIColor *color = NSPTintController.sharedController.activeTintColor;

	UINavigationController *navController = self.navigationController;
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) { navController = navController.navigationController; }
	navController.navigationBar.tintColor = color;

	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = color;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
	[UISlider appearanceWhenContainedInInstancesOfClasses:@[self.class]].tintColor = color;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self.view endEditing:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell *) [super tableView:tableView cellForRowAtIndexPath:indexPath];
	// tint color
	if (cell.type == PSLinkCell && cell.iconImageView && cell.iconImageView.image) {
		UIImage *newImage = [cell.iconImageView.image imageByReplacingColor:PUSHER_COLOR withColor:NSPTintController.sharedController.activeTintColor];
		cell.iconImageView.image = newImage;
	}
	return cell;
}

@end