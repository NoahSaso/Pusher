#import "NSPPSListControllerWithColoredUI.h"
#import "../global.h"
#import "../helpers.h"

@interface NSPSNSListController : NSPPSListControllerWithColoredUI {
  NSString *_service;
  BOOL _isCustomService;
  BOOL _isService;
  PSSpecifier *_synchronizeSpecifier;
}
@end
