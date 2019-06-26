#import <Preferences/PSListController.h>
#import "../global.h"
#import <Custom/defines.h>

@interface NSPPSListControllerWithColoredUI : PSListController {
  UIColor *_priorTintColor;
}
- (void)setPusherUIColor:(UIColor *)color override:(BOOL)override;
@end