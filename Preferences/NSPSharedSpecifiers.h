#import <Preferences/PSSpecifier.h>

@interface NSPSharedSpecifiers : NSObject
+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID;
+ (NSArray *)get:(NSString *)service;
+ (NSArray *)getCustomForService:(NSString *)service withAppID:(NSString *)appID ref:(PSListController *)listController;
+ (NSArray *)getCustomForService:(NSString *)service ref:(PSListController *)listController;
+ (NSArray *)pushover:(NSString *)appID;
+ (NSArray *)pushbullet:(NSString *)appID;
+ (NSArray *)ifttt:(NSString *)appID;
+ (void)setPreferenceValue:(id)value forIFTTTSpecifier:(PSSpecifier *)specifier;
+ (id)readIFTTTPreferenceValue:(PSSpecifier *)specifier;
+ (void)setPreferenceValue:(id)value forCustomSpecifier:(PSSpecifier *)specifier;
+ (id)readCustomPreferenceValue:(PSSpecifier *)specifier;
@end
