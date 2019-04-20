#import "NSPSharedSpecifiers.h"
#import "NSPDeviceListController.h"
#import "NSPSoundListController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

static id getPreference(CFStringRef keyRef) {
  CFPropertyListRef val = CFPreferencesCopyValue(keyRef, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  return (__bridge id) val;
}

static void setPreference(CFStringRef keyRef, CFPropertyListRef val, BOOL shouldNotify) {
	CFPreferencesSetValue(keyRef, val, PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(PUSHER_APP_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (shouldNotify) {
    // Reload stuff
    notify_post("com.noahsaso.pusher/prefs");
  }
}

@implementation NSPSharedSpecifiers

+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID {
  if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
    return [NSPSharedSpecifiers pushover:appID];
  } else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
    return [NSPSharedSpecifiers pushbullet:appID];
  } else if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
    return [NSPSharedSpecifiers ifttt:appID];
  }
  return @[];
}

+ (NSArray *)get:(NSString *)service {
  return [NSPSharedSpecifiers get:service withAppID:nil];
}

+ (NSArray *)pushover:(NSString *)appID {
  PSSpecifier *devices = [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:nil set:nil get:nil detail:NSPDeviceListController.class cell:PSLinkCell edit:nil];
  PSSpecifier *sounds = [PSSpecifier preferenceSpecifierNamed:@"Notification Sound" target:nil set:nil get:nil detail:NSPSoundListController.class cell:PSLinkCell edit:nil];

  [devices setProperty:PUSHER_SERVICE_PUSHOVER forKey:@"service"];
  [sounds setProperty:PUSHER_SERVICE_PUSHOVER forKey:@"service"];

  BOOL isCustomApp = appID != nil;

  [devices setProperty:(isCustomApp ? NSPPreferencePushoverCustomAppsKey : NSPPreferencePushoverDevicesKey) forKey:@"prefsKey"];
  [sounds setProperty:(isCustomApp ? NSPPreferencePushoverCustomAppsKey : NSPPreferencePushoverSoundsKey) forKey:@"prefsKey"];

  [devices setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];
  [sounds setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];

  if (isCustomApp) {
    [devices setProperty:appID forKey:@"customAppIDKey"];
    [sounds setProperty:appID forKey:@"customAppIDKey"];
  }

  return @[devices, sounds];
}

+ (NSArray *)pushbullet:(NSString *)appID {
  PSSpecifier *devices = [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:nil set:nil get:nil detail:NSPDeviceListController.class cell:PSLinkCell edit:nil];
  [devices setProperty:PUSHER_SERVICE_PUSHBULLET forKey:@"service"];
  BOOL isCustomApp = appID != nil;
  [devices setProperty:(isCustomApp ? NSPPreferencePushbulletCustomAppsKey : NSPPreferencePushbulletDevicesKey) forKey:@"prefsKey"];
  [devices setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];
  if (isCustomApp) {
    [devices setProperty:appID forKey:@"customAppIDKey"];
  }
  return @[devices];
}

+ (NSArray *)ifttt:(NSString *)appID {
  BOOL isCustomApp = appID != nil;

  PSSpecifier *eventName = [PSSpecifier preferenceSpecifierNamed:@"Event Name" target:self set:@selector(setPreferenceValue:forIFTTTSpecifier:) get:@selector(readIFTTTPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [eventName setProperty:NSPPreferenceIFTTTEventNameKey forKey:@"key"];
  [eventName setProperty:@YES forKey:@"enabled"];
  [eventName setProperty:@YES forKey:@"noAutoCorrect"];
  [eventName setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];
  [eventName setProperty:NSPPreferenceIFTTTCustomAppsKey forKey:@"customAppsKey"];
  [eventName setProperty:@"eventName" forKey:@"customAppsPrefsKey"];

  PSSpecifier *includeIcon = [PSSpecifier preferenceSpecifierNamed:@"Include Icon" target:self set:@selector(setPreferenceValue:forIFTTTSpecifier:) get:@selector(readIFTTTPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeIcon setProperty:NSPPreferenceIFTTTIncludeIconKey forKey:@"key"];
  [includeIcon setProperty:@YES forKey:@"enabled"];
  [includeIcon setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];
  [includeIcon setProperty:NSPPreferenceIFTTTCustomAppsKey forKey:@"customAppsKey"];
  [includeIcon setProperty:@"includeIcon" forKey:@"customAppsPrefsKey"];

  if (isCustomApp) {
    [eventName setProperty:appID forKey:@"customAppID"];
    [includeIcon setProperty:appID forKey:@"customAppID"];
  }

  return @[eventName, includeIcon];
}

+ (void)setPreferenceValue:(id)value forIFTTTSpecifier:(PSSpecifier *)specifier {
  BOOL isCustomApp = ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
  if (isCustomApp) {
		NSMutableDictionary *customApps = [(NSDictionary *)getPreference((__bridge CFStringRef) [specifier propertyForKey:@"customAppsKey"]) mutableCopy];
		NSMutableDictionary *customApp = [(customApps[[specifier propertyForKey:@"customAppID"]] ?: @{}) mutableCopy];
    customApp[[specifier propertyForKey:@"customAppsPrefsKey"]] = value;
		customApps[[specifier propertyForKey:@"customAppID"]] = customApp;
		setPreference((__bridge CFStringRef) [specifier propertyForKey:@"customAppsKey"], (__bridge CFPropertyListRef) customApps, YES);
	} else {
		setPreference((__bridge CFStringRef) [specifier propertyForKey:@"key"], (__bridge CFPropertyListRef) value, YES);
	}
}

+ (id)readIFTTTPreferenceValue:(PSSpecifier *)specifier {
  BOOL isCustomApp = ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
	if (isCustomApp) {
    NSMutableDictionary *customApps = [(NSDictionary *)getPreference((__bridge CFStringRef) [specifier propertyForKey:@"customAppsKey"]) mutableCopy];
		NSMutableDictionary *customApp = [(customApps[[specifier propertyForKey:@"customAppID"]] ?: @{}) mutableCopy];
    return customApp[[specifier propertyForKey:@"customAppsPrefsKey"]];
  }
  return getPreference((__bridge CFStringRef) [specifier propertyForKey:@"key"]);
}

@end
