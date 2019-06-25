#import <Preferences/PSListController.h>

@interface NSPServiceController : PSListController {
  NSString *_service;
  BOOL _isCustom;
  UIImage *_image;
  UIStackView *_imageTitleView;
}
- (id)initWithService:(NSString *)service image:(UIImage *)image isCustom:(BOOL)isCustom;
- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest;
@end
