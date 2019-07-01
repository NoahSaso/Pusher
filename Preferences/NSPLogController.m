#import "NSPLogController.h"

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

	_service = [self.specifier propertyForKey:@"service"];

	[self updateLog];

	self.selectedAppIDs = [NSMutableArray new];
	for (id key in _prefs.allKeys) {
		if (![key isKindOfClass:NSString.class]) { continue; }
		if ([key hasPrefix:_prefix] && ((NSNumber *) _prefs[key]).boolValue) {
			NSString *subKey = [key substringFromIndex:_prefix.length];
			[self.selectedAppIDs addObject:subKey];
		}
	}

	[_table reloadData];
}

- (void)updateLog {
	CFPreferencesSynchronize(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	if (_sections) {
		[_sections removeAllObjects];
	} else {
		_sections = [NSMutableArray new];
	}

	if (_data) {
		[_data removeAllObjects];
	} else {
		_data = [NSMutableDictionary new];
	}

	NSString *logKey = Xstr(@"%@Log", _service);
	CFPropertyListRef prefsLogRef = CFPreferencesCopyValue((__bridge CFStringRef) logKey, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSArray *prefsLog = prefsLogRef ?: (__bridge NSArray *) prefsLogRef : @[];

	for (NSDictionary *logSection) {
		NSString *section = logSection[@"section"] ?: @"Section";
		NSArray *logs = logSection[@"logs"] ?: @[];
		[_sections addObject:section];
		_data[section] = [logs retain];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 && indexPath.row == 0;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];

	// Clear log button
	if (indexPath.section == 0 && indexPath.row == 0) {

	}
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"LogCell" forIndexPath:indexPath];
	cell.textLabel.text = _data[_sections[indexPath.section]][indexPath.row];
	return cell;
}

@end
