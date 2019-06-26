#import "NSPPSListControllerWithColoredUI.h"
#import "../global.h"

@interface NSPSoundListController : NSPPSListControllerWithColoredUI {
  NSMutableArray *_serviceSounds;
  NSDictionary *_prefs;
  UIBarButtonItem *_updateBn;
  UIActivityIndicatorView *_activityIndicator;
  UIBarButtonItem *_activityIndicatorBn;
  NSString *_prefsKey;
  NSString *_service;
  BOOL _isCustomApp;
  NSString *_customAppIDKey;
}
- (void)setPreferenceValue:(id)value forSoundSpecifier:(PSSpecifier *)specifier;
- (id)readSoundPreferenceValue:(PSSpecifier *)specifier;
- (void)updateSounds;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
- (void)updatePushoverSounds;
- (void)updatePushbulletSounds;
- (void)saveServiceSounds;
- (NSArray *)sortedSoundList:(NSArray *)sounds;
@end
