#import "NSPRootListController.h"
#import "CCColorCube.h"

@interface NSPServiceController : NSPRootListController { // extend so can use twitter function
  NSString *_service;
  BOOL _isCustom;
  UIImage *_image;
  UIStackView *_imageTitleView;
  CCColorCube *_colorCube;
}
- (id)initWithService:(NSString *)service image:(UIImage *)image isCustom:(BOOL)isCustom;
- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest;
@end
