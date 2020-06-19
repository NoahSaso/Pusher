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
    notify_post(PUSHER_PREFS_NOTIFICATION);
  }
}

@implementation NSPCustomizeAppsController

- (void)setAppDefaults:(NSString *)appID {
	if ([_customApps.allKeys containsObject:appID]) {
			NSMutableDictionary *appDict = [(NSDictionary *)_customApps[appID] mutableCopy];
			appDict[@"enabled"] = @YES;
			_customApps[appID] = appDict;
	} else {
		NSMutableDictionary *defaultDict = [@{ @"enabled": @YES } mutableCopy];
		if (Xeq(_service, PUSHER_SERVICE_PUSHOVER) || Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
			defaultDict[@"devices"] = _defaultDevices;
		}
		if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
			defaultDict[@"sounds"] = _defaultSounds;
		}
		if (Xeq(_service, PUSHER_SERVICE_IFTTT)) {
			defaultDict[@"eventName"] = _defaultEventName;
		}
		if (_isCustomService || Xeq(_service, PUSHER_SERVICE_IFTTT) || Xeq(_service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
			defaultDict[@"includeIcon"] = _defaultIncludeIcon;
		}
		if (_isCustomService || Xeq(_service, PUSHER_SERVICE_PUSHER_RECEIVER) || Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
			defaultDict[@"includeImage"] = _defaultIncludeImage;
			defaultDict[@"imageMaxWidth"] = _defaultImageMaxWidth;
			defaultDict[@"imageMaxHeight"] = _defaultImageMaxHeight;
			defaultDict[@"imageShrinkFactor"] = _defaultImageShrinkFactor;
		}
		if (_isCustomService || Xeq(_service, PUSHER_SERVICE_IFTTT)) {
			defaultDict[@"curateData"] = _defaultCurateData;
		}
		_customApps[appID] = defaultDict;
	}
}

- (void)saveAppState {
	NSArray *appIDs = _data[@"Apps"];
	for (NSString *appID in appIDs) {
		[self setAppDefaults:appID];
	}
	for (NSString *appID in _customApps.allKeys) {
		if (![appIDs containsObject:appID]) {
			[_customApps removeObjectForKey:appID];
		}
	}
	[self updateTitle];
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
	_isCustomService = [self.specifier propertyForKey:@"isCustomService"] && ((NSNumber *)[self.specifier propertyForKey:@"isCustomService"]).boolValue;
	_prefsKey = [(_isCustomService ? NSPPreferenceCustomServiceCustomAppsKey(_service) : NSPPreferenceBuiltInServiceCustomAppsKey(_service)) retain];

	_lastTargetAppID = nil;
	_lastTargetIndexPath = nil;

	_loadedAppControllers = [NSMutableDictionary new];

	CGRect tableFrame = self.view.bounds;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableFrame = self.rootController.view.bounds;
	}
	_table = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
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

	_label = [[self.specifier.name componentsSeparatedByString:@" ("][0] retain];
	[self updateTitle];

	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER) || Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
		_defaultDevices = [(prefs[[self.specifier propertyForKey:@"defaultDevicesKey"]] ?: @[]) copy];
	}
	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
		_defaultSounds = [(prefs[[self.specifier propertyForKey:@"defaultSoundsKey"]] ?: @[]) copy];
        _defaultIncludeImage = [(prefs[[self.specifier propertyForKey:@"defaultIncludeImageKey"]] ?: @YES) copy];
        _defaultImageMaxWidth = [(prefs[[self.specifier propertyForKey:@"defaultImageMaxWidthKey"]] ?: @(PUSHER_DEFAULT_MAX_WIDTH)) copy];
        _defaultImageMaxHeight = [(prefs[[self.specifier propertyForKey:@"defaultImageMaxHeightKey"]] ?: @(PUSHER_DEFAULT_MAX_HEIGHT)) copy];
        _defaultImageShrinkFactor = [(prefs[[self.specifier propertyForKey:@"defaultImageShrinkFactorKey"]] ?: @(PUSHER_DEFAULT_SHRINK_FACTOR)) copy];
	}
	if (Xeq(_service, PUSHER_SERVICE_IFTTT)) {
		_defaultEventName = [(prefs[[self.specifier propertyForKey:@"defaultEventNameKey"]] ?: @"") copy];
		_defaultIncludeIcon = [(prefs[[self.specifier propertyForKey:@"defaultIncludeIconKey"]] ?: @NO) copy];
		_defaultCurateData = [(prefs[[self.specifier propertyForKey:@"defaultCurateDataKey"]] ?: @YES) copy];
	}
	if (Xeq(_service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
		_defaultIncludeIcon = [(prefs[[self.specifier propertyForKey:@"defaultIncludeIconKey"]] ?: @YES) copy];
		_defaultIncludeImage = [(prefs[[self.specifier propertyForKey:@"defaultIncludeImageKey"]] ?: @YES) copy];
		_defaultImageMaxWidth = [(prefs[[self.specifier propertyForKey:@"defaultImageMaxWidthKey"]] ?: @(PUSHER_DEFAULT_MAX_WIDTH)) copy];
		_defaultImageMaxHeight = [(prefs[[self.specifier propertyForKey:@"defaultImageMaxHeightKey"]] ?: @(PUSHER_DEFAULT_MAX_HEIGHT)) copy];
		_defaultImageShrinkFactor = [(prefs[[self.specifier propertyForKey:@"defaultImageShrinkFactorKey"]] ?: @(PUSHER_DEFAULT_SHRINK_FACTOR)) copy];
	}
	if (_isCustomService) {
		NSDictionary *customService = (prefs[NSPPreferenceCustomServicesKey] ?: @{})[_service] ?: @{};
		_defaultIncludeIcon = [(customService[[self.specifier propertyForKey:@"defaultIncludeIconKey"]] ?: @NO) copy];
		_defaultIncludeImage = [(customService[[self.specifier propertyForKey:@"defaultIncludeImageKey"]] ?: @NO) copy];
		_defaultImageMaxWidth = [(customService[[self.specifier propertyForKey:@"defaultImageMaxWidthKey"]] ?: @(PUSHER_DEFAULT_MAX_WIDTH)) copy];
		_defaultImageMaxHeight = [(customService[[self.specifier propertyForKey:@"defaultImageMaxHeightKey"]] ?: @(PUSHER_DEFAULT_MAX_HEIGHT)) copy];
		_defaultImageShrinkFactor = [(customService[[self.specifier propertyForKey:@"defaultImageShrinkFactorKey"]] ?: @(PUSHER_DEFAULT_SHRINK_FACTOR)) copy];
	}

	_sections = [@[@"", @"Apps"] retain];
	_data = [@{
		@"": @[@"Add Apps"],
		@"Apps": [NSMutableArray new],
	} mutableCopy];

	[_data[@"Apps"] addObjectsFromArray:_customApps.allKeys];

	[self sortAppIDArray:_data[@"Apps"]];

	[_table reloadData];
}

- (void)updateTitle {
	self.specifier.name = Xstr(@"%@ (%d total)", _label, (int) _customApps.count);
	PSListController *listController = (PSListController *)[self.specifier propertyForKey:@"psListRef"];
	if (listController) {
		[listController reloadSpecifier:self.specifier];
	}
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
		if (![_data[@"Apps"] containsObject:appID]) {
			[nonOverlappingAppIDs addObject:appID];
		}
	}
	[_data[@"Apps"] addObjectsFromArray:nonOverlappingAppIDs];
	[self sortAppIDArray:_data[@"Apps"]];
	[self saveAppState];
	[_table reloadData];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	// Non-App
	if (indexPath.section == 0) {
		NSPAppSelectionController *appSelectionController = [NSPAppSelectionController new];
		[appSelectionController setCallback:^(id appIDs) {
			[self addAppIDs:(NSArray *) appIDs];
		}];
		appSelectionController.navItemTitle = @"Add Apps";
		appSelectionController.rightButtonTitle = @"Add";
		appSelectionController.selectingMultiple = YES;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:appSelectionController];
		navController.navigationBar.tintColor = NSPusherManager.sharedController.activeTintColor;
		[self presentViewController:navController animated:YES completion:nil];
		return;
	}
	NSString *appID = _data[_sections[indexPath.section]][indexPath.row];
	NSPCustomAppController *controller;
	if ([_loadedAppControllers.allKeys containsObject:appID]) {
		controller = _loadedAppControllers[appID];
	} else {
		NSString *appTitle = _appList.applications[appID] ?: @"UNKNOWN APP";
		controller = [[NSPCustomAppController alloc] initWithService:_service appID:appID appTitle:appTitle isCustomService:_isCustomService];
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

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
	NSString *title = _sections[section];
	if (Xeq(title, @"Apps") && [self tableView:table numberOfRowsInSection:section] == 0) {
		title = @"No Apps";
	}
	return title;
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

		// do all this fancy transition stuff to animate header to 'No Apps' if last one deleted (unnecessary but user experience is TOP priority!11!!!1)
		[CATransaction begin];
		[table beginUpdates];
		if (((NSArray *) _data[_sections[indexPath.section]]).count == 0) {
			[CATransaction setCompletionBlock:^{
				[table reloadData];
			}];
		}
		[table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		[table endUpdates];
		[CATransaction commit];
	}];
	return @[deleteAction];
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section > 0;
}

@end
