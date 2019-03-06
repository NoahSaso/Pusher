#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface NSPDeviceListController : PSListController {
  NSMutableDictionary *_pushoverDevices;
  NSDictionary *_prefs;
}
@end
