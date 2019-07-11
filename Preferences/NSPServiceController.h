#import "NSPPSListControllerWithColoredUI.h"
#import "CCColorCube.h"
#import <UserNotifications/UserNotifications.h>

@interface NSPServiceController : NSPPSListControllerWithColoredUI <UNUserNotificationCenterDelegate> { // extend so can use twitter function
  NSString *_service;
  BOOL _isCustom;
  UIImage *_image;
  UIStackView *_imageTitleView;
  CCColorCube *_colorCube;
  UIColor *_uiColor;
}
- (id)initWithService:(NSString *)service image:(UIImage *)image isCustom:(BOOL)isCustom;
- (void)displayNotification:(NSString *)message;
- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest;
@end
