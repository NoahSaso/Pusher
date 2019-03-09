#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSSpecifier (Pusher)
+ (id)emptyGroupSpecifier;
@end

@interface NSPDeviceListController : PSListController {
  NSMutableDictionary *_serviceDevices;
  NSDictionary *_prefs;
  UIBarButtonItem *_updateBn;
  UIActivityIndicatorView *_activityIndicator;
  UIBarButtonItem *_activityIndicatorBn;
  NSString *_prefsKey;
  NSString *_service;
  BOOL _isCustomApp;
  NSString *_customAppIDKey;
}
- (void)setPreferenceValue:(id)value forDeviceSpecifier:(PSSpecifier *)specifier;
- (id)readDevicePreferenceValue:(PSSpecifier *)specifier;
- (void)updateDevices;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
- (void)updatePushoverDevices;
- (void)updatePushbulletDevices;
- (void)saveServiceDevices;
@end
