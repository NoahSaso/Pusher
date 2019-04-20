#import "NSPCustomizeAppsController.h"
#import "NSPSharedSpecifiers.h"
#import "NSPCustomAppController.h"
#import "NSPAppSelectionController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

static void setPreference(CFStringRef keyRef, CFPropertyListRef val, BOOL shouldNotify) {
	CFPreferencesSetValue(keyRef, val, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (shouldNotify) {
    // Reload stuff
    notify_post("com.noahsaso.pusher/prefs");
  }
}

@implementation NSPCustomizeAppsController

- (void)setDefaultsFor:(NSString *)appID enabled:(BOOL)enabled {
	if ([_customApps.allKeys containsObject:appID]) {
			NSMutableDictionary *appDict = [(NSDictionary *)_customApps[appID] mutableCopy];
			appDict[@"enabled"] = @NO;
			_customApps[appID] = appDict;
	} else {
		NSMutableDictionary *defaultDict = [@{ @"enabled": [NSNumber numberWithBool:enabled] } mutableCopy];
		if (Xeq(_service, PUSHER_SERVICE_PUSHOVER) || Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
			defaultDict[@"devices"] = _defaultDevices;
		}
		if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
			defaultDict[@"sounds"] = _defaultSounds;
		}
		if (Xeq(_service, PUSHER_SERVICE_IFTTT)) {
			defaultDict[@"eventName"] = _defaultEventName;
			defaultDict[@"includeIcon"] = _defaultIncludeIcon;
		}
		_customApps[appID] = defaultDict;
	}
}

- (void)saveAppState {
	NSArray *enabledApps = _data[@"Enabled"];
	NSArray *disabledApps = _data[@"Disabled"];
	for (NSString *appID in enabledApps) {
		[self setDefaultsFor:appID enabled:YES];
	}
	for (NSString *appID in disabledApps) {
		[self setDefaultsFor:appID enabled:NO];
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

- (void)viewDidLoad {
	[super viewDidLoad];

	_appList = [ALApplicationList sharedApplicationList];

	_service = [[self.specifier propertyForKey:@"service"] retain];
	_prefsKey = [Xstr(@"%@CustomApps", _service) retain];

	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER) || Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
		_defaultDevicesKey = [self.specifier propertyForKey:@"defaultDevicesKey"];
	}
	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
		_defaultSoundsKey = [self.specifier propertyForKey:@"defaultSoundsKey"];
	}
	if (Xeq(_service, PUSHER_SERVICE_IFTTT)) {
		_defaultEventNameKey = [self.specifier propertyForKey:@"defaultEventNameKey"];
		_defaultIncludeIconKey = [self.specifier propertyForKey:@"defaultIncludeIconKey"];
	}

	_lastTargetAppID = nil;
	_lastTargetIndexPath = nil;

	_loadedAppControllers = [NSMutableDictionary new];

	_table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"CustomAppCell"];
	_table.dataSource = self;
	_table.delegate = self;
	[self.view addSubview:_table];

	self.navigationItem.title = @"App Customization";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditing:)];
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

	// Get preferences
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	_customApps = [(prefs[_prefsKey] ?: @{}) mutableCopy];

	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER) || Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
		_defaultDevices = [(prefs[_defaultDevicesKey] ?: @[]) copy];
	}
	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
		_defaultSounds = [(prefs[_defaultSoundsKey] ?: @[]) copy];
	}
	if (Xeq(_service, PUSHER_SERVICE_IFTTT)) {
		_defaultEventName = [(prefs[_defaultEventNameKey] ?: @"") copy];
		_defaultIncludeIcon = [(prefs[_defaultIncludeIconKey] ?: @NO) copy];
	}

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

	[self sortAppIDArray:_data[@"Enabled"]];
	[self sortAppIDArray:_data[@"Disabled"]];

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
	NSPCustomAppController *controller;
	if ([_loadedAppControllers.allKeys containsObject:appID]) {
		controller = _loadedAppControllers[appID];
	} else {
		controller = [[NSPCustomAppController alloc] initWithService:_service appID:appID];
		_loadedAppControllers[appID] = controller;
	}
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
	_lastTargetAppID = nil;
	_lastTargetIndexPath = nil;
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
	if (_lastTargetAppID && Xeq(appID, _lastTargetAppID)) {
		return _lastTargetIndexPath;
	}
	_lastTargetAppID = appID;
	NSMutableArray *tempArray = [[_data[_sections[proposedDestinationIndexPath.section]] arrayByAddingObject:appID] mutableCopy];
	[self sortAppIDArray:tempArray];
	_lastTargetIndexPath = [NSIndexPath indexPathForRow:[tempArray indexOfObject:appID] inSection:proposedDestinationIndexPath.section];
	return _lastTargetIndexPath;
}

@end
