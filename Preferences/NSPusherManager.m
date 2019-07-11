#import "../global.h"
#import <Custom/defines.h>

@implementation NSPusherManager : NSObject

+ (instancetype)sharedController {
  static NSPusherManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [NSPusherManager new];
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

- (void)openTwitter:(NSString *)username {
	NSString *appLink = Xstr(@"twitter://user?screen_name=%@", username);
	NSString *webLink = Xstr(@"https://twitter.com/%@", username);
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appLink]]) {
		Xurl(appLink);
	} else {
		Xurl(webLink);
	}
}

@end
