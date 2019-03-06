#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSListController (Pusher)
- (BOOL)performActionForSpecifier:(PSSpecifier *)arg1;
@end

@interface NSPRootListController : PSListController {
  BOOL _pushoverHasDevices;
  NSDictionary *_prefs;
}
- (PSSpecifier *)generateDeviceLinkSpecifier;
- (PSSpecifier *)addDeviceLinkSpecifier;
@end
