#import <Preferences/PSListController.h>
#import "../global.h"

@interface NSPPSListControllerWithColoredUI : PSListController {
  UIColor *_priorTintColor;
}
- (void)setPusherUIColor:(UIColor *)color;
@end