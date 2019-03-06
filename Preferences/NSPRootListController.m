#include "NSPRootListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPRootListController

- (id)init {
	id ret = [super init];

	// Get preferences
	CFArrayRef keyList = CFPreferencesCopyKeyList(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	_prefs = @{};
	if (keyList) {
		_prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!_prefs) { _prefs = @{}; }
		CFRelease(keyList);
	}
	id val = _prefs[@"pushoverDevices"];
	NSDictionary *pushoverDevices = val ? val : @{};
	_pushoverHasDevices = pushoverDevices.count > 0;

	return ret;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
		NSMutableArray *allSpecifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
		// If has devices, add link to devices list specifier
		if (_pushoverHasDevices) {
			[allSpecifiers addObject:[self generateDeviceLinkSpecifier]];
		}
		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

- (PSSpecifier *)generateDeviceLinkSpecifier {
	return [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:self set:NULL get:NULL detail:NSClassFromString(@"NSPDeviceListController") cell:PSLinkCell edit:nil];
}

- (PSSpecifier *)addDeviceLinkSpecifier {
	PSSpecifier *devicesLinkSpecifier = [self generateDeviceLinkSpecifier];
	[self insertSpecifier:devicesLinkSpecifier afterSpecifierID:@"validateAndLoadDeviceList" animated:YES];
	return devicesLinkSpecifier;
}

- (void)openPushoverAppBuild {
	Xurl(@"https://pushover.net/apps/build");
}

- (void)openPushoverDashboard {
	Xurl(@"https://pushover.net/dashboard");
}

- (void)validateAndLoadDeviceList {
	// end editing to save token in place
	[self.table endEditing:YES];

	CFArrayRef keyList = CFPreferencesCopyKeyList(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = nil;
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	id val = [prefs[@"pushoverToken"] copy];
	NSString *pushoverToken = val ? val : @"";
	val = [prefs[@"pushoverUser"] copy];
	NSString *pushoverUser = val ? val : @"";
	val = [prefs[@"pushoverDevices"] copy];
	__block NSDictionary *currPushoverDevices = val ? val : @{};
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
				return;
			}

			NSArray *pushoverDevices = (NSArray *)json[@"devices"];
			NSMutableDictionary *pushoverDevicesDict = [NSMutableDictionary new];
			for (NSString *device in pushoverDevices) {
				pushoverDevicesDict[device] = currPushoverDevices[device] ? currPushoverDevices[device] : @NO;
			}

			CFStringRef pushoverDevicesKey = CFSTR("pushoverDevices");
			CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSetValue(pushoverDevicesKey, (__bridge CFPropertyListRef)pushoverDevicesDict, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFRelease(pushoverDevicesKey);
			// Reload stuff
			notify_post("com.noahsaso.pusher/prefs");

			XLog(@"Saved devices");

			// Show alert to open receiving devices
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				__block PSSpecifier *spec = [self specifierForID:@"Receiving Devices"];
				if (!_pushoverHasDevices || !spec) {
					spec = [self addDeviceLinkSpecifier];
					_pushoverHasDevices = YES;
				}
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:kName message:@"Receiving devices loaded." preferredStyle:UIAlertControllerStyleAlert];
				[alert addAction:[UIAlertAction actionWithTitle:@"Show" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
					[self tableView:self.table didSelectRowAtIndexPath:[self indexPathForSpecifier:spec]];
				}]];
				[self presentViewController:alert animated:true completion:nil];
			});

		} else if (data.length && error == nil) {
			XLog(@"No data");
		} else if (error != nil) {
			XLog(@"Error: %@", error);
		} else {
			XLog(@"idk what happened");
		}
	}] resume];
}

@end
