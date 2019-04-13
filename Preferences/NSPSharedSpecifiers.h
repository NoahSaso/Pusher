#import <Preferences/PSSpecifier.h>

@interface NSPSharedSpecifiers : NSObject
+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID;
+ (NSArray *)get:(NSString *)service;
+ (NSArray *)pushover:(NSString *)appID;
+ (NSArray *)pushbullet:(NSString *)appID;
+ (NSArray *)ifttt:(NSString *)appID;
+ (void)setPreferenceValue:(id)value forIFTTTSpecifier:(PSSpecifier *)specifier;
+ (id)readIFTTTPreferenceValue:(PSSpecifier *)specifier;
@end
