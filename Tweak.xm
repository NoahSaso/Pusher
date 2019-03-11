#import "global.h"
#import <Custom/defines.h>

#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

@interface BBBulletin (Pusher)
@property (nonatomic, readonly) BOOL showsSubtitle;
- (void)sendBulletinToPusher:(BBBulletin *)bulletin;
- (void)makePusherRequest:(NSString *)urlString infoDict:(NSDictionary *)infoDict credentials:(NSDictionary *)credentials authType:(PusherAuthorizationType)authType;
@end

static BOOL pusherEnabled = NO;
static NSArray *globalBlacklist = nil;
static NSMutableDictionary *pusherEnabledServices = nil;

static NSMutableArray *recentNotificationTitles = [NSMutableArray new];

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
		NSArray *devices = prefs[devicesKey] ?: @[];
		NSMutableArray *enabledDevices = [NSMutableArray new];
		for (NSDictionary *device in devices) {
			if (((NSNumber *) device[@"enabled"]).boolValue) {
				[enabledDevices addObject:device];
			}
		}
		servicePrefs[@"devices"] = [enabledDevices retain];
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
			NSArray *customAppDevices = customAppPrefs[@"devices"] ?: @{};

			NSMutableArray *customAppEnabledDevices = [NSMutableArray new];
			for (NSDictionary *customAppDevice in customAppDevices) {
				if (((NSNumber *) customAppDevice[@"enabled"]).boolValue) {
					[customAppEnabledDevices addObject:customAppDevice];
				}
			}
			customApps[customAppID] = @{
				@"devices": [customAppEnabledDevices retain]
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
					|| servicePrefs[@"devices"] == nil || ![servicePrefs[@"devices"] isKindOfClass:NSArray.class] // devices can be empty depending on API
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

	for (NSString *recentNotificationTitle in recentNotificationTitles) {
		// prevent looping by checking if this title contains any recent titles in format of "App [Previous Title]"
		if (Xeq(title, Xstr(@"%@ [%@]", appName, recentNotificationTitle))) {
			XLog(@"Prevented loop");
			return;
		}
	}
	// keep array small, looping shouldn't happen after 100 notifications have already passed
	if (recentNotificationTitles.count >= 100) {
		[recentNotificationTitles removeAllObjects];
	}
	[recentNotificationTitles addObject:title];

	for (NSString *service in pusherEnabledServices.allKeys) {
		NSDictionary *servicePrefs = pusherEnabledServices[service];
		NSArray *serviceBlacklist = servicePrefs[@"blacklist"];
		// Blacklist array contains lowercase app IDs
		if ([serviceBlacklist containsObject:appID.lowercaseString]) {
			continue;
		}
		// Custom app prefs?
		NSArray *devices = servicePrefs[@"devices"];
		NSDictionary *customApps = servicePrefs[@"customApps"];
		if ([customApps.allKeys containsObject:appID] && customApps[appID][@"devices"]) {
			devices = customApps[appID][@"devices"];
		}
		NSMutableArray *deviceIDs = [NSMutableArray new];
		// filters for enabled in prefs changed
		for (NSDictionary *device in devices) {
			[deviceIDs addObject:device[@"id"]];
		}
		// PUSHOVER SPECIFIC
		NSString *device = [deviceIDs componentsJoinedByString:@","];
		// Send
		NSDictionary *infoDict = @{
			@"title": title,
			@"message": message,
			@"device": device
		};
		NSDictionary *credentials = nil;
		PusherAuthorizationType authType = PusherAuthorizationTypeCredentials;
		if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
			// authType = PusherAuthorizationTypeCredentials;
			credentials = @{
				@"token": servicePrefs[@"token"],
				@"user": servicePrefs[@"user"]
			};
		}/* else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
			authType = PusherAuthorizationTypeHeader;
			credentials = @{
				@"token": servicePrefs[@"token"]
			};
		}*/
		[self makePusherRequest:servicePrefs[@"url"] infoDict:infoDict credentials:credentials authType:authType];
	}

	XLog(@"Pushed %@", appName);
}

%new
- (void)makePusherRequest:(NSString *)urlString infoDict:(NSDictionary *)infoDict credentials:(NSDictionary *)credentials authType:(PusherAuthorizationType)authType {
	NSMutableDictionary *infoDictForJSON = [infoDict mutableCopy];
	if (authType == PusherAuthorizationTypeCredentials) {
		[infoDictForJSON addEntriesFromDictionary:credentials];
	}
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDictForJSON options:NSJSONWritingPrettyPrinted error:nil];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	if (authType == PusherAuthorizationTypeHeader) {
		[request setValue:credentials[@"token"] forHTTPHeaderField:@"Access-Token"];
	}
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
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)pusherPrefsChanged, PUSHER_PREFS_NOTIFICATION, NULL, CFNotificationSuspensionBehaviorCoalesce);
	pusherPrefsChanged();
	%init;
}
