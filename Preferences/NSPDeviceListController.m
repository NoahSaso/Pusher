#import "NSPDeviceListController.h"

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

@implementation NSPDeviceListController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// End editing of previous view controller so updates prefs if editing text field
	if (self.navigationController.viewControllers && self.navigationController.viewControllers.count > 1) {
		UIViewController *viewController = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
		if (viewController) {
			[viewController.view endEditing:YES];
		}
	}

	// Create buttons
	_updateBn = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(updateDevices)];
	_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_activityIndicatorBn = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];

	// Get preferences
	CFArrayRef keyList = CFPreferencesCopyKeyList(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	_prefs = @{};
	if (keyList) {
		_prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!_prefs) { _prefs = @{}; }
		CFRelease(keyList);
	}

	_prefsKey = [[self.specifier propertyForKey:@"prefsKey"] retain];
	_service = [[self.specifier propertyForKey:@"service"] retain];
	_isCustomApp = ((NSNumber *) [self.specifier propertyForKey:@"isCustomApp"]).boolValue;
	if (_isCustomApp) {
		_customAppIDKey = [[self.specifier propertyForKey:@"customAppIDKey"] retain];
	}

	id val = _prefs[_prefsKey];
	NSDictionary *dict = val ?: @{};
	if (_isCustomApp) {
		val = dict[_customAppIDKey] ?: @{};
		val = val[@"devices"] ?: @{};
	}
	_serviceDevices = [(val ?: @{}) mutableCopy];

	// // If no devices, tell them
	// if (_serviceDevices.count == 0) {
	// 	// give error and exit screen
	// 	XLog(@"devices empty");
	// 	[((UIViewController *) ret).navigationController popViewControllerAnimated:YES];u3f633wd6vo7ksmcy1hvgvkswpqkj6
	// 	Xalert(@"There are no devices loaded. Please verify your credentials are .");
	// }

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
		NSMutableDictionary *customApps = [_prefs[_prefsKey] ?: @{} mutableCopy];
		NSMutableDictionary *customApp = [(customApps[_customAppIDKey] ?: @{}) mutableCopy];
		customApp[@"devices"] = _serviceDevices;
		customApps[_customAppIDKey] = customApp;
		setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFPropertyListRef) customApps, YES);
	} else {
		setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFPropertyListRef) _serviceDevices, YES);
	}
}

- (void)updateDevices {
	[self showActivityIndicator];

	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
		[self updatePushoverDevices];
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		if (_serviceDevices.count) {
			PSSpecifier *groupSpecifier = [PSSpecifier emptyGroupSpecifier];
			[groupSpecifier setProperty:@"Selecting none will forward push notifications to all devices." forKey:@"footerText"];
			[allSpecifiers addObject:groupSpecifier];
		}

		for (NSString *device in [_serviceDevices.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
			PSSpecifier *switchSpecifier = [PSSpecifier preferenceSpecifierNamed:device target:self set:@selector(setPreferenceValue:forDeviceSpecifier:) get:@selector(readDevicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
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

- (void)setPreferenceValue:(id)value forDeviceSpecifier:(PSSpecifier *)specifier {
	_serviceDevices[specifier.identifier] = value;
	[self saveServiceDevices];
}

- (id)readDevicePreferenceValue:(PSSpecifier *)specifier {
	return _serviceDevices[specifier.identifier];
}

- (void)updatePushoverDevices {
	id val = [_prefs[NSPPreferencePushoverTokenKey] copy];
	NSString *pushoverToken = val ?: @"";
	val = [_prefs[NSPPreferencePushoverUserKey] copy];
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

			NSArray *serviceDevices = (NSArray *)json[@"devices"];
			for (NSString *device in serviceDevices) {
				_serviceDevices[device] = _serviceDevices[device] ?: @NO;
			}
			for (NSString *device in _serviceDevices.allKeys) {
				if (![serviceDevices containsObject:device]) {
					[_serviceDevices removeObjectForKey:device];
				}
			}

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
