#import "global.h"
#import <Custom/defines.h>

#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

@interface BBBulletin (Pusher)
@property (nonatomic, readonly) BOOL showsSubtitle;
- (void)sendBulletinToPusher:(BBBulletin *)bulletin;
@end

static BOOL pusherEnabled = NO;
static NSArray *globalBlacklist = nil;
static NSMutableDictionary *pusherServices = nil;

static NSArray *getPusherBlacklist(NSDictionary *prefs, NSString *prefix) {
	// Extract all blacklisted app IDs
	NSMutableArray *blacklist = [NSMutableArray new];
	for (id key in prefs.allKeys) {
		if (![key isKindOfClass:NSString.class]) { continue; }
		if ([key hasPrefix:prefix]) {
			if (((NSNumber *) prefs[key]).boolValue) {
				[blacklist addObject:[key substringFromIndex:prefix.length].lowercaseString];
			}
		}
	}
	NSArray *ret = [blacklist copy];
	[blacklist release];
	return ret;
}

static void pusherPrefsChanged() {
	XLog(@"Reloading prefs");

	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	id val = prefs[@"enabled"];
	pusherEnabled = val ? ((NSNumber *) val).boolValue : YES;
	globalBlacklist = getPusherBlacklist(prefs, NSPPreferenceGlobalBLPrefix);

	for (NSString *service in PUSHER_SERVICES) {
		NSMutableDictionary *servicePrefs = [NSMutableDictionary new];

		NSString *tokenKey = Xstr(@"%@Token", service);
		NSString *userKey = Xstr(@"%@User", service);
		NSString *devicesKey = Xstr(@"%@Devices", service);
		NSString *blacklistPrefix = Xstr(@"%@BL-", service);
		NSString *customAppsKey = Xstr(@"%@CustomApps", service);

		servicePrefs[@"blacklist"] = getPusherBlacklist(prefs, blacklistPrefix);
		val = [prefs[tokenKey] copy];
		servicePrefs[@"token"] = val ?: @"";
		val = [prefs[userKey] copy];
		servicePrefs[@"user"] = val ?: @"";

		val = [prefs[devicesKey] copy];
		NSDictionary *devices = val ?: @{};
		NSMutableArray *enabledDevices = [NSMutableArray new];
		for (NSString *device in devices.allKeys) {
			if (((NSNumber *) devices[device]).boolValue) {
				[enabledDevices addObject:device];
			}
		}
		servicePrefs[@"devices"] = [[enabledDevices componentsJoinedByString:@","] copy];

		pusherServices[service] = [servicePrefs copy];
	}

	XLog(@"Reloaded");
}

static BOOL prefsSayNo() {
	return !pusherEnabled
					|| globalBlacklist == nil || ![globalBlacklist isKindOfClass:NSArray.class]
					|| pushoverBlacklist == nil || ![pushoverBlacklist isKindOfClass:NSArray.class]
					|| pushoverToken == nil || ![pushoverToken isKindOfClass:NSString.class] || pushoverToken.length == 0
					|| pushoverUser == nil || ![pushoverUser isKindOfClass:NSString.class] || pushoverUser.length == 0
					|| pushoverDevice == nil || ![pushoverDevice isKindOfClass:NSString.class];
}

%hook BBServer

%new
- (void)sendBulletinToPusher:(BBBulletin *)bulletin {
	if (prefsSayNo() || bulletin == nil) {
		XLog(@"Prefs said no");
		if (pusherEnabled) {
			XLog(@"globalBlacklist: %@", globalBlacklist);
			XLog(@"pushoverBlacklist: %@", pushoverBlacklist);
			XLog(@"pushoverToken: %@", pushoverToken);
			XLog(@"pushoverUser: %@", pushoverUser);
			XLog(@"pushoverDevice: %@", pushoverDevice);
		}
		return;
	}
	// Check if notification within last 5 seconds so we don't send uncleared notifications every respring
	NSDate *fiveSecondsAgo = [[NSDate date] dateByAddingTimeInterval:-5];
	if (bulletin.date && [bulletin.date compare:fiveSecondsAgo] == NSOrderedAscending) {
		return;
	}
	if ([globalBlacklist containsObject:bulletin.sectionID.lowercaseString]
				|| [pushoverBlacklist containsObject:bulletin.sectionID.lowercaseString]) {
		XLog(@"Blacklisted");
		return;
	}
	SBApplication *app = [[NSClassFromString(@"SBApplicationController") sharedInstance] applicationWithBundleIdentifier:bulletin.sectionID];
	NSString *appName = app && app.displayName && app.displayName.length > 0 ? app.displayName : Xstr(@"Unknown App: %@", bulletin.sectionID);
	NSString *title = Xstr(@"%@%@", appName, (bulletin.title && bulletin.title.length > 0 ? Xstr(@" [%@]", bulletin.title) : @""));
	NSString *message = @"";
	if (bulletin.subtitle && bulletin.subtitle.length > 0) {
		message = bulletin.subtitle;
	}
	message = Xstr(@"%@%@%@", message, (message.length > 0 && bulletin.message && bulletin.message.length > 0 ? @"\n" : @""), bulletin.message ? bulletin.message : @"");
	NSDictionary *userDictionary = @{
		@"token": pushoverToken,
		@"user": pushoverUser,
		@"title": title,
		@"message": message,
		@"device": pushoverDevice
	};
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userDictionary options:NSJSONWritingPrettyPrinted error:nil];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.pushover.net/1/messages.json"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:Xstr(@"%lu", jsonData.length) forHTTPHeaderField:@"Content-length"];
	[request setHTTPBody:jsonData];

	//use async way to connect network
	[[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response, NSError *error) {
		if (data.length && error == nil) {
			XLog(@"Success");
		} else if (data.length && error == nil) {
			XLog(@"No data");
		} else if (error != nil) {
			XLog(@"Error: %@", error);
		} else {
			XLog(@"idk what happened");
		}
	}] resume];
	XLog(@"Pushed %@", appName);
}

// iOS 11?
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(unsigned int)arg2 alwaysToLockScreen:(BOOL)arg3 {
	%orig;
	[self sendBulletinToPusher:bulletin];
}

// iOS 12?
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(unsigned long long)arg2 {
	%orig;
	[self sendBulletinToPusher:bulletin];
}

%end

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)pusherPrefsChanged, PUSHER_PREFS_NOTIFICATION, NULL, CFNotificationSuspensionBehaviorCoalesce);
	pusherPrefsChanged();
	%init;
}
