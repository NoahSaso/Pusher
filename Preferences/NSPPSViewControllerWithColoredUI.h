#import <Preferences/PSViewController.h>
#import "../global.h"

@interface NSPPSViewControllerWithColoredUI : PSViewController {
  UIColor *_priorTintColor;
}
- (void)setPusherUIColor:(UIColor *)color;
@end