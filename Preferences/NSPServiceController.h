#import <Preferences/PSListController.h>

@interface NSPServiceController : PSListController {
  NSString *_service;
}
- (id)initWithService:(NSString *)service;
@end
