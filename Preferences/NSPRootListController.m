#include "NSPRootListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)openPushoverAppBuild {
	Xurl(@"https://pushover.net/apps/build");
}

- (void)openPushoverDashboard {
	Xurl(@"https://pushover.net/dashboard");
}

- (void)validateAndChooseDevices {
	// end editing to save token in place
	[self.table endEditing:YES];
	NSDictionary *pusherPrefs = [NSDictionary dictionaryWithContentsOfFile:PUSHER_PREFS_FILE];
	id val = [pusherPrefs[@"pushoverToken"] copy];
	NSString *pusherToken = val ? val : @"";
	val = [pusherPrefs[@"pushoverUser"] copy];
	NSString *pusherUser = val ? val : @"";
	NSDictionary *userDictionary = @{
		@"token": pusherToken,
		@"user": pusherUser
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
		if ([data length] > 0 && error == nil) {
			XLog(@"Success");
			NSError *jsonError = nil;
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
			if (jsonError) {
				XLog(@"JSON Error: %@", jsonError);
			}
			// 0 error, 1 success
			int status = ((NSNumber *) [json objectForKey:@"status"]).intValue;
			if (status == 0) {
				XLog(@"Something went wrong");
				for (id key in json.allKeys) {
					XLog(@"%@: %@", key, [json objectForKey:key]);
				}
				return;
			}
			NSArray *pushoverDevices = (NSArray *)[json objectForKey:@"devices"];
			NSString *pushoverDevice = [pushoverDevices componentsJoinedByString:@","];

			CFStringRef pushoverDeviceKey = CFSTR("pushoverDevice");
			CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSetValue(pushoverDeviceKey, (__bridge CFStringRef)pushoverDevice, pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize(pusherAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFRelease(pushoverDeviceKey);

			dispatch_async(dispatch_get_main_queue(), ^(void){
				[self reloadSpecifierID:@"pushoverDevice"];
			});
			// Reload stuff
			notify_post("com.noahsaso.pusher/prefs");
		} else if ([data length] == 0 && error == nil) {
			XLog(@"No data");
		} else if (error != nil) {
			XLog(@"Error: %@", error);
		} else {
			XLog(@"idk what happened");
		}
	}] resume];
}

@end
