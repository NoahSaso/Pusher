#import "NSPSoundListController.h"

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

@implementation NSPSoundListController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Create buttons
	_updateBn = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(updateSounds)];
	_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_activityIndicatorBn = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];

	_prefsKey = [[self.specifier propertyForKey:@"prefsKey"] retain];
	_service = [[self.specifier propertyForKey:@"service"] retain];
	_isCustomApp = ((NSNumber *) [self.specifier propertyForKey:@"isCustomApp"]).boolValue;
	if (_isCustomApp) {
		_customAppIDKey = [[self.specifier propertyForKey:@"customAppIDKey"] retain];
	}
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
		val = val[@"sounds"] ?: @[];
	}
	_serviceSounds = [val mutableCopy];
	NSMutableDictionary *indexesToReplace = [NSMutableDictionary new];
	for (int i = 0; i < _serviceSounds.count; i++) {
		indexesToReplace[[NSNumber numberWithInt:i]] = [_serviceSounds[i] mutableCopy];
	}
	for (NSNumber *index in indexesToReplace.allKeys) {
		[_serviceSounds replaceObjectAtIndex:index.intValue withObject:indexesToReplace[index]];
	}

	[self reloadSpecifiers];

	// Update in background
	[self updateSounds];
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

- (void)saveServiceSounds {
	if (_isCustomApp) {
		NSMutableDictionary *customApps = [(_prefs[_prefsKey] ?: @{}) mutableCopy];
		NSMutableDictionary *customApp = [(customApps[_customAppIDKey] ?: @{}) mutableCopy];
		customApp[@"sounds"] = _serviceSounds;
		customApps[_customAppIDKey] = customApp;
		setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFPropertyListRef) customApps, YES);
	} else {
		setPreference((__bridge CFStringRef) _prefsKey, (__bridge CFArrayRef) _serviceSounds, YES);
	}
}

- (void)updateSounds {
	[self showActivityIndicator];

	if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
		[self updatePushoverSounds];
	} else if (Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
		[self updatePushbulletSounds];
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		if (_serviceSounds.count) {
			PSSpecifier *groupSpecifier = [PSSpecifier emptyGroupSpecifier];
			// if (Xeq(_service, PUSHER_SERVICE_PUSHOVER)) {
			// 	[groupSpecifier setProperty:@"Selecting none will forward push notifications to all sounds." forKey:@"footerText"];
			// } else if (Xeq(_service, PUSHER_SERVICE_PUSHBULLET)) {
			// 	[groupSpecifier setProperty:@"Pushbullet only allows one receiving sound. Selecting none will forward push notifications to all sounds." forKey:@"footerText"];
			// }
			[allSpecifiers addObject:groupSpecifier];
		}

		for (NSDictionary *sound in [self sortedSoundList:_serviceSounds]) {
			PSSpecifier *switchSpecifier = [PSSpecifier preferenceSpecifierNamed:sound[@"name"] target:self set:@selector(setPreferenceValue:forSoundSpecifier:) get:@selector(readSoundPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
			switchSpecifier.identifier = sound[@"id"];
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

- (NSArray *)sortedSoundList:(NSArray *)sounds {
	return [sounds sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *sound1, NSDictionary *sound2) {
    return [sound1[@"name"] localizedCaseInsensitiveCompare:sound2[@"name"]];
	}];
}

- (void)setPreferenceValue:(id)value forSoundSpecifier:(PSSpecifier *)specifier {
	for (NSMutableDictionary *sound in _serviceSounds) {
		if (Xeq(sound[@"id"], specifier.identifier)) {
			sound[@"enabled"] = value;
		} else {
			// all others must be off
			sound[@"enabled"] = @NO;
		}
	}
	[self reloadSpecifiers];
	[self saveServiceSounds];
}

- (id)readSoundPreferenceValue:(PSSpecifier *)specifier {
	for (NSDictionary *sound in _serviceSounds) {
		if (Xeq(sound[@"id"], specifier.identifier)) {
			return sound[@"enabled"];
		}
	}
	return @NO;
}

- (void)updatePushoverSounds {
	NSString *pushoverToken = _prefs[NSPPreferencePushoverTokenKey] ?: @"";
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:Xstr(@"https://api.pushover.net/1/sounds.json?token=%@", pushoverToken)] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

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

			NSMutableDictionary *serviceSounds = [(NSDictionary *)json[@"sounds"] mutableCopy];

			NSMutableArray *serviceSoundsToRemove = [NSMutableArray new];
			for (NSDictionary *sound in _serviceSounds) {
				if (![serviceSounds.allKeys containsObject:sound[@"id"]]) {
					[serviceSoundsToRemove addObject:sound];
				} else {
					[serviceSounds removeObjectForKey:sound[@"id"]];
				}
			}
			for (NSString *soundID in serviceSounds.allKeys) {
				[_serviceSounds addObject:[@{ @"name": serviceSounds[soundID], @"id": soundID, @"enabled": @NO } mutableCopy]];
			}
			for (NSDictionary *sound in serviceSoundsToRemove) {
				[_serviceSounds removeObject:sound];
			}
			[serviceSoundsToRemove release];

			[self saveServiceSounds];

			XLog(@"Saved sounds");

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

- (void)updatePushbulletSounds {
	NSString *pushbulletToken = _prefs[NSPPreferencePushbulletTokenKey] ?: @"";
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.pushbullet.com/v2/sounds"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
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

			NSMutableArray *serviceSounds = [(NSArray *)json[@"sounds"] mutableCopy];

			NSMutableArray *serviceSoundsToRemove = [NSMutableArray new];
			for (NSDictionary *savedSound in _serviceSounds) {
				NSDictionary *foundNewSound = nil;
				for (NSDictionary *newSound in serviceSounds) {
					if (Xeq(savedSound[@"id"], newSound[@"iden"])) {
						foundNewSound = newSound;
						break;
					}
				}
				if (foundNewSound) {
					// prevent from adding later because already exists
					[serviceSounds removeObject:foundNewSound];
				} else {
					[serviceSoundsToRemove addObject:savedSound];
				}
			}

			for (NSDictionary *newSound in serviceSounds) {
				// pushable deprecated
				if ((newSound[@"active"] && !((NSNumber *) newSound[@"active"]).boolValue)) {
					continue;
				}
				NSString *name = newSound[@"nickname"] ?: newSound[@"model"];
				[_serviceSounds addObject:[@{ @"name": name, @"id": newSound[@"iden"], @"enabled": @NO } mutableCopy]];
			}
			for (NSDictionary *savedSound in serviceSoundsToRemove) {
				[_serviceSounds removeObject:savedSound];
			}
			[serviceSoundsToRemove release];

			[self saveServiceSounds];

			XLog(@"Saved sounds");

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
