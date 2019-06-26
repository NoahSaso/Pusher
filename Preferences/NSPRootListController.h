#import <Preferences/PSListController.h>

@interface NSPRootListController : PSListController {
  UIColor *_priorBarTintColor;
  UIColor *_priorTintColor;
}
- (void)openTwitter:(NSString *)username;
@end
