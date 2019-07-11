#import "NSPPSListControllerWithColoredUI.h"

@interface NSPRootListController : NSPPSListControllerWithColoredUI {
  UIColor *_priorTintColor;
}
- (void)openTwitter:(NSString *)username;
@end
