#import "NSPPSListControllerWithColoredUI.h"

@interface NSPRootListController : NSPPSListControllerWithColoredUI {
  UIColor *_priorTintColor;
  UIImageView *_headerImageView;
  UIView *_headerContainer;
  BOOL _showingHeader;
}
- (void)updateHeader;
@end
