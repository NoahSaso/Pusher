#import "global.h"
#import <Custom/defines.h>

#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

@interface BBBulletin (Pusher)
@property (nonatomic, readonly) BOOL showsSubtitle;
- (void)sendBulletinToPusher:(BBBulletin *)bulletin;
- (void)makePusherRequest:(NSString *)urlString userData:(NSDictionary *)userData;
@end

static BOOL pusherEnabled = NO;
static NSArray *globalBlacklist = nil;
static NSMutableDictionary *pusherEnabledServices = nil;

// Make all app IDs lowercase in case some library I use starts messing with the case
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

static NSString *getServiceURL(NSString *service) {
	if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
		return PUSHER_SERVICE_PUSHOVER_URL;
	}
	return @"";
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

	if (pusherEnabledServices == nil) {
		pusherEnabledServices = [NSMutableDictionary new];
	}

	for (NSString *service in PUSHER_SERVICES) {
		NSMutableDictionary *servicePrefs = [NSMutableDictionary new];

		NSString *enabledKey = Xstr(@"%@Enabled", service);
		// default is service disabled
		if (prefs[enabledKey] == nil || !((NSNumber *) prefs[enabledKey]).boolValue) {
			// skip if disabled
			[pusherEnabledServices removeObjectForKey:service];
			continue;
		}

		NSString *blacklistPrefix = Xstr(@"%@BL-", service);
		NSString *tokenKey = Xstr(@"%@Token", service);
		NSString *userKey = Xstr(@"%@User", service);
		NSString *devicesKey = Xstr(@"%@Devices", service);
		NSString *customAppsKey = Xstr(@"%@CustomApps", service);

		servicePrefs[@"blacklist"] = getPusherBlacklist(prefs, blacklistPrefix);
		val = prefs[tokenKey];
		servicePrefs[@"token"] = [val copy] ?: @"";
		val = prefs[userKey];
		servicePrefs[@"user"] = [val copy] ?: @"";
		servicePrefs[@"url"] = getServiceURL(service);

		// devices
		val = prefs[devicesKey];
		NSDictionary *devices = val ?: @{};
		NSMutableArray *enabledDevices = [NSMutableArray new];
		for (NSString *device in devices.allKeys) {
			if (((NSNumber *) devices[device]).boolValue) {
				[enabledDevices addObject:device];
			}
		}
		servicePrefs[@"device"] = [[enabledDevices componentsJoinedByString:@","] retain];
		// [enabledDevices release];
		// [devices release];

		// custom apps & devices
		NSDictionary *prefCustomApps = (NSDictionary *)prefs[customAppsKey] ?: @{};
		NSMutableDictionary *customApps = [NSMutableDictionary new];
		for (NSString *customAppID in prefCustomApps.allKeys) {
			NSDictionary *customAppPrefs = prefCustomApps[customAppID];
			// skip if custom app is disabled, default enabled so ignore bool check if key doesn't exist
			if (customAppPrefs[@"enabled"] && !((NSNumber *) customAppPrefs[@"enabled"]).boolValue) {
				continue;
			}
			NSDictionary *customAppDevices = customAppPrefs[@"devices"] ?: @{};

			NSMutableArray *customAppEnabledDevices = [NSMutableArray new];
			for (NSString *customAppDevice in customAppDevices.allKeys) {
				if (((NSNumber *) customAppDevices[customAppDevice]).boolValue) {
					[customAppEnabledDevices addObject:customAppDevice];
				}
			}
			customApps[customAppID] = @{
				@"device": [[customAppEnabledDevices componentsJoinedByString:@","] retain]
			};
			// [customAppEnabledDevices release];
			// [customAppDevices release];
			// [customAppPrefs release];
		}
		servicePrefs[@"customApps"] = [customApps copy];
		// [customApps release];

		pusherEnabledServices[service] = [servicePrefs copy];
	}

	XLog(@"Reloaded");
}

static BOOL prefsSayNo() {
	if (!pusherEnabled
				|| globalBlacklist == nil || ![globalBlacklist isKindOfClass:NSArray.class]) {
		return YES;
	}
	for (NSString *service in pusherEnabledServices.allKeys) {
		NSDictionary *servicePrefs = pusherEnabledServices[service];
		if (servicePrefs == nil
					|| servicePrefs[@"blacklist"] == nil || ![servicePrefs[@"blacklist"] isKindOfClass:NSArray.class]
					|| servicePrefs[@"token"] == nil || ![servicePrefs[@"token"] isKindOfClass:NSString.class] || ((NSString *) servicePrefs[@"token"]).length == 0
					|| servicePrefs[@"user"] == nil || ![servicePrefs[@"user"] isKindOfClass:NSString.class] || ((NSString *) servicePrefs[@"user"]).length == 0
					|| servicePrefs[@"device"] == nil || ![servicePrefs[@"device"] isKindOfClass:NSString.class] // device can be empty depending on API
					|| servicePrefs[@"url"] == nil || ![servicePrefs[@"url"] isKindOfClass:NSString.class] || ((NSString *) servicePrefs[@"url"]).length == 0
					|| servicePrefs[@"customApps"] == nil || ![servicePrefs[@"customApps"] isKindOfClass:NSDictionary.class]) {
			return YES;
		}
	}
	return NO;
}

%hook BBServer

%new
- (void)sendBulletinToPusher:(BBBulletin *)bulletin {
	if (bulletin == nil || prefsSayNo()) {
		XLog(@"Prefs said no / bulletin nil: %d", bulletin == nil);
		return;
	}
	// Check if notification within last 5 seconds so we don't send uncleared notifications every respring
	NSDate *fiveSecondsAgo = [[NSDate date] dateByAddingTimeInterval:-5];
	if (bulletin.date && [bulletin.date compare:fiveSecondsAgo] == NSOrderedAscending) {
		return;
	}
	NSString *appID = bulletin.sectionID;
	// Blacklist array contains lowercase app IDs
	if ([globalBlacklist containsObject:appID.lowercaseString]) {
		XLog(@"Blacklisted");
		return;
	}

	SBApplication *app = [[NSClassFromString(@"SBApplicationController") sharedInstance] applicationWithBundleIdentifier:appID];
	NSString *appName = app && app.displayName && app.displayName.length > 0 ? app.displayName : Xstr(@"Unknown App: %@", appID);
	NSString *title = Xstr(@"%@%@", appName, (bulletin.title && bulletin.title.length > 0 ? Xstr(@" [%@]", bulletin.title) : @""));
	NSString *message = @"";
	if (bulletin.subtitle && bulletin.subtitle.length > 0) {
		message = bulletin.subtitle;
	}
	message = Xstr(@"%@%@%@", message, (message.length > 0 && bulletin.message && bulletin.message.length > 0 ? @"\n" : @""), bulletin.message ? bulletin.message : @"");

	for (NSString *service in pusherEnabledServices.allKeys) {
		NSDictionary *servicePrefs = pusherEnabledServices[service];
		NSArray *serviceBlacklist = servicePrefs[@"blacklist"];
		// Blacklist array contains lowercase app IDs
		if ([serviceBlacklist containsObject:appID.lowercaseString]) {
			continue;
		}
		// Custom app prefs?
		NSString *device = servicePrefs[@"device"];
		NSDictionary *customApps = servicePrefs[@"customApps"];
		if ([customApps.allKeys containsObject:appID] && customApps[appID][@"device"]) {
			device = customApps[appID][@"device"];
		}
		// Send
		NSDictionary *userData = @{
			@"token": servicePrefs[@"token"],
			@"user": servicePrefs[@"user"],
			@"title": title,
			@"message": message,
			@"device": device
		};
		[self makePusherRequest:servicePrefs[@"url"] userData:userData];
	}

	XLog(@"Pushed %@", appName);
}

%new
- (void)makePusherRequest:(NSString *)urlString userData:(NSDictionary *)userData {
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userData options:NSJSONWritingPrettyPrinted error:nil];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:Xstr(@"%lu", jsonData.length) forHTTPHeaderField:@"Content-length"];
	[request setHTTPBody:jsonData];

	//use async way to connect network
	[[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (data.length && error == nil) {
			XLog(@"Success");
		} else if (error) {
			XLog(@"Error: %@", error);
		} else {
			XLog(@"No data");
		}
	}] resume];
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
