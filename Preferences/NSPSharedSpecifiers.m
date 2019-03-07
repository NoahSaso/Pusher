#import "NSPSharedSpecifiers.h"
#import "NSPDeviceListController.h"

@implementation NSPSharedSpecifiers

+ (NSArray *)pushover {
  PSSpecifier *devices = [PSSpecifier preferenceSpecifierNamed:@"Receiving Devices" target:nil set:nil get:nil detail:NSPDeviceListController.class cell:PSLinkCell edit:nil];
  return @[devices];
}

@end