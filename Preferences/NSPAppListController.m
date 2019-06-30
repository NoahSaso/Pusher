#import "NSPAppListController.h"
#import "NSPAppListALApplicationTableDataSource.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPAppListALApplicationTableDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	NSString *displayIdentifier = [self displayIdentifierForIndexPath:indexPath];
	cell.accessoryType = [self.appListController.selectedAppIDs containsObject:displayIdentifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

@end

@implementation NSPAppListController

- (void)dealloc {
	[_table release];
	[_appListDataSource dealloc];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"AppCell"];
	_table.delegate = self;
	[self.view addSubview:_table];

	_appList = [ALApplicationList sharedApplicationList];
	_appListDataSource = [NSPAppListALApplicationTableDataSource new];
	_appListDataSource.sectionDescriptors = [NSPAppListALApplicationTableDataSource standardSectionDescriptors];
	_appListDataSource.appListController = self;

	UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	searchController.searchResultsUpdater = self;
	searchController.hidesNavigationBarDuringPresentation = NO;
	searchController.dimsBackgroundDuringPresentation = NO;
	[searchController.searchBar sizeToFit];
	_table.tableHeaderView = searchController.searchBar;

	_table.dataSource = _appListDataSource;
	_appListDataSource.tableView = _table;

	_prefix = [self.specifier propertyForKey:@"ALSettingsKeyPrefix"];

	// Get preferences
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	self.selectedAppIDs = [NSMutableArray new];
	for (id key in prefs.allKeys) {
		if (![key isKindOfClass:NSString.class]) { continue; }
		if ([key hasPrefix:_prefix] && ((NSNumber *) prefs[key]).boolValue) {
			NSString *subKey = [key substringFromIndex:_prefix.length];
			[self.selectedAppIDs addObject:subKey];
		}
	}

	_label = [self.specifier propertyForKey:@"label"];
	[self updateTitle];

	[_table reloadData];
}

- (void)updateTitle {
	self.navigationItem.title = Xstr(@"%@ (%lu total)", _label, self.selectedAppIDs.count);
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	NSString *filter = searchController.searchBar.text;

	NSMutableArray *sectionDescriptors = [NSPAppListALApplicationTableDataSource.standardSectionDescriptors mutableCopy];
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

	[_table reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
	[self updateTitle];
}

- (void)updatePreferencesForAppID:(NSString *)appID selected:(BOOL)selected {
	if (selected) {
		[self.selectedAppIDs addObject:appID];
	} else {
		[self.selectedAppIDs removeObject:appID];
	}
	[self updateTitle];
	NSString *key = Xstr(@"%@%@", _prefix, appID);
	CFPreferencesSetValue((__bridge CFStringRef) key, @(selected), PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	notify_post("com.noahsaso.pusher/prefs");
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];

	NSString *displayIdentifier = [_appListDataSource displayIdentifierForIndexPath:indexPath];
	[self updatePreferencesForAppID:displayIdentifier selected:![self.selectedAppIDs containsObject:displayIdentifier]];

	[table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
