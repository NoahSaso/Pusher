@interface NSPTintController : NSObject {
  UIColor *_activeTintColor;
}
+ (instancetype)sharedController;
- (void)setActiveTintColor:(UIColor *)color;
- (UIColor *)activeTintColor;
@end
