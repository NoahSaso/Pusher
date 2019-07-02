#import "NSPLogController.h"
#import "NSPAppSelectionController.h"

static NSPLogController *logControllerSharedInstance = nil;
static void logsUpdated() {
	if (logControllerSharedInstance && [logControllerSharedInstance isKindOfClass:NSPLogController.class] && [logControllerSharedInstance respondsToSelector:@selector(updateLogAndReload)]) {
		[logControllerSharedInstance updateLogAndReload];
	}
}

static NSDictionary *getLogPreferences() {
	CFPreferencesSynchronize(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}
	return prefs;
}

@implementation NSPLogController

- (void)dealloc {
	logControllerSharedInstance = nil;
	[_table release];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	logControllerSharedInstance = self;
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)logsUpdated, CFSTR(PUSHER_LOG_PREFS_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);

	_table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"LogCell"];
	_table.delegate = self;
	_table.dataSource = self;
	[self.view addSubview:_table];

	_service = [[self.specifier propertyForKey:@"service"] ?: @"" retain];
	_global = XIS_EMPTY(_service);
	_logKey = [Xstr(@"%@Log", _service) retain];
	_logEnabledKey = [Xstr(@"%@LogEnabled", _service) retain];

	self.navigationItem.title = [self.specifier propertyForKey:@"label"] ?: @"Log";

	CFPropertyListRef logEnabledRef = CFPreferencesCopyValue((__bridge CFStringRef) _logEnabledKey, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	_logEnabled = logEnabledRef ? ((__bridge NSNumber *) logEnabledRef).boolValue : YES;

	[self updateLog];

	[_table reloadData];
}

- (void)updateLogEnabled:(UISwitch *)logEnabledSwitch {
	_logEnabled = logEnabledSwitch.isOn;
	CFPreferencesSetValue((__bridge CFStringRef) _logEnabledKey, (__bridge CFNumberRef) @(_logEnabled), PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	notify_post(PUSHER_PREFS_NOTIFICATION);
}

- (void)updateLogAndReload {
	[self updateLog];
	[_table reloadData];
}

- (void)updateLog {
	NSDictionary *prefs = getLogPreferences();

	if (_sections) {
		[_sections release];
	}
	_sections = [@[
		@"Settings",
		@"Filters"
	] mutableCopy];

	if (_data) {
		[_data release];
	}
	_data = [@{
		_sections[0]: [@[
			@"Logger Enabled",
			@"Clear Existing Logs"
		] mutableCopy],
		_sections[1]: @[
			@"Network Response",
			@"App"
		]
	} mutableCopy];

	if (_global) {
		// remove enabled switch because global can't be disabled
		[_data[_sections[0]] removeObjectAtIndex:0];
		_logEnabledSwitchRow = -1;
		_clearLogRow = 0;
	} else {
		_logEnabledSwitchRow = 0;
		_clearLogRow = 1;
	}

	_firstLogSection = _data.count;

	_expandedIndexPaths = [NSMutableArray new];

	NSArray *prefsLog = nil;
	if (_global) {
		NSMutableArray *allLogs = [NSMutableArray new];
		for (id key in prefs.allKeys) {
			if (![key isKindOfClass:NSString.class]) { continue; }
			// should be all but just in case change implementation later
			if ([key hasSuffix:@"Log"]) {
				NSString *service = [key substringToIndex:((NSString *) key).length - 3];
				NSArray *serviceLogs = (NSArray *) prefs[key];
				if (!serviceLogs) { continue; }
				for (NSDictionary *logSection in serviceLogs) {
					NSMutableDictionary *newLogSection = [logSection mutableCopy];
					newLogSection[@"name"] = Xstr(@"[%@] %@", service, newLogSection[@"name"]);
					[allLogs addObject:newLogSection];
				}
			}
		}
		prefsLog = allLogs;
	} else {
		prefsLog = prefs[_logKey] ?: @[];
	}

	// sort prefs log by timestamp
	NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
	prefsLog = [prefsLog sortedArrayUsingDescriptors:@[timestampDescriptor]];

	for (NSDictionary *logSection in prefsLog) {
		NSString *sectionName = logSection[@"name"] ?: @"Section";
		NSArray *logs = logSection[@"logs"] ?: @[];
		[_sections addObject:sectionName];
		_data[sectionName] = [logs retain];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	// Clear log button
	if (indexPath.section == 0 && indexPath.row == _clearLogRow) {
		if (_global) {
			NSDictionary *prefs = getLogPreferences();
			for (id key in prefs.allKeys) {
				if (![key isKindOfClass:NSString.class]) { continue; }
				// should be all but just in case change implementation later
				if ([key hasSuffix:@"Log"]) {
					CFPreferencesSetValue((__bridge CFStringRef) key, NULL, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				}
			}
			CFPreferencesSynchronize(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		} else {
			CFPreferencesSetValue((__bridge CFStringRef) _logKey, NULL, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		}

		int numSections = [self numberOfSectionsInTableView:tableView];
		if (numSections >= _firstLogSection) {
			[tableView beginUpdates];
			[self updateLog];
			[tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, numSections - _firstLogSection)] withRowAnimation:UITableViewRowAnimationAutomatic];
			[tableView endUpdates];
		}
	} else if (indexPath.section == 1 && indexPath.row == 1) {
		// app filter
		NSPAppSelectionController *appSelectionController = [NSPAppSelectionController new];
		appSelectionController.title = @"Select an App";
		appSelectionController.selectingMultiple = NO;
		[appSelectionController add]
		appSelectionController.customizeAppsController = self;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:appSelectionController];
		[self presentViewController:navController animated:YES completion:nil];
	} else if (indexPath.section >= _firstLogSection) {
		if ([_expandedIndexPaths containsObject:indexPath]) {
			[_expandedIndexPaths removeObject:indexPath];
		} else {
			[_expandedIndexPaths addObject:indexPath];
		}
		[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return _sections[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ((NSArray *) _data[_sections[section]]).count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return _sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogCell" forIndexPath:indexPath];
	cell.textLabel.text = _data[_sections[indexPath.section]][indexPath.row];
	BOOL expanded = [_expandedIndexPaths containsObject:indexPath];
	cell.textLabel.numberOfLines = expanded ? 0 : 1;
	cell.textLabel.lineBreakMode = expanded ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;

	CGSize textSize = [cell.textLabel.text sizeWithAttributes:@{NSFontAttributeName: cell.textLabel.font}];
	BOOL isTruncated = textSize.width > cell.contentView.bounds.size.width;
	if ((indexPath.section == 0 && indexPath.row == _clearLogRow)
			|| (indexPath.section == 1 && indexPath.row > 0)
			|| (indexPath.section >= _firstLogSection && !expanded && isTruncated)) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	UISwitch *logEnabledSwitch = (UISwitch *) cell.accessoryView;
	if (indexPath.section == 0 && indexPath.row == _logEnabledSwitchRow) {
		if (!logEnabledSwitch || ![logEnabledSwitch isKindOfClass:UISwitch.class]) {
			logEnabledSwitch = [UISwitch new];
			logEnabledSwitch.on = _logEnabled;
			[logEnabledSwitch addTarget:self action:@selector(updateLogEnabled:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = logEnabledSwitch;
		}
	} else {
		cell.accessoryView = nil;
	}
	return cell;
}

@end
