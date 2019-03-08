#import "NSPAppSelectionController.h"
#import "NSPALApplicationTableDataSource.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPALApplicationTableDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	NSString *displayIdentifier = [self displayIdentifierForIndexPath:indexPath];
	cell.accessoryType = [self.appSelectionController.selectedAppIDs containsObject:displayIdentifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

@end

@implementation NSPAppSelectionController

- (void)dealloc {
	[_appListDataSource.tableView release];
	[_appListDataSource dealloc];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_appList = [ALApplicationList sharedApplicationList];
	_appListDataSource = [NSPALApplicationTableDataSource new];
	_appListDataSource.sectionDescriptors = [NSPALApplicationTableDataSource standardSectionDescriptors];
	_appListDataSource.appSelectionController = self;

	self.tableView.dataSource = _appListDataSource;
	_appListDataSource.tableView = self.tableView;

	self.selectedAppIDs = [NSMutableArray new];

	self.navigationItem.title = @"Add Apps";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneSelecting)];
}

- (void)dismiss {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneSelecting {
	[self.customizeAppsController addAppIDs:self.selectedAppIDs];
	[self dismiss];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	NSString *displayIdentifier = [_appListDataSource displayIdentifierForIndexPath:indexPath];
	if ([self.selectedAppIDs containsObject:displayIdentifier]) {
		[self.selectedAppIDs removeObject:displayIdentifier];
	} else {
		[self.selectedAppIDs addObject:displayIdentifier];
	}
	[table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
