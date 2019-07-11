@interface NSPusherManager : NSObject {
  UIColor *_activeTintColor;
}
+ (instancetype)sharedController;
- (void)setActiveTintColor:(UIColor *)color;
- (UIColor *)activeTintColor;
- (void)openTwitter:(NSString *)username;
@end
