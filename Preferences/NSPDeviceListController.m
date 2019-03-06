#include "NSPDeviceListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

static void setPreference(CFStringRef keyRef, CFPropertyListRef val, BOOL shouldNotify) {
	CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSetValue(keyRef, val, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFRelease(keyRef);
  if (shouldNotify) {
    // Reload stuff
    notify_post("com.noahsaso.pusher/prefs");
  }
}

@implementation NSPDeviceListController

- (id)init {
	id ret = [super init];

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
	id val = _prefs[@"pushoverDevices"];
	_pushoverDevices = [(val ? val : @{}) mutableCopy];

	// If no devices, tell them
	if (_pushoverDevices.count == 0) {
		// give error and exit screen
		XLog(@"devices empty");
		[((UIViewController *) ret).navigationController popViewControllerAnimated:YES];
		Xalert(@"There are no devices loaded. Please validate and load the receiving devices.");
	}

	return ret;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// Add reload button
	self.navigationItem.rightBarButtonItem = _updateBn;
}

- (void)showActivityIndicator {
	self.navigationItem.rightBarButtonItem = _activityIndicatorBn;
	[_activityIndicator startAnimating];
}

- (void)hideActivityIndicator {
	[_activityIndicator stopAnimating];
	self.navigationItem.rightBarButtonItem = _updateBn;
}

- (void)updateDevices {
	[self showActivityIndicator];

	id val = [_prefs[@"pushoverToken"] copy];
	NSString *pushoverToken = val ? val : @"";
	val = [_prefs[@"pushoverUser"] copy];
	NSString *pushoverUser = val ? val : @"";
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
				for (id key in json.allKeys) {
					XLog(@"%@: %@", key, json[key]);
				}
				[self hideActivityIndicator];
				return;
			}

			NSArray *pushoverDevices = (NSArray *)json[@"devices"];
			for (NSString *device in pushoverDevices) {
				_pushoverDevices[device] = _pushoverDevices[device] ? _pushoverDevices[device] : @NO;
			}
			for (NSString *device in _pushoverDevices.allKeys) {
				if (![pushoverDevices containsObject:device]) {
					[_pushoverDevices removeObjectForKey:device];
				}
			}

			setPreference(CFSTR("pushoverDevices"), (__bridge CFPropertyListRef)_pushoverDevices, YES);

			XLog(@"Saved devices");

			// Reload specifiers on current screen
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self reloadSpecifiers];
			});

		} else if (data.length && error == nil) {
			XLog(@"No data");
		} else if (error != nil) {
			XLog(@"Error: %@", error);
		} else {
			XLog(@"idk what happened");
		}

		[self hideActivityIndicator];
	}] resume];
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *allSpecifiers = [NSMutableArray new];

		if (_pushoverDevices.count) {
			PSSpecifier *groupSpecifier = [PSSpecifier emptyGroupSpecifier];
			[groupSpecifier setProperty:@"Selecting none will forward push notifications to all devices." forKey:@"footerText"];
			[allSpecifiers addObject:groupSpecifier];
		}

		for (NSString *device in [_pushoverDevices.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
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
	_pushoverDevices[specifier.identifier] = value;
	NSMutableArray *enabledDevices = [NSMutableArray new];
	for (NSString *device in _pushoverDevices.allKeys) {
		if (((NSNumber *) _pushoverDevices[device]).boolValue) {
			[enabledDevices addObject:device];
		}
	}
	setPreference(CFSTR("pushoverDevices"), (__bridge CFPropertyListRef)_pushoverDevices, NO);
}

- (id)readDevicePreferenceValue:(PSSpecifier *)specifier {
	return _pushoverDevices[specifier.identifier];
}

@end
