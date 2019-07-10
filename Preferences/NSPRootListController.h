#import "NSPPSListControllerWithColoredUI.h"

@interface NSPRootListController : NSPPSListControllerWithColoredUI {
  UIColor *_priorTintColor;
}
- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest;
- (void)openTwitter:(NSString *)username;
@end
