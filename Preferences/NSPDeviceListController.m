#import "NSPDeviceListController.h"

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

@implementation NSPDeviceListController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Create buttons
	_updateBn = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(updateDevices)];
	_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_activityIndicatorBn = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];

	_prefsKey = [[self.specifier propertyForKey:@"prefsKey"] retain];
	_service = [[self.specifier propertyForKey:@"service"] retain];
	_isCustomApp = ((NSNumber *) [self.specifier propertyForKey:@"isCustomApp"]).boolValue;
	if (_isCustomApp) {
		_customAppIDKey = [[self.specifier propertyForKey:@"customAppIDKey"] retain];
	}

	_onlyAllowOne = Xeq(_service, PUSHER_SERVICE_PUSHBULLET);
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
	_prefs = @{};
	if (keyList) {
		_prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!_prefs) { _prefs = @{}; }
		CFRelease(keyList);
	}

	NSDictionary *val = _prefs[_prefsKey] ?: (_isCustomApp ? @{} : @[]);
	if (_isCustomApp) {
		val = val[_customAppIDKey] ?: @{};
		val = val[@"devices"] ?: @[];
	}
	_serviceDevices = [val mutableCopy];
	NSMutableDictionary *indexesToReplace = [NSMutableDictionary new];
	for (int i = 0; i < _serviceDevices.count; i++) {
		indexesToReplace[@(i)] = [_serviceDevices[i] mutableCopy];
	}
	for (NSNumber *index in indexesToReplace.allKeys) {
		[_serviceDevices replaceObjectAtIndex:index.intValue withObject:indexesToReplace[index]];
	}

	[self reloadSpecifiers];

	// Update in background
	[self updateDevices];
}

- (void)showActivityIndicator {
	self.navigationItem.rightBarButtonItem = _activityIndicatorBn;
	[_activityIndicator startAnimating];
}

- (void)hideActivityIndicator {
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[_activityIndicator stopAnimating];
		self.navigationItem.rightBarButtonItem = _updateBn;
	});
}

- (void)saveServiceDevices {
	if (_isCustomApp) {
		NSMutableDictionary *customApps = [(_prefs[_prefsKey] ?: @{}) mutableCopy];
		NSMutableDictionary *customApp = [(customApps[_customAppIDKey] ?: @{}) mutableCopy];
		customApp[@"devices"] = _serviceDevices;
		customApps[_customAppIDKey] = customApp;
		setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFPropertyListRef) customApps, YES);
	} else {
		setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFArrayRef) _serviceDevices, YES);
	}
}

- (void)updateDevices {
	[self showActivityIndicator];

	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
		[self updatePushoverDevices];
	} else if (Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
		[self updatePushbulletDevices];
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		if (_serviceDevices.count) {
			PSSpecifier *groupSpecifier = [PSSpecifier emptyGroupSpecifier];
			if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
				[groupSpecifier setProperty:@"Selecting none will forward push notifications to all devices." forKey:@"footerText"];
			} else if (Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
				[groupSpecifier setProperty:@"Pushbullet only allows one receiving device. Selecting none will forward push notifications to all devices." forKey:@"footerText"];
			}
			[allSpecifiers addObject:groupSpecifier];
		}

		for (NSDictionary *device in [self sortedDeviceList:_serviceDevices]) {
			PSSpecifier *switchSpecifier = [PSSpecifier preferenceSpecifierNamed:device[@"name"] target:self set:@selector(setPreferenceValue:forDeviceSpecifier:) get:@selector(readDevicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
			switchSpecifier.identifier = device[@"id"];
			[switchSpecifier setProperty:@"com.noahsaso.pusher/prefs" forKey:@"PostNotification"];
			[switchSpecifier setProperty:@YES forKey:@"enabled"];
			[switchSpecifier setProperty:@"com.noahsaso.pusher" forKey:@"defaults"];
			[switchSpecifier setProperty:@NO forKey:@"default"];
			[allSpecifiers addObject:switchSpecifier];
		}

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

- (NSArray *)sortedDeviceList:(NSArray *)devices {
	return [devices sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *device1, NSDictionary *device2) {
    return [device1[@"name"] localizedCaseInsensitiveCompare:device2[@"name"]];
	}];
}

- (void)setPreferenceValue:(id)value forDeviceSpecifier:(PSSpecifier *)specifier {
	for (NSMutableDictionary *device in _serviceDevices) {
		if (Xeq(device[@"id"], specifier.identifier)) {
			device[@"enabled"] = value;
		} else if (_onlyAllowOne) {
			// all others must be off
			device[@"enabled"] = @NO;
		}
	}
	// reload specifiers because likely turned other switch off
	if (_onlyAllowOne) {
		[self reloadSpecifiers];
	}
	[self saveServiceDevices];
}

- (id)readDevicePreferenceValue:(PSSpecifier *)specifier {
	for (NSDictionary *device in _serviceDevices) {
		if (Xeq(device[@"id"], specifier.identifier)) {
			return device[@"enabled"];
		}
	}
	return @NO;
}

- (void)updatePushoverDevices {
	id val = _prefs[NSPPreferencePushoverTokenKey];
	NSString *pushoverToken = val ?: @"";
	val = _prefs[NSPPreferencePushoverUserKey];
	NSString *pushoverUser = val ?: @"";
	NSDictionary *userDictionary = @{
		@"token": pushoverToken,
		@"user": pushoverUser
	};
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userDictionary options:NSJSONWritingPrettyPrinted error:nil];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.pushover.net/1/users/validate.json"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:Xstr(@"%lu", jsonData.length) forHTTPHeaderField:@"Content-length"];
	[request setHTTPBody:jsonData];

	//use async way to connect network
	[[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response, NSError *error) {
		if (data.length && error == nil) {
			XLog(@"Success");
			NSError *jsonError = nil;
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
			if (jsonError) {
				XLog(@"JSON Error: %@", jsonError);
			}
			// 0 error, 1 success
			int status = ((NSNumber *) json[@"status"]).intValue;
			if (status == 0) {
				XLog(@"Something went wrong");
				NSArray *errors = (NSArray *) json[@"errors"];
				NSString *title;
				NSString *msg = @"";
				if (errors == nil || errors.count == 0) {
					title = @"Unknown Error";
					msg = Xstr(@"Server response: %@", json);
				} else {
					title = @"Server Error";
					msg = Xstr(@"%@", [errors componentsJoinedByString:@"\n"]);
				}
				UIAlertController *alert = XalertWTitle(title, msg);
				id handler = ^(UIAlertAction *action) {
					[self.navigationController popViewControllerAnimated:YES];
				};
				[alert addAction:XalertBtnWHandler(@"Ok", handler)];
				dispatch_async(dispatch_get_main_queue(), ^(void) {
					[self presentViewController:alert animated:YES completion:nil];
				});
				[self hideActivityIndicator];
				return;
			}

			NSMutableArray *serviceDevices = [(NSArray *)json[@"devices"] mutableCopy];
			NSMutableArray *serviceDevicesToRemove = [NSMutableArray new];
			for (NSDictionary *device in _serviceDevices) {
				if (![serviceDevices containsObject:device[@"id"]]) {
					[serviceDevicesToRemove addObject:device];
				} else {
					[serviceDevices removeObject:device[@"id"]];
				}
			}
			for (NSString *device in serviceDevices) {
				[_serviceDevices addObject:[@{ @"name": device, @"id": device, @"enabled": @NO } mutableCopy]];
			}
			for (NSDictionary *device in serviceDevicesToRemove) {
				[_serviceDevices removeObject:device];
			}
			[serviceDevicesToRemove release];

			[self saveServiceDevices];

			XLog(@"Saved devices");

			// Reload specifiers on current screen
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self reloadSpecifiers];
			});

		} else {
			id handler = ^(UIAlertAction *action) {
				[self.navigationController popViewControllerAnimated:YES];
			};
			NSString *msg;
			if (data.length == 0 && error == nil) {
				msg = @"Server did not respond. Please check your internet connection or try again later.";
			} else if (error) {
				msg = error.localizedDescription;
			} else {
				msg = @"Unknown Error. Contact Developer.";
			}
			UIAlertController *alert = XalertWTitle(@"Network Error", msg);
			[alert addAction:XalertBtnWHandler(@"Ok", handler)];
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self presentViewController:alert animated:YES completion:nil];
			});
		}

		[self hideActivityIndicator];
	}] resume];
}

- (void)updatePushbulletDevices {
	NSString *pushbulletToken = _prefs[NSPPreferencePushbulletTokenKey] ?: @"";
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.pushbullet.com/v2/devices"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[request setValue:pushbulletToken forHTTPHeaderField:@"Access-Token"];

	//use async way to connect network
	[[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response, NSError *error) {
		if (data.length && error == nil) {
			XLog(@"Success");
			NSError *jsonError = nil;
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
			if (jsonError) {
				XLog(@"JSON Error: %@", jsonError);
			}

			NSDictionary *error = (NSDictionary *) json[@"error"];
			if (error) {
				XLog(@"Something went wrong");
				NSString *title = @"Server Error";
				NSString *msg = error[@"message"] ?: @"Unknown Error";
				UIAlertController *alert = XalertWTitle(title, msg);
				id handler = ^(UIAlertAction *action) {
					[self.navigationController popViewControllerAnimated:YES];
				};
				[alert addAction:XalertBtnWHandler(@"Ok", handler)];
				dispatch_async(dispatch_get_main_queue(), ^(void) {
					[self presentViewController:alert animated:YES completion:nil];
				});
				[self hideActivityIndicator];
				return;
			}

			NSMutableArray *serviceDevices = [(NSArray *)json[@"devices"] mutableCopy];

			NSMutableArray *serviceDevicesToRemove = [NSMutableArray new];
			for (NSDictionary *savedDevice in _serviceDevices) {
				NSDictionary *foundNewDevice = nil;
				for (NSDictionary *newDevice in serviceDevices) {
					if (Xeq(savedDevice[@"id"], newDevice[@"iden"])) {
						foundNewDevice = newDevice;
						break;
					}
				}
				if (foundNewDevice) {
					// prevent from adding later because already exists
					[serviceDevices removeObject:foundNewDevice];
				} else {
					[serviceDevicesToRemove addObject:savedDevice];
				}
			}

			for (NSDictionary *newDevice in serviceDevices) {
				// pushable deprecated
				if ((newDevice[@"active"] && !((NSNumber *) newDevice[@"active"]).boolValue)) {
					continue;
				}
				NSString *name = newDevice[@"nickname"] ?: newDevice[@"model"];
				[_serviceDevices addObject:[@{ @"name": name, @"id": newDevice[@"iden"], @"enabled": @NO } mutableCopy]];
			}
			for (NSDictionary *savedDevice in serviceDevicesToRemove) {
				[_serviceDevices removeObject:savedDevice];
			}
			[serviceDevicesToRemove release];

			[self saveServiceDevices];

			XLog(@"Saved devices");

			// Reload specifiers on current screen
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self reloadSpecifiers];
			});

		} else {
			id handler = ^(UIAlertAction *action) {
				[self.navigationController popViewControllerAnimated:YES];
			};
			NSString *msg;
			if (data.length == 0 && error == nil) {
				msg = @"Server did not respond. Please check your internet connection or try again later.";
			} else if (error) {
				msg = error.localizedDescription;
			} else {
				msg = @"Unknown Error. Contact Developer.";
			}
			UIAlertController *alert = XalertWTitle(@"Network Error", msg);
			[alert addAction:XalertBtnWHandler(@"Ok", handler)];
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self presentViewController:alert animated:YES completion:nil];
			});
		}

		[self hideActivityIndicator];
	}] resume];
}

@end
