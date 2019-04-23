#import <Preferences/PSListController.h>

@interface NSPServiceController : PSListController {
  NSString *_service;
  BOOL _isCustom;
}
- (id)initWithService:(NSString *)service isCustom:(BOOL)isCustom;
- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest;
@end
