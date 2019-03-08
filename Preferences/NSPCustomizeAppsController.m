#import "NSPCustomizeAppsController.h"
#import "NSPSharedSpecifiers.h"
#import "NSPCustomAppController.h"
#import "NSPAppSelectionController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

static void setPreference(CFStringRef keyRef, CFPropertyListRef val, BOOL shouldNotify) {
	CFPreferencesSetValue(keyRef, val, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (shouldNotify) {
    // Reload stuff
    notify_post("com.noahsaso.pusher/prefs");
  }
}

@implementation NSPCustomizeAppsController

- (void)saveAppState {
	NSArray *enabledApps = _data[@"Enabled"];
	NSArray *disabledApps = _data[@"Disabled"];
	for (NSString *appID in enabledApps) {
		if ([_customApps.allKeys containsObject:appID]) {
			NSMutableDictionary *appDict = [(NSDictionary *)_customApps[appID] mutableCopy];
			appDict[@"enabled"] = @YES;
			_customApps[appID] = appDict;
		} else {
			_customApps[appID] = @{ @"enabled": @YES, @"devices": _defaultDevices };
		}
	}
	for (NSString *appID in disabledApps) {
		if ([_customApps.allKeys containsObject:appID]) {
			NSMutableDictionary *appDict = [(NSDictionary *)_customApps[appID] mutableCopy];
			appDict[@"enabled"] = @NO;
			_customApps[appID] = appDict;
		} else {
			_customApps[appID] = @{ @"enabled": @NO, @"devices": _defaultDevices };
		}
	}
	for (NSString *appID in _customApps.allKeys) {
		if (![enabledApps containsObject:appID] && ![disabledApps containsObject:appID]) {
			[_customApps removeObjectForKey:appID];
		}
	}
	setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFPropertyListRef) _customApps, YES);
}

- (void)dealloc {
	[_table release];
	[_sections release];
	[_data release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// End editing of previous view controller so updates prefs if editing text field
	if (self.navigationController.viewControllers && self.navigationController.viewControllers.count > 1) {
		UIViewController *viewController = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
		if (viewController) {
			[viewController.view endEditing:YES];
		}
	}

	_appList = [ALApplicationList sharedApplicationList];

	// Get preferences
	CFArrayRef keyList = CFPreferencesCopyKeyList(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	_service = [[self.specifier propertyForKey:@"service"] retain];
	_prefsKey = [Xstr(@"%@CustomApps", _service) retain];
	_customApps = [(prefs[_prefsKey] ?: @{}) mutableCopy];

	NSString *defaultDevicesKey = [self.specifier propertyForKey:@"defaultDevicesKey"];
	_defaultDevices = [(prefs[defaultDevicesKey] ?: @{}) copy];

	_sections = [@[@"", @"Enabled", @"Disabled"] retain];
	_data = [@{
		@"": @[@"Add Apps"],
		@"Enabled": [NSMutableArray new],
		@"Disabled": [NSMutableArray new]
	} mutableCopy];

	for (NSString *appID in _customApps.allKeys) {
		NSDictionary *customAppPrefs = _customApps[appID];
		BOOL enabled = customAppPrefs[@"enabled"] ? ((NSNumber *) customAppPrefs[@"enabled"]).boolValue : NO;
		if (enabled) {
			[_data[@"Enabled"] addObject:appID];
		} else {
			[_data[@"Disabled"] addObject:appID];
		}
	}

	_lastTargetAppID = @"";
	_lastTargetIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

	[self sortAppIDArray:_data[@"Enabled"]];
	[self sortAppIDArray:_data[@"Disabled"]];

	_table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"CustomAppCell"];
	_table.dataSource = self;
	_table.delegate = self;
	[self.view addSubview:_table];

	self.navigationItem.title = @"App Customization";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditing:)];

	[_table reloadData];
}

- (void)sortAppIDArray:(NSMutableArray *)array {
	[array sortUsingComparator:^NSComparisonResult(NSString *appID1, NSString *appID2) {
    NSString *first = _appList.applications[appID1];
    NSString *second = _appList.applications[appID2];
    return [first localizedCaseInsensitiveCompare:second];
	}];
}

- (void)toggleEditing:(UIBarButtonItem *)barButtonItem {
	[_table setEditing:![_table isEditing] animated:YES];
	barButtonItem.title = [_table isEditing] ? @"Done" : @"Edit";
}

- (void)addAppIDs:(NSArray *)appIDs {
	NSMutableArray *nonOverlappingAppIDs = [NSMutableArray new];
	for (NSString *appID in appIDs) {
		if (![_data[@"Enabled"] containsObject:appID] && ![_data[@"Disabled"] containsObject:appID]) {
			[nonOverlappingAppIDs addObject:appID];
		}
	}
	[_data[@"Enabled"] addObjectsFromArray:nonOverlappingAppIDs];
	[self sortAppIDArray:_data[@"Enabled"]];
	[self saveAppState];
	[_table reloadData];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	// Non-App
	if (indexPath.section == 0) {
		NSPAppSelectionController *appSelectionController = [NSPAppSelectionController new];
		appSelectionController.customizeAppsController = self;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:appSelectionController];
		[self presentViewController:navController animated:YES completion:nil];
		return;
	}
	NSString *appID = _data[_sections[indexPath.section]][indexPath.row];
	NSPCustomAppController *controller = [[NSPCustomAppController alloc] initWithService:_service appID:appID];
	[self pushController:controller];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return ((NSArray *) _data[_sections[section]]).count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
	return _sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return _sections[section];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"CustomAppCell" forIndexPath:indexPath];
	NSString *appID = _data[_sections[indexPath.section]][indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.imageView.image = nil;
	// Non-App
	if (indexPath.section == 0) {
		cell.textLabel.text = appID;
		return cell;
	}
	cell.textLabel.text = _appList.applications[appID];
	cell.imageView.image = [_appList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:appID];
	return cell;
}

- (BOOL)tableView:(UITableView *)table canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section > 0;
}

- (void)tableView:(UITableView *)table moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	_lastTargetAppID = @"";
	_lastTargetIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	NSString *appID = _data[_sections[sourceIndexPath.section]][sourceIndexPath.row];
	[_data[_sections[sourceIndexPath.section]] removeObjectAtIndex:sourceIndexPath.row];
	// sorted because target index path forces to be in right place
	[_data[_sections[destinationIndexPath.section]] insertObject:appID atIndex:destinationIndexPath.row];
	[self saveAppState];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section > 0) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

- (NSArray *)tableView:(UITableView *)table editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		return @[];
	}
	UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
		[_data[_sections[indexPath.section]] removeObjectAtIndex:indexPath.row];
		[self saveAppState];
		[table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}];
	return @[ deleteAction ];
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section > 0;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.section == 0
			|| sourceIndexPath.section == proposedDestinationIndexPath.section) {
		return sourceIndexPath;
	}
	NSString *appID = _data[_sections[sourceIndexPath.section]][sourceIndexPath.row];
	if (Xeq(appID, _lastTargetAppID)) {
		return _lastTargetIndexPath;
	}
	_lastTargetAppID = appID;
	NSMutableArray *tempArray = [[_data[_sections[proposedDestinationIndexPath.section]] arrayByAddingObject:appID] mutableCopy];
	[self sortAppIDArray:tempArray];
	_lastTargetIndexPath = [NSIndexPath indexPathForRow:[tempArray indexOfObject:appID] inSection:proposedDestinationIndexPath.section];
	return _lastTargetIndexPath;
}

@end
