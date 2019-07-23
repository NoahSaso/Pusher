#import "NSPAppListController.h"
#import "NSPAppListALApplicationTableDataSource.h"

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

@implementation NSPAppListALApplicationTableDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	NSString *displayIdentifier = [self displayIdentifierForIndexPath:indexPath];
	cell.accessoryType = [self.appListController.selectedAppIDs containsObject:displayIdentifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.tintColor = NSPusherManager.sharedController.activeTintColor;
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

	CGRect tableFrame = self.view.bounds;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableFrame = self.rootController.view.bounds;
	}
	_table = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"AppCell"];
	_table.delegate = self;
	[self.view addSubview:_table];

	_appList = [ALApplicationList sharedApplicationList];
	_appListDataSource = [NSPAppListALApplicationTableDataSource new];
	_appListDataSource.sectionDescriptors = [NSPAppListALApplicationTableDataSource standardSectionDescriptors];
	_appListDataSource.appListController = self;

	_searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	_searchController.searchResultsUpdater = self;
	_searchController.hidesNavigationBarDuringPresentation = NO;
	_searchController.dimsBackgroundDuringPresentation = NO;
	[_searchController.searchBar sizeToFit];
	_searchController.searchBar.tintColor = NSPusherManager.sharedController.activeTintColor;
	_table.tableHeaderView = _searchController.searchBar;

	_table.dataSource = _appListDataSource;
	_appListDataSource.tableView = _table;

	_prefix = [self.specifier propertyForKey:@"ALSettingsKeyPrefix"];

	// Get preferences
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	_prefs = @{};
	if (keyList) {
		_prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!_prefs) { _prefs = @{}; }
		CFRelease(keyList);
	}

	self.selectedAppIDs = [NSMutableArray new];
	for (id key in _prefs.allKeys) {
		if (![key isKindOfClass:NSString.class]) { continue; }
		if ([key hasPrefix:_prefix] && ((NSNumber *) _prefs[key]).boolValue) {
			NSString *subKey = [key substringFromIndex:_prefix.length];
			[self.selectedAppIDs addObject:subKey];
		}
	}

	_label = [[self.specifier.name componentsSeparatedByString:@" ("][0] retain];
	[self updateTitle];

	[_table reloadData];
}

- (void)updateTitle {
	self.navigationItem.title = Xstr(@"%@ (%d total)", _label, (int) self.selectedAppIDs.count);
	self.specifier.name = self.navigationItem.title;
	PSListController *listController = (PSListController *)[self.specifier propertyForKey:@"psListRef"];
	if (listController) {
		[listController reloadSpecifier:self.specifier];
	}
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
	notify_post(PUSHER_PREFS_NOTIFICATION);
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];

	NSString *displayIdentifier = [_appListDataSource displayIdentifierForIndexPath:indexPath];
	[self updatePreferencesForAppID:displayIdentifier selected:![self.selectedAppIDs containsObject:displayIdentifier]];

	[table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!_prefs[@"AppListTutorialShown"] || !((NSNumber *) _prefs[@"AppListTutorialShown"]).boolValue) {
		[self showTutorial];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	_searchController.active = NO;
}

- (void)showTutorial {
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	UIView *tutorialView = [[UIView alloc] initWithFrame:window.bounds];
	tutorialView.alpha = 0.f;
	tutorialView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.9f];

	// Label setup
	UILabel *label = [UILabel new];
	label.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:UIFont.systemFontSize * 1.5f];
	label.textColor = UIColor.whiteColor;
	label.text = @"Tap on the apps you want to be in the list, and checkmarks will indicate which apps are selected. The Blacklist / Whitelist setting in the previous menu determines what function this app list serves.\n\nTap anywhere to continue.";
	label.lineBreakMode = NSLineBreakByWordWrapping;
	label.numberOfLines = 0;
	label.translatesAutoresizingMaskIntoConstraints = NO;
	label.textAlignment = NSTextAlignmentCenter;
	[tutorialView addSubview:label];

	// Constraints
	[label addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:270]];
	[label addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:tutorialView.frame.size.height]];
	[label.centerXAnchor constraintEqualToAnchor:label.superview.centerXAnchor].active = YES;
	[label.centerYAnchor constraintEqualToAnchor:label.superview.centerYAnchor].active = YES;

	[window addSubview:tutorialView];
	[UIView animateWithDuration:0.3 animations:^{ tutorialView.alpha = 1.f; }];

	// Add touch action after a second
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTutorial:)];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		// Dismiss gesture
		[tutorialView addGestureRecognizer:tapGestureRecognizer];
	});

	CFStringRef tutorialKeyRef = CFSTR("AppListTutorialShown");
	setPreference(tutorialKeyRef, (__bridge CFNumberRef) @YES, NO);
	CFRelease(tutorialKeyRef);
	NSMutableDictionary *mutablePrefs = [_prefs mutableCopy];
	mutablePrefs[@"AppListTutorialShown"] = @YES;
	_prefs = [mutablePrefs copy];
}

- (void)dismissTutorial:(UITapGestureRecognizer *)tapGestureRecognizer {
	UIView *tutorialView = tapGestureRecognizer.view;
	[UIView animateWithDuration:0.3 animations:^{ tutorialView.alpha = 0.f; } completion:^(BOOL finished){ [tutorialView removeFromSuperview]; }];
}

@end
