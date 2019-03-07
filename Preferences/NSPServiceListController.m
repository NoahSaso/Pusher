#include "NSPServiceListController.h"
#import "NSPServiceController.h"

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

@implementation NSPServiceListController

- (void)dealloc {
	[_prefs release];
	[_table release];
	[_sections release];
	[_data release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Get preferences
	CFArrayRef keyList = CFPreferencesCopyKeyList(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	_prefs = @{};
	if (keyList) {
		_prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!_prefs) { _prefs = @{}; }
		CFRelease(keyList);
	}

	_sections = [@[@"Enabled", @"Disabled"] retain];
	_data = [@{
		@"Enabled": [NSMutableArray new],
		@"Disabled": [NSMutableArray new]
	} mutableCopy];
	_services = [PUSHER_SERVICES retain];

	for (NSString *service in _services) {
		NSString *enabledKey = Xstr(@"%@Enabled", service);
		if (_prefs[enabledKey] && ((NSNumber *) _prefs[enabledKey]).boolValue) {
			[_data[@"Enabled"] addObject:service];
		} else {
			[_data[@"Disabled"] addObject:service];
		}
	}

	_table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"ServiceCell"];
	_table.dataSource = self;
	_table.delegate = self;
	[self.view addSubview:_table];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditing:)];

	[_table reloadData];
}

- (void)toggleEditing:(UIBarButtonItem *)barButtonItem {
	[_table setEditing:![_table isEditing] animated:YES];
	barButtonItem.title = [_table isEditing] ? @"Save" : @"Edit";
	if (![_table isEditing]) {
		// Save
		for (NSString *service in _services) {
			NSString *enabledKey = Xstr(@"%@Enabled", service);
			setPreference((__bridge CFStringRef) enabledKey, (__bridge CFNumberRef) [NSNumber numberWithBool:[_data[@"Enabled"] containsObject:service]], NO);
		}
		notify_post("com.noahsaso.pusher/prefs");
	}
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	NSString *service = _data[_sections[indexPath.section]][indexPath.row];
	NSPServiceController *listController = [[NSPServiceController alloc] initWithService:service];
	[self pushController:listController];
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

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"ServiceCell" forIndexPath:indexPath];
	cell.textLabel.text = _data[_sections[indexPath.section]][indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (BOOL)tableView:(UITableView *)table canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSString *service = _data[_sections[sourceIndexPath.section]][sourceIndexPath.row];
	[_data[_sections[sourceIndexPath.section]] removeObjectAtIndex:sourceIndexPath.row];
	[_data[_sections[destinationIndexPath.section]] insertObject:service atIndex:destinationIndexPath.row];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

@end
