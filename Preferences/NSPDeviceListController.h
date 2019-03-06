#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSSpecifier (Pusher)
+ (id)emptyGroupSpecifier;
@end

@interface NSPDeviceListController : PSListController {
  NSMutableDictionary *_pushoverDevices;
  NSDictionary *_prefs;
}
- (void)setPreferenceValue:(id)value forDeviceSpecifier:(PSSpecifier *)specifier;
- (id)readDevicePreferenceValue:(PSSpecifier *)specifier;
- (void)updateDevices;
@end
