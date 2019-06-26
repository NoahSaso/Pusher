#import "NSPPSListControllerWithColoredUI.h"
#import "../global.h"

@interface NSPDeviceListController : NSPPSListControllerWithColoredUI {
  NSMutableArray *_serviceDevices;
  NSDictionary *_prefs;
  UIBarButtonItem *_updateBn;
  UIActivityIndicatorView *_activityIndicator;
  UIBarButtonItem *_activityIndicatorBn;
  NSString *_prefsKey;
  NSString *_service;
  BOOL _isCustomApp;
  NSString *_customAppIDKey;
  BOOL _onlyAllowOne;
}
- (void)setPreferenceValue:(id)value forDeviceSpecifier:(PSSpecifier *)specifier;
- (id)readDevicePreferenceValue:(PSSpecifier *)specifier;
- (void)updateDevices;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
- (void)updatePushoverDevices;
- (void)updatePushbulletDevices;
- (void)saveServiceDevices;
- (NSArray *)sortedDeviceList:(NSArray *)devices;
@end
