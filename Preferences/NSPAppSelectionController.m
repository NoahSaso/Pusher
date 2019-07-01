#import "NSPAppSelectionController.h"
#import "NSPAppSelectionALApplicationTableDataSource.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPAppSelectionALApplicationTableDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	NSString *displayIdentifier = [self displayIdentifierForIndexPath:indexPath];
	cell.accessoryType = [self.appSelectionController.selectedAppIDs containsObject:displayIdentifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

@end

@implementation NSPAppSelectionController

- (void)dealloc {
	[self.tableView release];
	[_appListDataSource dealloc];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_appList = [ALApplicationList sharedApplicationList];
	_appListDataSource = [NSPAppSelectionALApplicationTableDataSource new];
	_appListDataSource.sectionDescriptors = [NSPAppSelectionALApplicationTableDataSource standardSectionDescriptors];
	_appListDataSource.appSelectionController = self;

	self.tableView.dataSource = _appListDataSource;
	_appListDataSource.tableView = self.tableView;

	UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	searchController.searchResultsUpdater = self;
	searchController.hidesNavigationBarDuringPresentation = NO;
	searchController.dimsBackgroundDuringPresentation = NO;
	[searchController.searchBar sizeToFit];
	self.tableView.tableHeaderView = searchController.searchBar;

	self.selectedAppIDs = [NSMutableArray new];

	self.navigationItem.title = @"Add Apps";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(doneSelecting)];
}

- (void)dismiss {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneSelecting {
	[self.customizeAppsController addAppIDs:self.selectedAppIDs];
	[self dismiss];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	NSString *filter = searchController.searchBar.text;

	NSMutableArray *sectionDescriptors = [NSPAppSelectionALApplicationTableDataSource.standardSectionDescriptors mutableCopy];
	if (XIS_EMPTY(filter)) {
		_appListDataSource.sectionDescriptors = sectionDescriptors;
	} else {
		NSMutableArray *filteredSectionDescriptors = [NSMutableArray new];
		for (NSDictionary *sectionDescriptor in sectionDescriptors) {
			NSMutableDictionary *filteredSectionDescriptor = [sectionDescriptor mutableCopy];
			filteredSectionDescriptor[ALSectionDescriptorPredicateKey] = Xstr(@"%@ AND displayName CONTAINS[cd] '%@'", filteredSectionDescriptor[ALSectionDescriptorPredicateKey], filter);
			XLog(@"filteredSectionDescriptor[ALSectionDescriptorPredicateKey] = %@", filteredSectionDescriptor[ALSectionDescriptorPredicateKey]);
			[filteredSectionDescriptors addObject:filteredSectionDescriptor];
		}
		_appListDataSource.sectionDescriptors = filteredSectionDescriptors;
	}

	[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	NSString *displayIdentifier = [_appListDataSource displayIdentifierForIndexPath:indexPath];
	if ([self.selectedAppIDs containsObject:displayIdentifier]) {
		[self.selectedAppIDs removeObject:displayIdentifier];
	} else {
		[self.selectedAppIDs addObject:displayIdentifier];
	}
	[table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
