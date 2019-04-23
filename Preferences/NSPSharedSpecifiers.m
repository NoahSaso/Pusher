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

+ (NSArray *)getCustomForService:(NSString *)service withAppID:(NSString *)appID ref:(PSListController *)listController {
  BOOL isCustomApp = appID != nil;

  NSArray *specifiers = [listController loadSpecifiersFromPlistName:@"Custom" target:listController];

  // // endpoint group
  // PSSpecifier *endpointGroup = [PSSpecifier groupSpecifierWithName:@"Endpoint"];
  // // endpoint url
  // PSSpecifier *endpointURL = [PSSpecifier preferenceSpecifierNamed:@"URL" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  // [endpointURL setProperty:@"url" forKey:@"key"];
  // [endpointURL setProperty:@YES forKey:@"noAutoCorrect"];
  // // endpoint method
  // PSSpecifier *endpointMethod = [PSSpecifier preferenceSpecifierNamed:@"Method" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSSegmentCell edit:nil];
  // [endpointMethod setProperty:@"method" forKey:@"key"];
  // [endpointMethod setProperty:@"GET" forKey:@"default"];
  // NSArray *methods = @[@"GET", @"POST"];
  // [endpointMethod setProperty:methods forKey:@"validTitles"];
  // [endpointMethod setProperty:methods forKey:@"validValues"];

  // // options group
  // PSSpecifier *optionsGroup = [PSSpecifier groupSpecifierWithName:@"Options"];
  // NSString *optionsFooterText = @"The following properties will be passed to the URL endpoint (via GET or POST parameters) specified above (property names in parentheses) [Must Turn on \"Include Icon\" switch above in order to get the icon property]:\nApp Name (appName), App Bundle ID (appID), Title (title), Subtitle (subtitle), Message (message), Date (date), Base64 Encoded PNG Icon 58x58 (icon)";
  // [optionsGroup setProperty:optionsFooterText forKey:@"footerText"];
  // // app customization list

  // // app blacklist

  // // include icon switch
  // PSSpecifier *includeIcon = [PSSpecifier preferenceSpecifierNamed:@"Include Icon" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  // [includeIcon setProperty:@"includeIcon" forKey:@"key"];

  // // date format group
  // PSSpecifier *dateFormatGroup = [PSSpecifier groupSpecifierWithName:@"Options"];
  // NSString *dateFormatFooterText = @"INSTRUCTIONS:\n1. Click 'Open Date Format Instructions' above (https://nsdateformatter.com).\n2. Using the reference and examples, create your desired date format and enter it above. If you don't care about the date, you may leave it as the default\n\nExample formats for Saturday, April 13, 2019 @ 3:12 AM:\nEEEE, MMM d, yyyy = Saturday, Apr 13, 2019\nMM/dd/yyyy = 04/13/2019\nMM-dd-yyyy HH:mm = 04-13-2019 03:12\nMMM d, h:mm a = Apr 13, 3:12 AM\nE, d MMM yyyy HH:mm:ss Z = Sat, 13 Apr 2019 03:12:11 +0000\nyyyy-MM-dd'T'HH:mm:ssZ = 2019-04-13T03:12:11+0000\ndd.MM.yy = 13.04.19\nHH:mm:ss.SSS = 03:12:11.678";
  // [dateFormatGroup setProperty:dateFormatFooterText forKey:@"footerText"];
  // // open date format instructions button

  // // date format input

  // NSArray *specifiers = @[
  //   endpointGroup,
  //   endpointURL,
  //   endpointMethod,

  //   optionsGroup,
  //   appCustomization,
  //   appBlacklist,
  //   includeIcon,

  //   dateFormatGroup,
  //   openDateFormatInstructions,
  //   dateFormat
  // ];

  for (PSSpecifier *specifier in specifiers) {
    if (specifier.cellType == 0) { // don't set these properties on group specifiers
      continue;
    }
    [specifier setProperty:@YES forKey:@"enabled"];
    [specifier setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];
    [specifier setProperty:service forKey:@"service"];
    if (isCustomApp) {
      [specifier setProperty:appID forKey:@"customAppID"];
    }
  }

  return specifiers;
}

+ (NSArray *)getCustomForService:(NSString *)service ref:(PSListController *)listController {
  return [NSPSharedSpecifiers getCustomForService:service withAppID:nil ref:listController];
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
    NSDictionary *customApps = getPreference((__bridge CFStringRef) [specifier propertyForKey:@"customAppsKey"]) ?: @{};
		NSDictionary *customApp = customApps[[specifier propertyForKey:@"customAppID"]] ?: @{};
    return customApp[[specifier propertyForKey:@"customAppsPrefsKey"]];
  }
  return getPreference((__bridge CFStringRef) [specifier propertyForKey:@"key"]);
}

+ (void)setPreferenceValue:(id)value forCustomSpecifier:(PSSpecifier *)specifier {
  BOOL isCustomApp = ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
  NSString *service = [specifier propertyForKey:@"service"];
  NSMutableDictionary *customServices = [(NSDictionary *)(getPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey) ?: @{}) mutableCopy];
  if (isCustomApp) {
		NSMutableDictionary *customApps = [(NSDictionary *) (customServices[service] ?: @{})[NSPPreferenceCustomServiceCustomAppsKey] mutableCopy];
		NSMutableDictionary *customApp = [(customApps[[specifier propertyForKey:@"customAppID"]] ?: @{}) mutableCopy];
    customApp[[specifier propertyForKey:@"key"]] = value;
		customApps[[specifier propertyForKey:@"customAppID"]] = customApp;
    customServices[service][NSPPreferenceCustomServiceCustomAppsKey] = customApps;
	} else {
    customServices[service][[specifier propertyForKey:@"key"]] = value;
  }
  setPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey, (__bridge CFPropertyListRef) customServices, YES);
}

+ (id)readCustomPreferenceValue:(PSSpecifier *)specifier {
  BOOL isCustomApp = ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
  NSString *service = [specifier propertyForKey:@"service"];
  NSDictionary *customServices = getPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey) ?: @{};
	if (isCustomApp) {
    NSDictionary *customApps = (customServices[service] ?: @{})[NSPPreferenceCustomServiceCustomAppsKey] ?: @{};
		NSDictionary *customApp = customApps[[specifier propertyForKey:@"customAppID"]] ?: @{};
    return customApp[[specifier propertyForKey:@"key"]];
  }
  return customServices[service][[specifier propertyForKey:@"key"]];
}

@end
