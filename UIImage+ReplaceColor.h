#import <UIKit/UIKit.h>

@interface UIImage (ReplaceColor)
- (UIImage *)imageByReplacingColor:(UIColor *)sourceColor withColor:(UIColor *)targetColor;
@end
