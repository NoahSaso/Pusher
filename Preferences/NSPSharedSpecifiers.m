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
    notify_post(PUSHER_PREFS_NOTIFICATION);
  }
}

@implementation NSPSharedSpecifiers

+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID isCustomService:(BOOL)isCustomService {
  if (isCustomService) {
    return [NSPSharedSpecifiers getCustomShared:service withAppID:appID];
  }
  if (Xeq(service, PUSHER_SERVICE_PUSHOVER)) {
    return [NSPSharedSpecifiers pushover:appID];
  } else if (Xeq(service, PUSHER_SERVICE_PUSHBULLET)) {
    return [NSPSharedSpecifiers pushbullet:appID];
  } else if (Xeq(service, PUSHER_SERVICE_IFTTT)) {
    return [NSPSharedSpecifiers ifttt:appID];
  } else if (Xeq(service, PUSHER_SERVICE_PUSHER_RECEIVER)) {
    return [NSPSharedSpecifiers pusherReceiver:appID];
  }
  return @[];
}

// get for main service prefs, not custom app
+ (NSArray *)get:(NSString *)service {
  return [NSPSharedSpecifiers get:service withAppID:nil isCustomService:NO];
}

+ (NSArray *)getCustom:(NSString *)service ref:(PSListController *)listController {
  NSArray *specifiers = [listController loadSpecifiersFromPlistName:@"Custom" target:listController];

  NSArray *specialCells = @[@(PSGroupCell), @(PSButtonCell), @(PSLinkCell)];

  for (PSSpecifier *specifier in specifiers) {
    [specifier setProperty:service forKey:@"service"];
    if ([specialCells containsObject:@(specifier.cellType)]) { // don't set these properties on group specifiers
      if (Xeq(specifier.name, @"App List")) {
        [specifier setProperty:NSPPreferenceCustomServiceBLPrefix(service) forKey:@"ALSettingsKeyPrefix"];
      } else if (Xeq(specifier.name, @"App Customization")) {
        [specifier setProperty:service forKey:@"service"];
      }
      continue;
    }
    [specifier setProperty:@YES forKey:@"enabled"];
    [specifier setProperty:@NO forKey:@"isCustomApp"];
    specifier->setter = @selector(setPreferenceValue:forCustomSpecifier:);
    specifier->getter = @selector(readCustomPreferenceValue:);
    specifier->target = self;
  }

  return specifiers;
}

+ (NSArray *)getCustomShared:(NSString *)service withAppID:(NSString *)appID {
  BOOL isCustomApp = appID != nil;

  PSSpecifier *includeIcon = [PSSpecifier preferenceSpecifierNamed:@"Include Icon" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeIcon setProperty:@"includeIcon" forKey:@"key"];
  [includeIcon setProperty:@YES forKey:@"enabled"];
  [includeIcon setProperty:@NO forKey:@"default"];
  [includeIcon setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [includeIcon setProperty:service forKey:@"service"];

  PSSpecifier *includeImage = [PSSpecifier preferenceSpecifierNamed:@"Include Image" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeImage setProperty:@"includeImage" forKey:@"key"];
  [includeImage setProperty:@YES forKey:@"enabled"];
  [includeImage setProperty:@NO forKey:@"default"];
  [includeImage setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [includeImage setProperty:service forKey:@"service"];

  PSSpecifier *imageMaxWidth = [PSSpecifier preferenceSpecifierNamed:@"Maximum Image Width (pixels)" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageMaxWidth setProperty:@"imageMaxWidth" forKey:@"key"];
  [imageMaxWidth setProperty:@YES forKey:@"enabled"];
  [imageMaxWidth setProperty:@YES forKey:@"isDecimalPad"];
  [imageMaxWidth setProperty:@(PUSHER_DEFAULT_MAX_WIDTH) forKey:@"default"];
  [imageMaxWidth setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageMaxWidth setProperty:service forKey:@"service"];

  PSSpecifier *imageMaxHeight = [PSSpecifier preferenceSpecifierNamed:@"Maximum Image Height (pixels)" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageMaxHeight setProperty:@"imageMaxHeight" forKey:@"key"];
  [imageMaxHeight setProperty:@YES forKey:@"enabled"];
  [imageMaxHeight setProperty:@YES forKey:@"isDecimalPad"];
  [imageMaxHeight setProperty:@(PUSHER_DEFAULT_MAX_HEIGHT) forKey:@"default"];
  [imageMaxHeight setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageMaxHeight setProperty:service forKey:@"service"];

  PSSpecifier *imageShrinkFactor = [PSSpecifier preferenceSpecifierNamed:@"Image Shrink Factor Upon Retry" target:self set:@selector(setPreferenceValue:forCustomSpecifier:) get:@selector(readCustomPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageShrinkFactor setProperty:@"imageShrinkFactor" forKey:@"key"];
  [imageShrinkFactor setProperty:@YES forKey:@"enabled"];
  [imageShrinkFactor setProperty:@YES forKey:@"isDecimalPad"];
  [imageShrinkFactor setProperty:@(PUSHER_DEFAULT_SHRINK_FACTOR) forKey:@"default"];
  [imageShrinkFactor setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageShrinkFactor setProperty:service forKey:@"service"];

  if (isCustomApp) {
    [includeIcon setProperty:appID forKey:@"customAppID"];
    [includeImage setProperty:appID forKey:@"customAppID"];
    [imageMaxWidth setProperty:appID forKey:@"customAppID"];
    [imageMaxHeight setProperty:appID forKey:@"customAppID"];
    [imageShrinkFactor setProperty:appID forKey:@"customAppID"];
  }

  return @[includeIcon, includeImage, imageMaxWidth, imageMaxHeight, imageShrinkFactor];
}

+ (NSArray *)getCustomShared:(NSString *)service {
  return [NSPSharedSpecifiers getCustomShared:service withAppID:nil];
}

+ (NSArray *)pushover:(NSString *)appID {
  PSSpecifier *devices = [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:nil set:nil get:nil detail:NSPDeviceListController.class cell:PSLinkCell edit:nil];
  PSSpecifier *sounds = [PSSpecifier preferenceSpecifierNamed:@"Notification Sound" target:nil set:nil get:nil detail:NSPSoundListController.class cell:PSLinkCell edit:nil];

  [devices setProperty:PUSHER_SERVICE_PUSHOVER forKey:@"service"];
  [sounds setProperty:PUSHER_SERVICE_PUSHOVER forKey:@"service"];

  BOOL isCustomApp = appID != nil;

  [devices setProperty:(isCustomApp ? NSPPreferencePushoverCustomAppsKey : NSPPreferencePushoverDevicesKey) forKey:@"prefsKey"];
  [sounds setProperty:(isCustomApp ? NSPPreferencePushoverCustomAppsKey : NSPPreferencePushoverSoundsKey) forKey:@"prefsKey"];

  [devices setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [sounds setProperty:@(isCustomApp) forKey:@"isCustomApp"];
    
  PSSpecifier *includeImage = [PSSpecifier preferenceSpecifierNamed:@"Include Image" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeImage setProperty:NSPPreferencePushoverIncludeImageKey forKey:@"key"];
  [includeImage setProperty:@YES forKey:@"enabled"];
  [includeImage setProperty:@YES forKey:@"default"];
  [includeImage setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [includeImage setProperty:NSPPreferencePushoverCustomAppsKey forKey:@"customAppsKey"];
  [includeImage setProperty:@"includeImage" forKey:@"customAppsPrefsKey"];

  PSSpecifier *imageMaxWidth = [PSSpecifier preferenceSpecifierNamed:@"Maximum Image Width (pixels)" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageMaxWidth setProperty:NSPPreferencePushoverImageMaxWidthKey forKey:@"key"];
  [imageMaxWidth setProperty:@YES forKey:@"enabled"];
  [imageMaxWidth setProperty:@YES forKey:@"isDecimalPad"];
  [imageMaxWidth setProperty:@(PUSHER_DEFAULT_MAX_WIDTH) forKey:@"default"];
  [imageMaxWidth setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageMaxWidth setProperty:NSPPreferencePushoverCustomAppsKey forKey:@"customAppsKey"];
  [imageMaxWidth setProperty:@"imageMaxWidth" forKey:@"customAppsPrefsKey"];

  PSSpecifier *imageMaxHeight = [PSSpecifier preferenceSpecifierNamed:@"Maximum Image Height (pixels)" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageMaxHeight setProperty:NSPPreferencePushoverImageMaxHeightKey forKey:@"key"];
  [imageMaxHeight setProperty:@YES forKey:@"enabled"];
  [imageMaxHeight setProperty:@YES forKey:@"isDecimalPad"];
  [imageMaxHeight setProperty:@(PUSHER_DEFAULT_MAX_HEIGHT) forKey:@"default"];
  [imageMaxHeight setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageMaxHeight setProperty:NSPPreferencePushoverCustomAppsKey forKey:@"customAppsKey"];
  [imageMaxHeight setProperty:@"imageMaxHeight" forKey:@"customAppsPrefsKey"];

  PSSpecifier *imageShrinkFactor = [PSSpecifier preferenceSpecifierNamed:@"Image Shrink Factor Upon Retry" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageShrinkFactor setProperty:NSPPreferencePushoverImageShrinkFactorKey forKey:@"key"];
  [imageShrinkFactor setProperty:@YES forKey:@"enabled"];
  [imageShrinkFactor setProperty:@YES forKey:@"isDecimalPad"];
  [imageShrinkFactor setProperty:@(PUSHER_DEFAULT_SHRINK_FACTOR) forKey:@"default"];
  [imageShrinkFactor setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageShrinkFactor setProperty:NSPPreferencePushoverCustomAppsKey forKey:@"customAppsKey"];
  [imageShrinkFactor setProperty:@"imageShrinkFactor" forKey:@"customAppsPrefsKey"];

  if (isCustomApp) {
    [devices setProperty:appID forKey:@"customAppIDKey"];
    [sounds setProperty:appID forKey:@"customAppIDKey"];
    [includeImage setProperty:appID forKey:@"customAppID"];
    [imageMaxWidth setProperty:appID forKey:@"customAppID"];
    [imageMaxHeight setProperty:appID forKey:@"customAppID"];
    [imageShrinkFactor setProperty:appID forKey:@"customAppID"];
  }

  return @[devices, sounds, includeImage, imageMaxWidth, imageMaxHeight, imageShrinkFactor];
}

+ (NSArray *)pushbullet:(NSString *)appID {
  PSSpecifier *devices = [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:nil set:nil get:nil detail:NSPDeviceListController.class cell:PSLinkCell edit:nil];
  [devices setProperty:PUSHER_SERVICE_PUSHBULLET forKey:@"service"];
  BOOL isCustomApp = appID != nil;
  [devices setProperty:(isCustomApp ? NSPPreferencePushbulletCustomAppsKey : NSPPreferencePushbulletDevicesKey) forKey:@"prefsKey"];
  [devices setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  if (isCustomApp) {
    [devices setProperty:appID forKey:@"customAppIDKey"];
  }
  return @[devices];
}

+ (NSArray *)ifttt:(NSString *)appID {
  BOOL isCustomApp = appID != nil;

  PSSpecifier *eventName = [PSSpecifier preferenceSpecifierNamed:@"Event Name" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [eventName setProperty:NSPPreferenceIFTTTEventNameKey forKey:@"key"];
  [eventName setProperty:@YES forKey:@"enabled"];
  [eventName setProperty:@YES forKey:@"noAutoCorrect"];
  [eventName setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [eventName setProperty:NSPPreferenceIFTTTCustomAppsKey forKey:@"customAppsKey"];
  [eventName setProperty:@"eventName" forKey:@"customAppsPrefsKey"];

  PSSpecifier *includeIcon = [PSSpecifier preferenceSpecifierNamed:@"Include Icon" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeIcon setProperty:NSPPreferenceIFTTTIncludeIconKey forKey:@"key"];
  [includeIcon setProperty:@YES forKey:@"enabled"];
  [includeIcon setProperty:@NO forKey:@"default"];
  [includeIcon setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [includeIcon setProperty:NSPPreferenceIFTTTCustomAppsKey forKey:@"customAppsKey"];
  [includeIcon setProperty:@"includeIcon" forKey:@"customAppsPrefsKey"];

  PSSpecifier *curateData = [PSSpecifier preferenceSpecifierNamed:@"Curate Request Data" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [curateData setProperty:NSPPreferenceIFTTTCurateDataKey forKey:@"key"];
  [curateData setProperty:@YES forKey:@"enabled"];
  [curateData setProperty:@YES forKey:@"default"];
  [curateData setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [curateData setProperty:NSPPreferenceIFTTTCustomAppsKey forKey:@"customAppsKey"];
  [curateData setProperty:@"curateData" forKey:@"customAppsPrefsKey"];

  if (isCustomApp) {
    [eventName setProperty:appID forKey:@"customAppID"];
    [includeIcon setProperty:appID forKey:@"customAppID"];
    [curateData setProperty:appID forKey:@"customAppID"];
  }

  return @[eventName, includeIcon, curateData];
}

+ (NSArray *)pusherReceiver:(NSString *)appID {
  BOOL isCustomApp = appID != nil;

  PSSpecifier *includeIcon = [PSSpecifier preferenceSpecifierNamed:@"Include Icon" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeIcon setProperty:NSPPreferencePusherReceiverIncludeIconKey forKey:@"key"];
  [includeIcon setProperty:@YES forKey:@"enabled"];
  [includeIcon setProperty:@YES forKey:@"default"];
  [includeIcon setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [includeIcon setProperty:NSPPreferencePusherReceiverCustomAppsKey forKey:@"customAppsKey"];
  [includeIcon setProperty:@"includeIcon" forKey:@"customAppsPrefsKey"];

  PSSpecifier *includeImage = [PSSpecifier preferenceSpecifierNamed:@"Include Image" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
  [includeImage setProperty:NSPPreferencePusherReceiverIncludeImageKey forKey:@"key"];
  [includeImage setProperty:@YES forKey:@"enabled"];
  [includeImage setProperty:@YES forKey:@"default"];
  [includeImage setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [includeImage setProperty:NSPPreferencePusherReceiverCustomAppsKey forKey:@"customAppsKey"];
  [includeImage setProperty:@"includeImage" forKey:@"customAppsPrefsKey"];

  PSSpecifier *imageMaxWidth = [PSSpecifier preferenceSpecifierNamed:@"Maximum Image Width (pixels)" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageMaxWidth setProperty:NSPPreferencePusherReceiverImageMaxWidthKey forKey:@"key"];
  [imageMaxWidth setProperty:@YES forKey:@"enabled"];
  [imageMaxWidth setProperty:@YES forKey:@"isDecimalPad"];
  [imageMaxWidth setProperty:@(PUSHER_DEFAULT_MAX_WIDTH) forKey:@"default"];
  [imageMaxWidth setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageMaxWidth setProperty:NSPPreferencePusherReceiverCustomAppsKey forKey:@"customAppsKey"];
  [imageMaxWidth setProperty:@"imageMaxWidth" forKey:@"customAppsPrefsKey"];

  PSSpecifier *imageMaxHeight = [PSSpecifier preferenceSpecifierNamed:@"Maximum Image Height (pixels)" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageMaxHeight setProperty:NSPPreferencePusherReceiverImageMaxHeightKey forKey:@"key"];
  [imageMaxHeight setProperty:@YES forKey:@"enabled"];
  [imageMaxHeight setProperty:@YES forKey:@"isDecimalPad"];
  [imageMaxHeight setProperty:@(PUSHER_DEFAULT_MAX_HEIGHT) forKey:@"default"];
  [imageMaxHeight setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageMaxHeight setProperty:NSPPreferencePusherReceiverCustomAppsKey forKey:@"customAppsKey"];
  [imageMaxHeight setProperty:@"imageMaxHeight" forKey:@"customAppsPrefsKey"];

  PSSpecifier *imageShrinkFactor = [PSSpecifier preferenceSpecifierNamed:@"Image Shrink Factor Upon Retry" target:self set:@selector(setPreferenceValue:forBuiltInServiceSpecifier:) get:@selector(readBuiltInServicePreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
  [imageShrinkFactor setProperty:NSPPreferencePusherReceiverImageShrinkFactorKey forKey:@"key"];
  [imageShrinkFactor setProperty:@YES forKey:@"enabled"];
  [imageShrinkFactor setProperty:@YES forKey:@"isDecimalPad"];
  [imageShrinkFactor setProperty:@(PUSHER_DEFAULT_SHRINK_FACTOR) forKey:@"default"];
  [imageShrinkFactor setProperty:@(isCustomApp) forKey:@"isCustomApp"];
  [imageShrinkFactor setProperty:NSPPreferencePusherReceiverCustomAppsKey forKey:@"customAppsKey"];
  [imageShrinkFactor setProperty:@"imageShrinkFactor" forKey:@"customAppsPrefsKey"];

  if (isCustomApp) {
    [includeIcon setProperty:appID forKey:@"customAppID"];
    [includeImage setProperty:appID forKey:@"customAppID"];
    [imageMaxWidth setProperty:appID forKey:@"customAppID"];
    [imageMaxHeight setProperty:appID forKey:@"customAppID"];
    [imageShrinkFactor setProperty:appID forKey:@"customAppID"];
  }

  return @[includeIcon, includeImage, imageMaxWidth, imageMaxHeight, imageShrinkFactor];
}

+ (void)setPreferenceValue:(id)value forBuiltInServiceSpecifier:(PSSpecifier *)specifier {
  BOOL isCustomApp = [specifier propertyForKey:@"isCustomApp"] && ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
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

+ (id)readBuiltInServicePreferenceValue:(PSSpecifier *)specifier {
  BOOL isCustomApp = [specifier propertyForKey:@"isCustomApp"] && ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
	if (isCustomApp) {
    NSDictionary *customApps = getPreference((__bridge CFStringRef) [specifier propertyForKey:@"customAppsKey"]) ?: @{};
		NSDictionary *customApp = customApps[[specifier propertyForKey:@"customAppID"]] ?: @{};
    return customApp[[specifier propertyForKey:@"customAppsPrefsKey"]];
  }
  id value = getPreference((__bridge CFStringRef) [specifier propertyForKey:@"key"]);
  NSString *globalKey = [specifier propertyForKey:@"globalKey"];
  if (!value && globalKey) {
    value = getPreference((__bridge CFStringRef) globalKey);
  }
  return value ?: [specifier propertyForKey:@"default"];
}

+ (void)setPreferenceValue:(id)value forCustomSpecifier:(PSSpecifier *)specifier {
  BOOL isCustomApp = [specifier propertyForKey:@"isCustomApp"] && ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
  NSString *service = [specifier propertyForKey:@"service"];
  if (isCustomApp) {
    NSMutableDictionary *customApps = [(NSDictionary *)getPreference((__bridge CFStringRef) NSPPreferenceCustomServiceCustomAppsKey(service)) mutableCopy];
		NSMutableDictionary *customApp = [(customApps[[specifier propertyForKey:@"customAppID"]] ?: @{}) mutableCopy];
    customApp[[specifier propertyForKey:@"key"]] = value;
		customApps[[specifier propertyForKey:@"customAppID"]] = customApp;
		setPreference((__bridge CFStringRef) NSPPreferenceCustomServiceCustomAppsKey(service), (__bridge CFPropertyListRef) customApps, YES);
	} else {
    NSMutableDictionary *customServices = [(getPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey) ?: @{}) mutableCopy];
    NSMutableDictionary *customService = [(customServices[service] ?: @{}) mutableCopy];
    if (value) {
      customService[[specifier propertyForKey:@"key"]] = value;
    } else {
      [customService removeObjectForKey:[specifier propertyForKey:@"key"]];
    }
    customServices[service] = customService;
    setPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey, (__bridge CFPropertyListRef) customServices, YES);
  }
}

+ (id)readCustomPreferenceValue:(PSSpecifier *)specifier {
  BOOL isCustomApp = [specifier propertyForKey:@"isCustomApp"] && ((NSNumber *)[specifier propertyForKey:@"isCustomApp"]).boolValue;
  NSString *service = [specifier propertyForKey:@"service"];
	if (isCustomApp) {
    NSDictionary *customApps = getPreference((__bridge CFStringRef) NSPPreferenceCustomServiceCustomAppsKey(service)) ?: @{};
		NSDictionary *customApp = customApps[[specifier propertyForKey:@"customAppID"]] ?: @{};
    return customApp[[specifier propertyForKey:@"key"]];
  }
  NSDictionary *customServices = getPreference((__bridge CFStringRef) NSPPreferenceCustomServicesKey) ?: @{};
  id d = [specifier propertyForKey:@"default"];
  if (!customServices[service]) {
    return d;
  } else {
    id value = customServices[service][[specifier propertyForKey:@"key"]];
    NSString *globalKey = [specifier propertyForKey:@"globalKey"];
    if (!value && globalKey) {
      value = getPreference((__bridge CFStringRef) globalKey);
    }
    return value ?: d;
  }
}

@end
