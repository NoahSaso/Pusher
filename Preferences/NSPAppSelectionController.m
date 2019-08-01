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
	cell.tintColor = NSPusherManager.sharedController.activeTintColor;
	return cell;
}

@end

@implementation NSPAppSelectionController
@synthesize callback;

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

	_searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	_searchController.searchResultsUpdater = self;
	_searchController.hidesNavigationBarDuringPresentation = NO;
	_searchController.dimsBackgroundDuringPresentation = NO;
	[_searchController.searchBar sizeToFit];
	_searchController.searchBar.tintColor = NSPusherManager.sharedController.activeTintColor;
	self.tableView.tableHeaderView = _searchController.searchBar;

	if (!self.selectedAppIDs || ![self.selectedAppIDs isKindOfClass:NSMutableArray.class]) {
		self.selectedAppIDs = [NSMutableArray new];
	}

	self.navigationItem.title = self.navItemTitle ?: @"Apps";
	if (self.selectingMultiple) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:(self.rightButtonTitle ?: @"Done") style:UIBarButtonItemStylePlain target:self action:@selector(doneSelecting)];
	}
}

- (void)dismiss {
	_searchController.active = NO;
	if (self.selectingMultiple) {
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)doneSelecting {
	if (callback) {
		callback(self.selectingMultiple ? self.selectedAppIDs : (self.selectedAppIDs.count ? self.selectedAppIDs[0] : nil));
	}
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
			// XLog(@"filteredSectionDescriptor[ALSectionDescriptorPredicateKey] = %@", filteredSectionDescriptor[ALSectionDescriptorPredicateKey]);
			[filteredSectionDescriptors addObject:filteredSectionDescriptor];
		}
		_appListDataSource.sectionDescriptors = filteredSectionDescriptors;
	}

	[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	NSString *displayIdentifier = [_appListDataSource displayIdentifierForIndexPath:indexPath];
	if (self.selectingMultiple) {
		if ([self.selectedAppIDs containsObject:displayIdentifier]) {
			[self.selectedAppIDs removeObject:displayIdentifier];
		} else {
			[self.selectedAppIDs addObject:displayIdentifier];
		}
		[table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	} else {
		[self.selectedAppIDs removeAllObjects];
		[self.selectedAppIDs addObject:displayIdentifier];
		[self doneSelecting];
	}
}

@end
