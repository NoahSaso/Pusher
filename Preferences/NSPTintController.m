#import "../global.h"

@implementation NSPTintController : NSObject

+ (instancetype)sharedController {
  static NSPTintController *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [NSPTintController new];
    shared->_activeTintColor = nil;
  });
  return shared;
}

- (void)setActiveTintColor:(UIColor *)color {
  _activeTintColor = color;
}

- (UIColor *)activeTintColor {
  return _activeTintColor ?: PUSHER_COLOR;
}

@end
