#import <Preferences/PSListController.h>

@interface NSPServiceController : PSListController {
  NSString *_service;
}
- (id)initWithService:(NSString *)service;
- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest;
@end
