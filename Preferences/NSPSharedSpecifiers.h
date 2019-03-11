#import <Preferences/PSSpecifier.h>

@interface NSPSharedSpecifiers : NSObject
+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID;
+ (NSArray *)get:(NSString *)service;
+ (NSArray *)pushover:(NSString *)appID;
+ (NSArray *)pushbullet:(NSString *)appID;
@end
