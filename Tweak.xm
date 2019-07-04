#import "global.h"
#import <Custom/defines.h>
#import "NSPTestPush.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <notify.h>

@interface UIImage (UIApplicationIconPrivate)
/*
 @param format
    0 - 29x29
    1 - 40x40
    2 - 62x62
    3 - 42x42
    4 - 37x48
    5 - 37x48
    6 - 82x82
    7 - 62x62
    8 - 20x20
    9 - 37x48
    10 - 37x48
    11 - 122x122
    12 - 58x58
 */
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format;
@end

static BOOL pusherEnabled = NO;
static int pusherWhenToPush = PUSHER_WHEN_TO_PUSH_LOCKED;
static NSArray *pusherSNS = nil;
static BOOL pusherSNSIsAnd = YES;
static BOOL pusherSNSRequireANWithOR = YES;
static int pusherWhatNetwork = PUSHER_WHAT_NETWORK_ALWAYS;
static BOOL globalAppListIsBlacklist = YES;
static NSArray *globalAppList = nil;
static NSMutableDictionary *pusherEnabledServices = nil;
static NSMutableDictionary *pusherServicePrefs = nil;
static NSMutableArray *pusherEnabledLogs = nil;

static BBServer *bbServerInstance = nil;

static NSMutableArray *recentNotificationTitles = [NSMutableArray new];

static NSString *stringForObject(id object, NSString *prefix) {
	NSString *str = @"";
	if (!object) {
		str = Xstr(@"%@nil", prefix);
	} else if ([object isKindOfClass:NSArray.class]) {
		NSArray *array = (NSArray *) object;
		str = @"[";
		for (id val in array) {
			str = Xstr(@"%@\n%@\t%@", str, prefix, stringForObject(val, Xstr(@"%@\t", prefix)));
		}
		str = Xstr(@"%@\n%@]", str, prefix);
	} else if ([object isKindOfClass:NSDictionary.class]) {
		NSDictionary *dict = (NSDictionary *) object;
		str = @"{";
		for (id key in dict.allKeys) {
			str = Xstr(@"%@\n%@\t%@: %@", str, prefix, key, stringForObject(dict[key], Xstr(@"%@\t", prefix)));
		}
		str = Xstr(@"%@\n%@}", str, prefix);
	} else {
		str = Xstr(@"%@%@", prefix, object);
	}
	return str;
}

static NSString *stringForObject(id object) {
	return stringForObject(object, @"");
}

static void addToLogIfEnabled(NSString *service, BBBulletin *bulletin, NSString *label, id object) {
	// allow global service which is @"" so empty
	if (!XIS_EMPTY(service) && pusherEnabledLogs && ![pusherEnabledLogs containsObject:service]) {
		XLog(@"[S:%@] Log Disabled", service);
		return;
	}

	CFPreferencesSynchronize(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFArrayRef keyList = CFPreferencesCopyKeyList(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSDictionary *prefs = @{};
	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (!prefs) { prefs = @{}; }
		CFRelease(keyList);
	}

	NSString *logKey = Xstr(@"%@Log", service);
	NSMutableArray *logSections = [(prefs[logKey] ?: @[]) mutableCopy];

	NSMutableDictionary *existingLogSection = nil;
	int replaceIdx = -1;
	for (int i = 0; i < logSections.count; i++) {
		NSDictionary *logSection = logSections[i];
		NSDate *timestamp = (NSDate *) logSection[@"timestamp"];
		if (timestamp && [timestamp isKindOfClass:NSDate.class] && [timestamp respondsToSelector:@selector(isEqualToDate:)] && [timestamp isEqualToDate:bulletin.date]) {
			existingLogSection = [logSection mutableCopy];
			replaceIdx = i;
			break;
		}
	}

	if (!existingLogSection || replaceIdx == -1) {
		existingLogSection = [@{
			@"appID": bulletin.sectionID,
			@"timestamp": bulletin.date
		} mutableCopy];
		[logSections addObject:existingLogSection];
	}

	NSMutableArray *logs = [(existingLogSection[@"logs"] ?: @[]) mutableCopy];

	if (logs.count == 0) {
		[logs addObject:Xstr(@"Processing %@", bulletin.sectionID)];
	}

	NSString *logItem = nil;
	// if only one passed, only do one of them
	if ((label && !object) || (!label && object)) {
		logItem = label ?: stringForObject(object);
	} else {
		logItem = Xstr(@"%@: %@", label, stringForObject(object));
	}
	[logs addObject:logItem];

	existingLogSection[@"logs"] = logs;

	if (replaceIdx > -1) {
		[logSections replaceObjectAtIndex:replaceIdx withObject:existingLogSection];
	}

	CFPreferencesSetValue((__bridge CFStringRef) logKey, (__bridge CFPropertyListRef) logSections, PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(PUSHER_LOG_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	notify_post(PUSHER_LOG_PREFS_NOTIFICATION);

	XLog(@"[S:%@] Saved to log", service);
}

static void addToLogIfEnabled(NSString *service, BBBulletin *bulletin, NSString *label) {
	addToLogIfEnabled(service, bulletin, label, nil);
}

// returns array of all lowercase keys that begin with the given prefix that have a boolean value of true in the dictionary
static NSArray *getAppIDsWithPrefix(NSDictionary *prefs, NSString *prefix) {
	NSMutableArray *keys = [NSMutableArray new];
	for (id key in prefs.allKeys) {
		if (![key isKindOfClass:NSString.class]) { continue; }
		if ([key hasPrefix:prefix] && ((NSNumber *) prefs[key]).boolValue) {
			NSString *subKey = [key substringFromIndex:prefix.length];
			[keys addObject:subKey.lowercaseString];
		}
	}
	return keys;
}

static NSArray *getSNSKeys(NSDictionary *prefs, NSString *prefix, NSDictionary *backupPrefs, NSString *backupPrefix) {
	NSMutableArray *keys = [NSMutableArray new];
	NSDictionary *pusherDefaultSNSKeys = PUSHER_SNS_KEYS;
	for (NSString *snsKey in pusherDefaultSNSKeys.allKeys) {
		NSString *key = Xstr(@"%@%@", prefix, snsKey);
		id val = prefs[key];
		if (val) {
			if (((NSNumber *) val).boolValue) {
				[keys addObject:snsKey];
			}
			continue;
		} else if (!val && backupPrefs) {
			NSString *backupKey = Xstr(@"%@%@", backupPrefix, snsKey);
			if (backupPrefs[backupKey]) {
				if (((NSNumber *) backupPrefs[backupKey]).boolValue) {
					[keys addObject:snsKey];
				}
				continue;
			}
		}
		// check default if val is nil, not if it's set to false
		if (!val && pusherDefaultSNSKeys[snsKey] && ((NSNumber *) pusherDefaultSNSKeys[snsKey]).boolValue) {
			[keys addObject:snsKey];
		}
	}
	return keys;
}

static NSArray *getSNSKeys(NSDictionary *prefs, NSString *prefix) {
	return getSNSKeys(prefs, prefix, nil, nil);
}

static NSString *getServiceURL(NSString *service, NSDictionary *options) {
	if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
		return PUSHER_SERVICE_PUSHOVER_URL;
	} else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
		return PUSHER_SERVICE_PUSHBULLET_URL;
	} else if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
		return [PUSHER_SERVICE_IFTTT_URL stringByReplacingOccurrencesOfString:@"REPLACE_EVENT_NAME" withString:options[@"eventName"]];
	} else if (Xeq(service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
		return [PUSHER_SERVICE_PUSHER_RECEIVER_URL stringByReplacingOccurrencesOfString:@"REPLACE_DB_NAME" withString:options[@"dbName"]];
	}
	return @"";
}

static NSString *getServiceAppID(NSString *service) {
	if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
		return PUSHER_SERVICE_PUSHOVER_APP_ID;
	} else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
		return PUSHER_SERVICE_PUSHBULLET_APP_ID;
	}
	return @"";
}

static PusherAuthorizationType getServiceAuthType(NSString *service, NSDictionary *servicePrefs) {
	if (servicePrefs[@"isCustomService"] && ((NSNumber *) servicePrefs[@"isCustomService"]).boolValue) {
		NSNumber *authMethod = servicePrefs[@"authenticationMethod"];
		if (!authMethod) {
			return PusherAuthorizationTypeNone;
		}
		switch (authMethod.intValue) {
			case 1:
				return PusherAuthorizationTypeHeader;
			case 2:
				return PusherAuthorizationTypeCredentials;
			default:
				return PusherAuthorizationTypeNone;
		}
	} else if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
		return PusherAuthorizationTypeCredentials;
	} else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET) || Xeq(service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
		return PusherAuthorizationTypeHeader;
	}
	return PusherAuthorizationTypeReplaceKey; // ifttt key
}

static NSString *base64RepresentationForImage(UIImage *image) {
	NSData *iconData = UIImagePNGRepresentation(image);
	return [iconData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
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

	id val = prefs[@"Enabled"];
	pusherEnabled = val ? ((NSNumber *) val).boolValue : YES;
	val = prefs[@"WhenToPush"];
	pusherWhenToPush = val ? ((NSNumber *) val).intValue : PUSHER_WHEN_TO_PUSH_LOCKED;
	val = prefs[@"WhatNetwork"];
	pusherWhatNetwork = val ? ((NSNumber *) val).intValue : PUSHER_WHAT_NETWORK_ALWAYS;
	val = prefs[@"GlobalAppListIsBlacklist"];
	globalAppListIsBlacklist = val ? ((NSNumber *) val).boolValue : YES;
	val = prefs[@"SufficientNotificationSettingsIsAnd"];
	pusherSNSIsAnd = val ? ((NSNumber *) val).boolValue : YES;
	val = prefs[@"SNSORRequireAllowNotifications"];
	pusherSNSRequireANWithOR = val ? ((NSNumber *) val).boolValue : YES;
	globalAppList = getAppIDsWithPrefix(prefs, NSPPreferenceGlobalBLPrefix);
	pusherSNS = getSNSKeys(prefs, NSPPreferenceSNSPrefix);

	if (pusherEnabledServices == nil) {
		pusherEnabledServices = [NSMutableDictionary new];
	}
	if (pusherServicePrefs == nil) {
		pusherServicePrefs = [NSMutableDictionary new];
	}

	pusherEnabledLogs = [NSMutableArray new];

	NSDictionary *customServices = prefs[NSPPreferenceCustomServicesKey];
	for (NSString *service in customServices.allKeys) {
		NSDictionary *customService = customServices[service];
		NSMutableDictionary *servicePrefs = [customService mutableCopy];

		servicePrefs[@"isCustomService"] = @YES;
		servicePrefs[@"appList"] = getAppIDsWithPrefix(prefs, NSPPreferenceCustomServiceBLPrefix(service));
		servicePrefs[@"whenToPush"] = (!servicePrefs[@"whenToPush"] || ((NSNumber *) servicePrefs[@"whenToPush"]).intValue == PUSHER_SEGMENT_CELL_DEFAULT) ? @(pusherWhenToPush) : servicePrefs[@"whenToPush"];
		servicePrefs[@"whatNetwork"] = (!servicePrefs[@"whatNetwork"] || ((NSNumber *) servicePrefs[@"whatNetwork"]).intValue == PUSHER_SEGMENT_CELL_DEFAULT) ? @(pusherWhatNetwork) : servicePrefs[@"whatNetwork"];
		servicePrefs[@"snsIsAnd"] = servicePrefs[@"SufficientNotificationSettingsIsAnd"] ?: @(pusherSNSIsAnd);
		servicePrefs[@"snsRequireANWithOR"] = servicePrefs[@"SNSORRequireAllowNotifications"] ?: @(pusherSNSRequireANWithOR);
		servicePrefs[@"sns"] = getSNSKeys(customService, NSPPreferenceSNSPrefix, prefs, NSPPreferenceSNSPrefix);

		NSString *logEnabledKey = Xstr(@"%@LogEnabled", service);
		id val = prefs[logEnabledKey];
		BOOL logEnabled = val ? ((NSNumber *) val).boolValue : YES;
		if (logEnabled) {
			[pusherEnabledLogs addObject:service];
		}

		NSString *customAppsKey = NSPPreferenceCustomServiceCustomAppsKey(service);

		// custom apps
		NSDictionary *prefCustomApps = (NSDictionary *) prefs[customAppsKey] ?: @{};
		NSMutableDictionary *customApps = [NSMutableDictionary new];
		for (NSString *customAppID in prefCustomApps.allKeys) {
			NSDictionary *customAppPrefs = prefCustomApps[customAppID];
			// skip if custom app is disabled, default enabled so ignore bool check if key doesn't exist
			// COMMENTED OUT BECAUSE REMOVED ENABLE/DISABLE STATUS FOR CUSTOM APPS
			// if (customAppPrefs[@"enabled"] && !((NSNumber *) customAppPrefs[@"enabled"]).boolValue) {
			// 	continue;
			// }
			if (!customAppPrefs) {
				continue;
			}
			customApps[customAppID] = [customAppPrefs copy];
		}

		servicePrefs[@"customApps"] = [customApps copy];

		pusherServicePrefs[service] = [servicePrefs copy];

		// default is service disabled
		if (customService[@"Enabled"] == nil || !((NSNumber *) customService[@"Enabled"]).boolValue) {
			// skip if disabled
			[pusherEnabledServices removeObjectForKey:service];
		} else {
			pusherEnabledServices[service] = pusherServicePrefs[service];
		}
	}

	for (NSString *service in BUILTIN_PUSHER_SERVICES) {
		NSMutableDictionary *servicePrefs = [NSMutableDictionary new];

		NSString *appListPrefix = Xstr(@"%@BL-", service);
		NSString *tokenKey = Xstr(@"%@Token", service);
		NSString *userKey = Xstr(@"%@User", service);
		NSString *keyKey = Xstr(@"%@Key", service);
		NSString *devicesKey = Xstr(@"%@Devices", service);
		NSString *soundsKey = Xstr(@"%@Sounds", service);
		NSString *eventNameKey = Xstr(@"%@EventName", service);
		NSString *dateFormatKey = Xstr(@"%@DateFormat", service);
		NSString *customAppsKey = NSPPreferenceBuiltInServiceCustomAppsKey(service);
		NSString *appListIsBlacklistKey = Xstr(@"%@AppListIsBlacklist", service);
		NSString *dbNameKey = Xstr(@"%@DBName", service);
		NSString *whenToPushKey = Xstr(@"%@WhenToPush", service);
		NSString *whatNetworkKey = Xstr(@"%@WhatNetwork", service);
		NSString *snsIsAndKey = Xstr(@"%@SufficientNotificationSettingsIsAnd", service);
		NSString *snsRequireANWithORKey = Xstr(@"%@SNSORRequireAllowNotifications", service);
		NSString *snsPrefix = Xstr(@"%@%@", service, NSPPreferenceSNSPrefix);
		NSString *logEnabledKey = Xstr(@"%@LogEnabled", service);

		servicePrefs[@"appList"] = getAppIDsWithPrefix(prefs, appListPrefix);
		val = prefs[appListIsBlacklistKey];
		servicePrefs[@"appListIsBlacklist"] = [(val ?: @YES) copy];
		val = prefs[tokenKey];
		servicePrefs[@"token"] = [(val ?: @"") copy];
		val = prefs[userKey];
		servicePrefs[@"user"] = [(val ?: @"") copy];
		val = prefs[keyKey];
		servicePrefs[@"key"] = [(val ?: @"") copy];
		val = prefs[eventNameKey];
		NSString *eventName = [(val ?: @"") copy];
		val = prefs[dbNameKey];
		NSString *dbName = [[(val ?: @"") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
		val = prefs[dateFormatKey];
		servicePrefs[@"dateFormat"] = [(val ?: @"") copy];
		servicePrefs[@"url"] = getServiceURL(service, @{ @"eventName": eventName, @"dbName": dbName });
		val = prefs[whenToPushKey];
		servicePrefs[@"whenToPush"] = val ?: @(PUSHER_WHEN_TO_PUSH_LOCKED);
		servicePrefs[@"whenToPush"] = [(((NSNumber *) servicePrefs[@"whenToPush"]).intValue == PUSHER_SEGMENT_CELL_DEFAULT ? @(pusherWhenToPush) : servicePrefs[@"whenToPush"]) copy];
		val = prefs[whatNetworkKey];
		servicePrefs[@"whatNetwork"] = val ?: @(PUSHER_WHAT_NETWORK_ALWAYS);
		servicePrefs[@"whatNetwork"] = [(((NSNumber *) servicePrefs[@"whatNetwork"]).intValue == PUSHER_SEGMENT_CELL_DEFAULT ? @(pusherWhatNetwork) : servicePrefs[@"whatNetwork"]) copy];
		val = prefs[snsIsAndKey];
		servicePrefs[@"snsIsAnd"] = [(val ?: @YES) copy];
		val = prefs[snsRequireANWithORKey];
		servicePrefs[@"snsRequireANWithOR"] = [(val ?: @YES) copy];
		servicePrefs[@"sns"] = getSNSKeys(prefs, snsPrefix, prefs, NSPPreferenceSNSPrefix);

		val = prefs[logEnabledKey];
		BOOL logEnabled = val ? ((NSNumber *) val).boolValue : YES;
		if (logEnabled) {
			[pusherEnabledLogs addObject:service];
		}

		if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
			NSString *includeIconKey = Xstr(@"%@IncludeIcon", service);
			servicePrefs[@"includeIcon"] = prefs[includeIconKey] ?: @NO;

			NSString *curateDataKey = Xstr(@"%@CurateData", service);
			servicePrefs[@"curateData"] = prefs[curateDataKey] ?: @YES;
		}

		if (Xeq(service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
			NSString *includeIconKey = Xstr(@"%@IncludeIcon", service);
			servicePrefs[@"includeIcon"] = prefs[includeIconKey] ?: @YES;

			NSString *includeImageKey = Xstr(@"%@IncludeImage", service);
			servicePrefs[@"includeImage"] = prefs[includeImageKey] ?: @YES;
		}

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

		// sounds
		NSArray *sounds = prefs[soundsKey] ?: @[];
		NSMutableArray *enabledSounds = [NSMutableArray new];
		for (NSDictionary *sound in sounds) {
			if (((NSNumber *) sound[@"enabled"]).boolValue) {
				[enabledSounds addObject:sound[@"id"]];
			}
		}
		servicePrefs[@"sounds"] = [enabledSounds retain];

		// custom apps
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

			NSArray *customAppSounds = customAppPrefs[@"sounds"] ?: @{};
			NSMutableArray *customAppEnabledSounds = [NSMutableArray new];
			for (NSDictionary *customAppSound in customAppSounds) {
				if (((NSNumber *) customAppSound[@"enabled"]).boolValue) {
					[customAppEnabledSounds addObject:customAppSound[@"id"]];
				}
			}

			NSString *customAppEventName = [(customAppPrefs[@"eventName"] ?: eventName) retain];
			NSString *customAppUrl = getServiceURL(service, @{ @"eventName": customAppEventName, @"dbName": dbName });

			NSMutableDictionary *customAppIDPref = [@{
				@"devices": [customAppEnabledDevices retain],
				@"sounds": [customAppEnabledSounds retain]
			} mutableCopy];

			if (!Xeq(customAppUrl, servicePrefs[@"url"])) {
				customAppIDPref[@"url"] = customAppUrl;
			}

			if (Xeq(service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
				customAppIDPref[@"includeIcon"] = customAppPrefs[@"includeIcon"] ?: @YES;
				customAppIDPref[@"includeImage"] = customAppPrefs[@"includeImage"] ?: @YES;
			}

			if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
				customAppIDPref[@"includeIcon"] = customAppPrefs[@"includeIcon"] ?: @NO;
				customAppIDPref[@"curateData"] = customAppPrefs[@"curateData"] ?: @YES;
			}

			customApps[customAppID] = customAppIDPref;
			// [customAppEnabledDevices release];
			// [customAppDevices release];
			// [customAppPrefs release];
		}
		servicePrefs[@"customApps"] = [customApps copy];
		// [customApps release];

		pusherServicePrefs[service] = [servicePrefs copy];

		NSString *enabledKey = Xstr(@"%@Enabled", service);
		// default is service disabled
		if (prefs[enabledKey] == nil || !((NSNumber *) prefs[enabledKey]).boolValue) {
			// skip if disabled
			[pusherEnabledServices removeObjectForKey:service];
		} else {
			pusherEnabledServices[service] = pusherServicePrefs[service];
		}
	}

	XLog(@"Reloaded");
}

static NSString *snsSaysNo(NSArray *sns, BBSectionInfo *sectionInfo, BOOL isAnd, BOOL requireANWithOR) {
	if (!isAnd && requireANWithOR && !sectionInfo.allowsNotifications) {
		return @"'OR' and 'Require Allow Notifications with OR' both on, but Allow Notifications is disabled in this app's settings.";
	}

	for (NSString *key in sns) {
		BOOL sufficient = YES;
		if (Xeq(key, PUSHER_SUFFICIENT_ALLOW_NOTIFICATIONS_KEY)) {
			sufficient = sectionInfo.allowsNotifications;
		} else if (Xeq(key, PUSHER_SUFFICIENT_LOCK_SCREEN_KEY)) {
			sufficient = sectionInfo.showsInLockScreen;
		} else if (Xeq(key, PUSHER_SUFFICIENT_NOTIFICATION_CENTER_KEY)) {
			sufficient = sectionInfo.showsInNotificationCenter;
		} else if (Xeq(key, PUSHER_SUFFICIENT_BANNERS_KEY)) {
			sufficient = sectionInfo.alertType == BBSectionInfoAlertTypeBanner;
		} else if (Xeq(key, PUSHER_SUFFICIENT_BADGES_KEY)) {
			sufficient = (sectionInfo.pushSettings & BBActualSectionInfoPushSettingsBadges) != 0;
		// } else if (Xeq(key, PUSHER_SUFFICIENT_SOUNDS_KEY)) {
			// sufficient = (sectionInfo.pushSettings & BBActualSectionInfoPushSettingsSounds) != 0;
		} else if (Xeq(key, PUSHER_SUFFICIENT_SHOWS_PREVIEWS_KEY)) {
			sufficient = sectionInfo.showsMessagePreview;
		}
		// AND, so if any one is insufficient, just return right away
		if (isAnd && !sufficient) {
			return Xstr(@"'AND' but %@ incorrect", key);
		// OR, so just one sufficient is enough
		} else if (!isAnd && sufficient) {
			XLog(@"OR and sufficient: %@", key);
			break;
		}
	}

	// none passed as sufficient before so insufficient if OR
	if (!isAnd) {
		XLog(@"OR and insufficient");
		return @"'OR' and none were correct";
	}

	return nil;
}

static NSString *deviceConditionsSayNo(int whenToPush, int whatNetwork) {
	BOOL deviceIsLocked = ((SBLockScreenManager *) [%c(SBLockScreenManager) sharedInstance]).isUILocked;
	NSString *wifiName = [[%c(SBWiFiManager) sharedInstance] currentNetworkName];
	BOOL onWiFi = wifiName != nil;
	if (whatNetwork == PUSHER_WHAT_NETWORK_WIFI_ONLY && !onWiFi) {
		return @"What Network set to WiFi Only but not on WiFi";
	}
	if ((whenToPush == PUSHER_WHEN_TO_PUSH_LOCKED && !deviceIsLocked)
			|| (whenToPush == PUSHER_WHEN_TO_PUSH_UNLOCKED && deviceIsLocked)) {
		return Xstr(@"When to Push set to %@ but device %@locked", (whenToPush == PUSHER_WHEN_TO_PUSH_LOCKED ? @"Locked" : (whenToPush == PUSHER_WHEN_TO_PUSH_UNLOCKED ? @"Unlocked" : @"Always")), deviceIsLocked ? @"" : @"un");
	}
	return nil;
}

static NSString *prefsSayNo(BBServer *server, BBBulletin *bulletin) {
	XLog(@"---Bulletin:--- %@", bulletin.sectionID);
	if (!pusherEnabled) {
		return Xstr(@"Pusher %@abled", pusherEnabled ? @"En" : @"Dis");
	}

	if (bulletin.sectionID && Xeq(bulletin.sectionID, PUSHER_TEST_NOTIFICATION_SECTION_ID) && bulletin.title && Xeq(bulletin.title, @"Pusher") && bulletin.message && [bulletin.message hasPrefix:PUSHER_TEST_PUSH_RESULT_PREFIX]) {
		return @"Not forwarding test notification result banner";
	}

	if (!globalAppList || ![globalAppList isKindOfClass:NSArray.class]) {
		return Xstr(@"Global app list is nil, it shouldn't be. %@", globalAppList);
	}

	if (!server) {
		return @"Server is nil, it shouldn't be";
	}

	BBSectionInfo *sectionInfo = [server _sectionInfoForSectionID:bulletin.sectionID effective:YES];
	if (!sectionInfo) {
		return @"Section info is nil, it shouldn't be";
	}

	if (!pusherEnabledServices || ![pusherEnabledServices isKindOfClass:NSDictionary.class]) {
		return Xstr(@"Enabled services is nil, it shouldn't be. %@", pusherEnabledServices);
	}

	for (NSString *service in pusherEnabledServices.allKeys) {
		NSDictionary *servicePrefs = pusherEnabledServices[service];
		if (!servicePrefs || ![servicePrefs isKindOfClass:NSDictionary.class]) {
			return @"Service prefs are nil, they shouldn't be";
		}
	}
	return nil;
}

%hook BBServer

%new
+ (BBServer *)pusherSharedInstance {
	return bbServerInstance;
}

- (void)_addObserver:(id)arg1 {
	bbServerInstance = self;
	%orig;
}

%new
- (void)sendBulletinToPusher:(BBBulletin *)bulletin {
	if (!bulletin) {
		XLog(@"Bulletin nil");
		return;
	}
	if (!bulletin.date) {
		bulletin.date = [NSDate date]; // for logging to visual log
	}

	// bulletin.lastInterruptDate is nil upon respring, so ignore if that's the case
	if (!bulletin.lastInterruptDate) {
		XLog(@"Not forwarding, Last Interrupt Date: %@", bulletin.lastInterruptDate);
		addToLogIfEnabled(@"", bulletin, @"Last interrupt date nil (this should only happen if SpringBoard just restarted; if some other time, there is a problem)");
		return;
	}

	if (!NSClassFromString(@"SBApplicationController") || ![%c(SBApplicationController) sharedInstance]) {
		XLog(@"SpringBoard not ready");
		addToLogIfEnabled(@"", bulletin, @"SpringBoard not ready");
		return;
	}

	// THIS METHOD IS BAD BECAUSE THEN NOTIFICATIONS DATED IN THE PAST (e.g. Messages, Mail, etc.) WILL NOT GET FORWARDED
	// THIS IS WHY USE NEW METHOD OF lastInterruptDate = nil ABOVE
	// // Check if notification within last 5 seconds so we don't send uncleared notifications every respring
	// NSDate *fiveSecondsAgo = [[NSDate date] dateByAddingTimeInterval:-5];
	// if (bulletin.date && [bulletin.date compare:fiveSecondsAgo] == NSOrderedAscending) {
	// 	XLog(@"Bulletin 5 seconds or older");
	// 	addToLogIfEnabled(@"", bulletin, @"Notification dated greater than 5 seconds ago, not sending to prevent resending all notifications on respring");
	// 	return;
	// }

	NSString *appID = bulletin.sectionID;
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:appID];
	NSString *appName = app && app.displayName && app.displayName.length > 0 ? app.displayName : Xstr(@"Unknown App: %@", appID);

	NSString *prefsResponse = prefsSayNo(self, bulletin);
	if (prefsResponse) {
		XLog(@"Prefs say no: %@", prefsResponse);
		addToLogIfEnabled(@"", bulletin, Xstr(@"Global prefs: %@", prefsResponse));
		return;
	}

	// App list contains lowercase app IDs
	BOOL appListContainsApp = [globalAppList containsObject:appID.lowercaseString];
	if (globalAppListIsBlacklist == appListContainsApp) {
		XLog(@"[Global] Blocked by app list: %@", appID);
		addToLogIfEnabled(@"", bulletin, Xstr(@"Blocked by global app list (%@)", globalAppListIsBlacklist ? @"blacklist" : @"whitelist"));
		return;
	}

	NSString *title = Xstr(@"%@%@", appName, (bulletin.title && bulletin.title.length > 0 ? Xstr(@": %@", bulletin.title) : @""));
	NSString *message = @"";
	if (bulletin.showsSubtitle && bulletin.subtitle && bulletin.subtitle.length > 0) {
		message = bulletin.subtitle;
	}
	message = Xstr(@"%@%@%@", message, (message.length > 0 && bulletin.message && bulletin.message.length > 0 ? @"\n" : @""), bulletin.message ? bulletin.message : @"");

	for (NSString *recentNotificationTitle in recentNotificationTitles) {
		// prevent looping by checking if this title contains any recent titles in format of "App [Previous Title]"
		if (Xeq(title, Xstr(@"%@: %@", appName, recentNotificationTitle))) {
			XLog(@"Prevented loop");
			addToLogIfEnabled(@"", bulletin, @"Prevented loop");
			return;
		}
	}
	// keep array small, looping shouldn't happen after 50 notifications have already passed
	if (recentNotificationTitles.count >= 50) {
		[recentNotificationTitles removeAllObjects];
	}
	[recentNotificationTitles addObject:title];

	for (NSString *service in pusherEnabledServices.allKeys) {
		[self sendToPusherService:service bulletin:bulletin appID:appID appName:appName title:title message:message isTest:NO];
	}
}

%new
- (void)sendToPusherService:(NSString *)service bulletin:(BBBulletin *)bulletin appID:(NSString *)appID appName:(NSString *)appName title:(NSString *)title message:(NSString *)message isTest:(BOOL)isTest {
	if (!isTest && Xeq(appID, getServiceAppID(service))) {
		XLog(@"Prevented loop from same app");
		addToLogIfEnabled(service, bulletin, @"Prevented loop from same app");
		return;
	}
	NSDictionary *servicePrefs = pusherServicePrefs[service];
	if (!isTest) {
		NSArray *serviceAppList = servicePrefs[@"appList"];
		BOOL appListContainsApp = [serviceAppList containsObject:appID.lowercaseString];
		id appListIsBlacklist = servicePrefs[@"appListIsBlacklist"];
		if (appListIsBlacklist && ((NSNumber *) appListIsBlacklist).boolValue == appListContainsApp) {
			XLog(@"[S:%@] Blocked by app list: %@", service, appID);
			addToLogIfEnabled(service, bulletin, Xstr(@"Blocked by app list (%@)", ((NSNumber *) appListIsBlacklist).boolValue ? @"blacklist" : @"whitelist"));
			return;
		}

		NSArray *sns = servicePrefs[@"sns"];
		BOOL isAnd = servicePrefs[@"snsIsAnd"] && ((NSNumber *) servicePrefs[@"snsIsAnd"]).boolValue;
		BOOL requireANWithOR = servicePrefs[@"snsRequireANWithOR"] && ((NSNumber *) servicePrefs[@"snsRequireANWithOR"]).boolValue;
		BBSectionInfo *sectionInfo = [self _sectionInfoForSectionID:bulletin.sectionID effective:YES];
		if (!sectionInfo) {
			XLog(@"[S:%@,A:%@] sectionInfo nil", service, appID);
			addToLogIfEnabled(service, bulletin, @"sectionInfo is nil, it should not be");
			return;
		}
		XLog(@"[S:%@,A:%@] Doing SNS", service, appID);
		NSString *snsResponse = snsSaysNo(sns, sectionInfo, isAnd, requireANWithOR);
		if (snsResponse) {
			XLog(@"[S:%@,A:%@] SNS said no: %@", service, appID, snsResponse);
			addToLogIfEnabled(service, bulletin, snsResponse);
			return;
		}

		int serviceWhenToPush = ((NSNumber *) servicePrefs[@"whenToPush"]).intValue;
		int serviceWhatNetwork = ((NSNumber *) servicePrefs[@"whatNetwork"]).intValue;
		XLog(@"[S:%@,A:%@] Doing Device Conditions", service, appID);
		NSString *deviceConditionsResponse = deviceConditionsSayNo(serviceWhenToPush, serviceWhatNetwork);
		if (deviceConditionsResponse) {
			XLog(@"[S:%@,A:%@] Device Conditions said no: %@", service, appID, deviceConditionsResponse);
			addToLogIfEnabled(service, bulletin, deviceConditionsResponse);
			return;
		}
	}
	// Custom app prefs?
	NSDictionary *customApps = servicePrefs[@"customApps"];

	NSArray *devices = servicePrefs[@"devices"];
	NSArray *sounds = servicePrefs[@"sounds"];
	NSString *url = servicePrefs[@"url"];
	NSNumber *includeIcon = servicePrefs[@"includeIcon"] ?: @NO; // default NO for custom services, default check for built in services done earlier so should never get to this NO
	NSNumber *includeImage = servicePrefs[@"includeImage"] ?: @NO; // default NO for custom services, default check for built in services done earlier so should never get to this NO
	NSNumber *curateData = servicePrefs[@"curateData"] ?: @YES;
	if ([customApps.allKeys containsObject:appID]) {
		devices = customApps[appID][@"devices"] ?: devices;
		sounds = customApps[appID][@"sounds"] ?: sounds;
		url = customApps[appID][@"url"] ?: url;
		includeIcon = customApps[appID][@"includeIcon"] ?: includeIcon;
		includeImage = customApps[appID][@"includeImage"] ?: includeImage;
		curateData = customApps[appID][@"curateData"] ?: curateData;
	}
	// Send
	PusherAuthorizationType authType = getServiceAuthType(service, servicePrefs);
	NSDictionary *infoDict = [self getPusherInfoDictionaryForService:service withDictionary:@{
		@"title": title ?: @"",
		@"message": message ?: @"",
		@"devices": devices ?: @[],
		@"sounds": sounds ?: @[],
		@"appName": appName ?: @"",
		@"bulletin": bulletin,
		@"dateFormat": XStrDefault(servicePrefs[@"dateFormat"], @"MMM d, h:mm a"),
		@"includeIcon": includeIcon,
		@"includeImage": includeImage,
		@"curateData": curateData,
	}];
	NSDictionary *credentials = [self getPusherCredentialsForService:service withDictionary:@{
		@"token": servicePrefs[@"token"] ?: @"",
		@"user": servicePrefs[@"user"] ?: @"",
		@"key": servicePrefs[@"key"] ?: @"",
		@"paramName": authType == PusherAuthorizationTypeCredentials ? XStrDefault(servicePrefs[@"paramName"], @"key") : @"",
		@"headerName": authType == PusherAuthorizationTypeHeader ? XStrDefault(servicePrefs[@"paramName"], @"Access-Token") : @""
	}];
	NSString *method = XStrDefault(servicePrefs[@"method"], @"POST");
	[self makePusherRequest:url infoDict:infoDict credentials:credentials authType:authType method:method logString:Xstr(@"[S:%@,A:%@]", service, appName) service:service bulletin:bulletin];
	XLog(@"[S:%@,T:%d,A:%@] Pushed", service, isTest, appName);
	if (!isTest) {
		addToLogIfEnabled(service, bulletin, @"Pushed");
	}
}

%new
- (NSDictionary *)getPusherInfoDictionaryForService:(NSString *)service withDictionary:(NSDictionary *)dictionary {
	NSMutableArray *deviceIDs = [NSMutableArray new];
	for (NSDictionary *device in dictionary[@"devices"]) {
		[deviceIDs addObject:device[@"id"]];
	}
	if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
		NSString *combinedDevices = [deviceIDs componentsJoinedByString:@","];
		NSMutableDictionary *pushoverInfoDict = [@{
			@"title": dictionary[@"title"],
			@"message": dictionary[@"message"],
			@"device": combinedDevices
		} mutableCopy];
		NSString *firstSoundID = [dictionary[@"sounds"] firstObject];
		if (firstSoundID) {
			pushoverInfoDict[@"sound"] = firstSoundID;
		}
		return pushoverInfoDict;
	} else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
		// should always only be one, but just in case
		NSString *firstDevice = [deviceIDs firstObject];
		NSMutableDictionary *pushbulletInfoDict = [@{
			@"type": @"note",
			@"title": dictionary[@"title"],
			@"body": dictionary[@"message"]
		} mutableCopy];
		if (firstDevice) {
			pushbulletInfoDict[@"device_iden"] = firstDevice;
		}
		return pushbulletInfoDict;
	}

	// ifttt, pusher receiver, and custom services
	BBBulletin *bulletin = dictionary[@"bulletin"];
	// date
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	[dateFormatter setDateFormat:dictionary[@"dateFormat"]];
	NSString *dateStr = [dateFormatter stringFromDate:bulletin.date];
	[dateFormatter release];

	NSMutableDictionary *data = [@{
		@"appName": dictionary[@"appName"] ?: @"",
		@"appID": bulletin.sectionID ?: @"",
		@"title": bulletin.title ?: @"",
		@"subtitle": bulletin.subtitle ?: @"",
		@"message": bulletin.message ?: @"",
		@"date": dateStr ?: @""
	} mutableCopy];

	if (dictionary[@"includeIcon"] && ((NSNumber *)dictionary[@"includeIcon"]).boolValue) {
		data[@"icon"] = [self base64IconDataForBundleID:bulletin.sectionID];
	}

	if (dictionary[@"includeImage"] && ((NSNumber *)dictionary[@"includeImage"]).boolValue) {
		BBAttachmentMetadata *metadata = bulletin.primaryAttachment;
		if (metadata && metadata.type == 1 && metadata.URL) { // I assume image type is 1
			NSURL *URL = metadata.URL;
			UIImage *image = [UIImage imageWithContentsOfFile:URL.path];
			if (image) {
				data[@"image"] = base64RepresentationForImage(image);
			}
		}
	}

	if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
		if (dictionary[@"curateData"] && ((NSNumber *)dictionary[@"curateData"]).boolValue) {
			return @{ @"value1": dictionary[@"title"], @"value2": dictionary[@"message"], @"value3": data[@"icon"] ?: dateStr };
		}
		id json = data;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
		if (jsonData) {
			json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		}
		return @{ @"value1": json };
	}

	return data;
}

%new
- (NSString *)base64IconDataForBundleID:(NSString *)bundleID {
	SBApplicationIcon *icon = [((SBIconController *)[%c(SBIconController) sharedInstance]).model expectedIconForDisplayIdentifier:bundleID];
	return base64RepresentationForImage([icon generateIconImage:2]);
}

%new
- (NSDictionary *)getPusherCredentialsForService:(NSString *)service withDictionary:(NSDictionary *)dictionary {
	if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
		return @{
			@"token": dictionary[@"token"],
			@"user": dictionary[@"user"]
		};
	} else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
		return @{
			@"headerName": @"Access-Token",
			@"value": dictionary[@"token"]
		};
	} else if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
		return @{
			@"key": dictionary[@"key"]
		};
	} else if (Xeq(service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
		return @{
			@"headerName": @"x-apikey",
			@"value": dictionary[@"key"]
		};
	}

	// custom services
	if (dictionary[@"paramName"] && ((NSString *) dictionary[@"paramName"]).length > 0) {
		return @{
			dictionary[@"paramName"]: dictionary[@"key"]
		};
	} else if (dictionary[@"headerName"] && ((NSString *) dictionary[@"headerName"]).length > 0) {
		return @{
			@"key": dictionary[@"key"],
			@"headerName": dictionary[@"headerName"]
		};
	}

	return @{
		@"key": dictionary[@"key"]
	};
}

%new
- (void)makePusherRequest:(NSString *)urlString infoDict:(NSDictionary *)infoDict credentials:(NSDictionary *)credentials authType:(PusherAuthorizationType)authType method:(NSString *)method logString:(NSString *)logString service:(NSString *)service bulletin:(BBBulletin *)bulletin {

	NSMutableDictionary *infoDictForRequest = [infoDict mutableCopy];
	if (authType == PusherAuthorizationTypeCredentials) {
		[infoDictForRequest addEntriesFromDictionary:credentials];
	}
	if (authType == PusherAuthorizationTypeReplaceKey) {
		urlString = [urlString stringByReplacingOccurrencesOfString:@"REPLACE_KEY" withString:credentials[@"key"]];
	}

	if (Xeq(method, @"GET")) {
		NSString *parameterString = @"";
		for (NSString *key in infoDictForRequest.allKeys) {
			NSString *value = XStrDefault(infoDictForRequest[key], @"");
			NSString *escapedKey = [[[key stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"] stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
			NSString *escapedValue = [[[value stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"] stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
			parameterString = Xstr(@"%@%@%@=%@", parameterString, (parameterString.length < 1 ? @"" : @"&"), escapedKey, escapedValue);
		}
		urlString = Xstr(@"%@?%@", urlString, parameterString);
		XLog(@"URL String: %@", urlString);
	}

	urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	addToLogIfEnabled(service, bulletin, @"URL", urlString);
	NSURL *requestURL = [NSURL URLWithString:urlString];
	if (!requestURL) {
		XLog(@"Invalid URL: %@", urlString);
		addToLogIfEnabled(service, bulletin, @"Invalid URL");
		return;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];

	addToLogIfEnabled(service, bulletin, @"Method", method);
	[request setHTTPMethod:method];
	if (authType == PusherAuthorizationTypeHeader) {
		[request setValue:credentials[@"value"] forHTTPHeaderField:credentials[@"headerName"]];
		addToLogIfEnabled(service, bulletin, @"Header", Xstr(@"%@: %@", credentials[@"headerName"], credentials[@"value"]));
	}

	if (Xeq(method, @"POST")) {
		addToLogIfEnabled(service, bulletin, @"Request Body Dictionary", infoDictForRequest);
		[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		NSData *requestData = [NSJSONSerialization dataWithJSONObject:infoDictForRequest options:NSJSONWritingPrettyPrinted error:nil];
		[request setValue:Xstr(@"%lu", requestData.length) forHTTPHeaderField:@"Content-Length"];
		[request setHTTPBody:requestData];
	}

	//use async way to connect network
	[[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (data.length && error == nil) {
			addToLogIfEnabled(service, bulletin, @"Network Response: Success");
			XLog(@"%@ Success", logString);
			// XLog(@"data: %@", [[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "]);
		} else if (error) {
			addToLogIfEnabled(service, bulletin, @"Network Response: Error", error.description);
			XLog(@"%@ Error: %@", logString, error);
		} else {
			addToLogIfEnabled(service, bulletin, @"Network Response: No Data");
			XLog(@"%@ No data", logString);
		}
	}] resume];

}

// iOS 10 & 11
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(unsigned long long)arg2 alwaysToLockScreen:(BOOL)arg3 {
	%orig;
	if ([self respondsToSelector:@selector(sendBulletinToPusher:)]) {
		[self sendBulletinToPusher:bulletin];
	}
}

// iOS 12
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(unsigned long long)arg2 {
	%orig;
	if ([self respondsToSelector:@selector(sendBulletinToPusher:)]) {
		[self sendBulletinToPusher:bulletin];
	}
}

%end

%ctor {
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)pusherPrefsChanged, CFSTR(PUSHER_PREFS_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);
	pusherPrefsChanged();
	%init;
	[NSPTestPush load];
}
