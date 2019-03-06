#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSSpecifier (Pusher)
+ (id)emptyGroupSpecifier;
@end

@interface NSPDeviceListController : PSListController {
  NSMutableDictionary *_pushoverDevices;
  NSDictionary *_prefs;
  UIBarButtonItem *_updateBn;
  UIActivityIndicatorView *_activityIndicator;
  UIBarButtonItem *_activityIndicatorBn;
}
- (void)setPreferenceValue:(id)value forDeviceSpecifier:(PSSpecifier *)specifier;
- (id)readDevicePreferenceValue:(PSSpecifier *)specifier;
- (void)updateDevices;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
@end
