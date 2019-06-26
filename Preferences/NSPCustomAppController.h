#import "NSPPSListControllerWithColoredUI.h"

@interface NSPCustomAppController : NSPPSListControllerWithColoredUI {
  NSString *_service;
  NSString *_appID;
  NSString *_appTitle;
  BOOL _isCustomService;
}
- (id)initWithService:(NSString *)service appID:(NSString *)appID appTitle:(NSString *)appTitle isCustomService:(BOOL)isCustomService;
@end
