#import "UIImage+ReplaceColor.h"

@implementation UIImage (ReplaceColor)

- (UIImage *)imageByReplacingColor:(UIColor *)sourceColor withColor:(UIColor *)targetColor {

  // components of the source color
  const CGFloat *sourceComponents = CGColorGetComponents(sourceColor.CGColor);
  UInt8 *source255Components = malloc(sizeof(UInt8) * 4);
  for (int i = 0; i < 4; i++) source255Components[i] = (UInt8) round(sourceComponents[i] * 255.0);

  // components of the target color
  const CGFloat *targetComponents = CGColorGetComponents(targetColor.CGColor);
  UInt8 *target255Components = malloc(sizeof(UInt8) * 4);
  for (int i = 0; i < 4; i++) target255Components[i] = (UInt8) round(targetComponents[i] * 255.0);

  // raw image reference
  CGImageRef rawImage = self.CGImage;

  // image attributes
  size_t width = CGImageGetWidth(rawImage);
  size_t height = CGImageGetHeight(rawImage);
  CGRect rect = { CGPointZero, { width, height } };

  // bitmap format
  size_t bitsPerComponent = 8;
  size_t bytesPerRow = width * 4;
  CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

  // data pointer
  UInt8 *data = calloc(bytesPerRow, height);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // create bitmap context
  CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
  CGContextDrawImage(ctx, rect, rawImage);

  // loop through each pixel's components
  for (int byte = 0; byte < bytesPerRow * height; byte += 4) {

      UInt8 r = data[byte];
      UInt8 g = data[byte + 1];
      UInt8 b = data[byte + 2];

      // delta components
      UInt8 dr = abs(r - source255Components[0]);
      UInt8 dg = abs(g - source255Components[1]);
      UInt8 db = abs(b - source255Components[2]);

      // ratio of 'how far away' each component is from the source color
      CGFloat ratio = (dr+dg+db)/(255.0*3.0);
      if (ratio > 0.1) ratio = 1; // if ratio is too far away, set it to max.
      if (ratio < 0) ratio = 0; // if ratio isn't far enough away, set it to min.

      // blend color components
      data[byte] = (UInt8) round(ratio * r) + (UInt8) round((1.0 - ratio) * target255Components[0]);
      data[byte + 1] = (UInt8) round(ratio * g) + (UInt8) round((1.0 - ratio) * target255Components[1]);
      data[byte + 2] = (UInt8) round(ratio * b) + (UInt8) round((1.0 - ratio) * target255Components[2]);

  }

  // get image from context
  CGImageRef img = CGBitmapContextCreateImage(ctx);

  // clean up
  CGContextRelease(ctx);
  CGColorSpaceRelease(colorSpace);
  free(data);
  free(source255Components);
  free(target255Components);

  // scale for retina
  UIImage *newImage = [UIImage imageWithCGImage:img scale:UIScreen.mainScreen.scale orientation:UIImageOrientationUp];
  CGImageRelease(img);

  return newImage;

}

@end
