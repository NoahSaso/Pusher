#import <Preferences/PSListController.h>

@interface NSPCustomAppController : PSListController {
  NSString *_service;
  NSString *_appID;
  BOOL _isCustomService;
}
- (id)initWithService:(NSString *)service appID:(NSString *)appID isCustomService:(BOOL)isCustomService;
@end
