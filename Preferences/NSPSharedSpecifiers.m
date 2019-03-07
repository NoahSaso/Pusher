#import "NSPSharedSpecifiers.h"
#import "NSPDeviceListController.h"

#import "../global.h"
#import <Custom/defines.h>

@implementation NSPSharedSpecifiers

+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID {
  if (Xeq(service, @"Pushover")) {
    return [NSPSharedSpecifiers pushover:appID];
  }
  return @[];
}

+ (NSArray *)pushover:(NSString *)appID {
  PSSpecifier *devices = [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:nil set:nil get:nil detail:NSPDeviceListController.class cell:PSLinkCell edit:nil];
  [devices setProperty:@"Pushover" forKey:@"service"];
  BOOL isCustomApp = appID != nil;
  [devices setProperty:(isCustomApp ? @"PushoverCustomApps" : @"pushoverDevices") forKey:@"prefsKey"];
  [devices setProperty:[NSNumber numberWithBool:isCustomApp] forKey:@"isCustomApp"];
  if (isCustomApp) {
    [devices setProperty:appID forKey:@"customAppIDKey"];
  }
  return @[devices];
}

@end