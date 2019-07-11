#import "NSPServiceListController.h"
#import "NSPServiceController.h"

static void setPreference(CFStringRef keyRef, CFPropertyListRef val, BOOL shouldNotify) {
	CFPreferencesSetValue(keyRef, val, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (shouldNotify) {
    // Reload stuff
    notify_post(PUSHER_PREFS_NOTIFICATION);
  }
}

@implementation NSPServiceListController

- (void)dealloc {
	[_serviceImages release];
	[_prefs release];
	[_table release];
	[_sections release];
	[_data release];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_lastTargetService = nil;
	_lastTargetIndexPath = nil;

	_loadedServiceControllers = [NSMutableDictionary new];

	_table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"ServiceCell"];
	_table.dataSource = self;
	_table.delegate = self;
	_table.allowsSelectionDuringEditing = YES;
	[self.view addSubview:_table];
	_addNewServiceBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addNewService)];

	self.navigationItem.title = @"Services";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditing:)];
	self.navigationItem.leftBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// load each time to override NSPRootListController
	[NSPusherManager.sharedController setActiveTintColor:nil];
	[self tintUIToPusherColor];

	// Get preferences
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	_prefs = @{};
	if (keyList) {
		_prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!_prefs) { _prefs = @{}; }
		CFRelease(keyList);
	}

	_sections = [@[@"Enabled", @"Disabled"] retain];
	_data = [@{
		@"Enabled": [NSMutableArray new],
		@"Disabled": [NSMutableArray new]
	} mutableCopy];
	_services = [BUILTIN_PUSHER_SERVICES retain];
	_customServices = [(NSDictionary *)(_prefs[NSPPreferenceCustomServicesKey] ?: @{}) mutableCopy];

	_defaultImage = [UIImage imageNamed:DEFAULT_SERVICE_IMAGE_NAME inBundle:PUSHER_BUNDLE];
	_serviceImages = [NSMutableDictionary new];

	for (NSString *service in _services) {
		NSString *enabledKey = Xstr(@"%@Enabled", service);
		if (_prefs[enabledKey] && ((NSNumber *) _prefs[enabledKey]).boolValue) {
			[_data[@"Enabled"] addObject:service];
		} else {
			[_data[@"Disabled"] addObject:service];
		}
		_serviceImages[service] = [UIImage imageNamed:Xstr(@"BuiltInService_%@", service) inBundle:PUSHER_BUNDLE] ?: _defaultImage;
	}

	// make deep mutable and preload service images
	for (NSString *customService in _customServices.allKeys) {
		_customServices[customService] = [(_customServices[customService] ?: @{}) mutableCopy];
		if (_customServices[customService] && _customServices[customService][@"Enabled"] && ((NSNumber *) _customServices[customService][@"Enabled"]).boolValue) {
			[_data[@"Enabled"] addObject:customService];
		} else {
			[_data[@"Disabled"] addObject:customService];
		}
		_serviceImages[customService] = [UIImage imageNamed:Xstr(@"CustomService_%@", customService) inBundle:PUSHER_BUNDLE] ?: _defaultImage;
	}

	[_data[@"Enabled"] sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[_data[@"Disabled"] sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	[_table reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!_prefs[@"ServiceListTutorialShown"] || !((NSNumber *) _prefs[@"ServiceListTutorialShown"]).boolValue) {
		[self showTutorial];
	}
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
	label.text = @"After setting up your services, remember to enable them by using the 'Edit' button in the top right of this page and dragging your services to the 'Enabled' section at the top.\n\nTap anywhere to continue.";
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

	CFStringRef tutorialKeyRef = CFSTR("ServiceListTutorialShown");
	setPreference(tutorialKeyRef, (__bridge CFNumberRef) @YES, NO);
	CFRelease(tutorialKeyRef);
	NSMutableDictionary *mutablePrefs = [_prefs mutableCopy];
	mutablePrefs[@"ServiceListTutorialShown"] = @YES;
	_prefs = [mutablePrefs copy];
}

- (void)dismissTutorial:(UITapGestureRecognizer *)tapGestureRecognizer {
	UIView *tutorialView = tapGestureRecognizer.view;
	[UIView animateWithDuration:0.3 animations:^{ tutorialView.alpha = 0.f; } completion:^(BOOL finished){ [tutorialView removeFromSuperview]; }];
}

- (void)toggleEditing:(UIBarButtonItem *)barButtonItem {
	[_table setEditing:![_table isEditing] animated:YES];
	barButtonItem.title = [_table isEditing] ? @"Done" : @"Edit";
	self.navigationItem.leftBarButtonItem = [_table isEditing] ? _addNewServiceBarButtonItem : nil;
	if (![_table isEditing]) {
		// Save
		for (NSString *service in _services) {
			NSString *enabledKey = Xstr(@"%@Enabled", service);
			setPreference((__bridge CFStringRef) enabledKey, (__bridge CFNumberRef) @([_data[@"Enabled"] containsObject:service]), NO);
		}
		for (NSString *customService in _customServices.allKeys) {
			NSNumber *customServiceEnabled = @([_data[@"Enabled"] containsObject:customService]);
			if (!_customServices[customService]) {
				_customServices[customService] = [@{
					@"Enabled": customServiceEnabled
				} mutableCopy];
			} else {
				_customServices[customService][@"Enabled"] = customServiceEnabled;
			}
		}
		[self saveCustomServices]; // will notify post
		// notify_post(PUSHER_PREFS_NOTIFICATION);
	}
}

- (void)addNewService {
	UIAlertController *alert = XalertWTitle(@"Add Pusher Service", nil);
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.placeholder = @"Service Name";
	}];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	id handler = ^(UIAlertAction *action) {
		UITextField *textField = alert.textFields[0];
		if (!textField || !textField.text) {
			return;
		}
		NSString *newServiceName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (newServiceName.length < 1) {
			return;
		}
		if ([_customServices.allKeys containsObject:newServiceName] || [_services containsObject:newServiceName]) {
			id existsHandler = ^(UIAlertAction *existsAction) {
				[self addNewService];
			};
			UIAlertController *existsAlert = XalertWTitle(@"Add Pusher Service", @"A service with that name already exists.");
			[existsAlert addAction:XalertBtnWHandler(@"Ok", existsHandler)];
			[self presentViewController:existsAlert animated:YES completion:nil];
			return;
		}
		_customServices[newServiceName] = [@{
			@"Enabled": @NO
		} mutableCopy];
		[_data[@"Disabled"] addObject:newServiceName];
	  [_data[@"Disabled"] sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		_serviceImages[newServiceName] = [UIImage imageNamed:Xstr(@"CustomService_%@", newServiceName) inBundle:PUSHER_BUNDLE] ?: _defaultImage;
		[_table reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
		[self saveCustomServices];
	};
	[alert addAction:XalertBtnWHandler(@"Add", handler)];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)saveCustomServices {
	setPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey, (__bridge CFPropertyListRef) _customServices, YES);
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[table deselectRowAtIndexPath:indexPath animated:YES];
	NSString *currService = _data[_sections[indexPath.section]][indexPath.row];
	BOOL isCustomService = [_customServices.allKeys containsObject:currService];
	if (table.editing) {
		if (isCustomService) {
			// Rename
			[self renameService:currService];
		}
	} else {
		NSPServiceController *controller;
		if ([_loadedServiceControllers.allKeys containsObject:currService]) {
			controller = _loadedServiceControllers[currService];
		} else {
			controller = [[NSPServiceController alloc] initWithService:currService image:_serviceImages[currService] isCustom:isCustomService];
			_loadedServiceControllers[currService] = controller;
		}
		[self pushController:controller];
	}
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
	NSString *service = _data[_sections[indexPath.section]][indexPath.row];
	cell.textLabel.text = service;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.imageView.image = _serviceImages[service];
	return cell;
}

- (BOOL)tableView:(UITableView *)table canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)table moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	_lastTargetService = nil;
	_lastTargetIndexPath = nil;
	NSString *service = _data[_sections[sourceIndexPath.section]][sourceIndexPath.row];
	[_data[_sections[sourceIndexPath.section]] removeObjectAtIndex:sourceIndexPath.row];
	[_data[_sections[destinationIndexPath.section]] insertObject:service atIndex:destinationIndexPath.row];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *service = _data[_sections[indexPath.section]][indexPath.row];
	if ([_customServices.allKeys containsObject:service]) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)table commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *service = _data[_sections[indexPath.section]][indexPath.row];
	if (editingStyle == UITableViewCellEditingStyleDelete && [_customServices.allKeys containsObject:service]) {
		[_customServices removeObjectForKey:service];
		[_data[_sections[indexPath.section]] removeObjectAtIndex:indexPath.row];
		[self saveCustomServices];

		[table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (sourceIndexPath.section == proposedDestinationIndexPath.section) {
		return sourceIndexPath;
	}
	NSString *service = _data[_sections[sourceIndexPath.section]][sourceIndexPath.row];
	if (_lastTargetService && Xeq(service, _lastTargetService)) {
		return _lastTargetIndexPath;
	}
	_lastTargetService = service;
	NSArray *tempArray = [[_data[_sections[proposedDestinationIndexPath.section]] arrayByAddingObject:service] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	_lastTargetIndexPath = [NSIndexPath indexPathForRow:[tempArray indexOfObject:service] inSection:proposedDestinationIndexPath.section];
	return _lastTargetIndexPath;
}

- (void)renameService:(NSString *)currService {

	UIAlertController *alert = XalertWTitle(Xstr(@"Rename %@", currService), nil);
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.placeholder = @"Service Name";
		textField.text = currService;
	}];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	id handler = ^(UIAlertAction *action) {
		UITextField *textField = alert.textFields[0];
		if (!textField || !textField.text) {
			return;
		}
		NSString *newServiceName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (newServiceName.length < 1 || Xeq(newServiceName, currService)) {
			return;
		}
		if ([_customServices.allKeys containsObject:newServiceName] || [_services containsObject:newServiceName]) {
			id existsHandler = ^(UIAlertAction *existsAction) {
				[self renameService:currService];
			};
			UIAlertController *existsAlert = XalertWTitle(Xstr(@"Rename %@", currService), @"A service with that name already exists.");
			[existsAlert addAction:XalertBtnWHandler(@"Ok", existsHandler)];
			[self presentViewController:existsAlert animated:YES completion:nil];
			return;
		}

		_serviceImages[newServiceName] = _serviceImages[currService];
		[_serviceImages removeObjectForKey:currService];

		_customServices[newServiceName] = [_customServices[currService] mutableCopy];
		[_customServices removeObjectForKey:currService];
		[self saveCustomServices];

		// Get preferences
		CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		NSMutableDictionary *newPrefs = [NSMutableDictionary new];
		if (keyList) {
			newPrefs = [(NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
			if (!newPrefs) { newPrefs = [NSMutableDictionary new]; }
			CFRelease(keyList);
		}

		NSDictionary *keysToMigrate = @{
			NSPPreferenceCustomServiceCustomAppsKey(currService): NSPPreferenceCustomServiceCustomAppsKey(newServiceName)
		};

		NSDictionary *prefixesToMigrate = @{
			NSPPreferenceCustomServiceBLPrefix(currService): NSPPreferenceCustomServiceBLPrefix(newServiceName)
		};

		NSMutableArray *keysToRemove = [NSMutableArray arrayWithArray:keysToMigrate.allKeys];

		for (NSString *oldKey in keysToMigrate.allKeys) {
			NSString *newKey = keysToMigrate[oldKey];
			newPrefs[newKey] = [newPrefs[oldKey] copy];
			[newPrefs removeObjectForKey:oldKey];
		}

		for (NSString *oldPrefix in prefixesToMigrate.allKeys) {
			NSString *newPrefix = prefixesToMigrate[oldPrefix];
			NSMutableArray *foundPrefixKeys = [NSMutableArray new];
			for (id key in newPrefs.allKeys) {
				if (![key isKindOfClass:NSString.class]) { continue; }
				if ([key hasPrefix:oldPrefix]) {
					[foundPrefixKeys addObject:key];
				}
			}
			for (NSString *oldKey in foundPrefixKeys) {
				NSString *newKey = [oldKey stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
				newPrefs[newKey] = [newPrefs[oldKey] copy];
				[newPrefs removeObjectForKey:oldKey];
				[keysToRemove addObject:oldKey];
			}
		}

		CFPreferencesSetMultiple((__bridge CFDictionaryRef)newPrefs, (__bridge CFArrayRef)keysToRemove, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		notify_post(PUSHER_PREFS_NOTIFICATION);

		NSString *currSection = ((NSNumber *) _customServices[newServiceName][@"Enabled"]).boolValue ? @"Enabled" : @"Disabled";
		[_data[currSection] removeObject:currService];
		[_data[currSection] addObject:newServiceName];
		[_data[currSection] sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

		[_table reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationFade];
	};
	[alert addAction:XalertBtnWHandler(@"Rename", handler)];
	[self presentViewController:alert animated:YES completion:nil];

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self.view endEditing:YES];
}

@end
