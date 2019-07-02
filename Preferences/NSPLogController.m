#import "NSPLogController.h"

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
	[_table release];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];

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
	notify_post("com.noahsaso.pusher/prefs");
}

- (void)updateLog {
	NSDictionary *prefs = getLogPreferences();

	if (_sections) {
		[_sections removeAllObjects];
	} else {
		_sections = [@[@"Settings"] mutableCopy];
	}

	if (_data) {
		[_data removeAllObjects];
	} else {
		_data = [@{
			_sections[0]: @[
				@"Logger Enabled",
				@"Clear Existing Logs"
			]
		} mutableCopy];
	}

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

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 && indexPath.row == 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	// Clear log button
	if (indexPath.section == 0 && indexPath.row == 1) {
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
		if (numSections > 1) {
			[tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, numSections - 1)] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self updateLog];
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
	UISwitch *logEnabledSwitch = (UISwitch *) cell.accessoryView;
	if (indexPath.section == 0 && indexPath.row == 0) {
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
