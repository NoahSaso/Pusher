#import <Preferences/PSListController.h>

@interface NSPCustomAppController : PSListController {
  NSString *_service;
  NSString *_appID;
}
- (id)initWithService:(NSString *)service appID:(NSString *)appID;
@end
