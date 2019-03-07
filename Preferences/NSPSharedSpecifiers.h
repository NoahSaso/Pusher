#import <Preferences/PSSpecifier.h>

@interface NSPSharedSpecifiers : NSObject
+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID;
+ (NSArray *)pushover:(NSString *)appID;
@end
