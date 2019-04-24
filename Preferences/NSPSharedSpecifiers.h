#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>

@interface NSPSharedSpecifiers : NSObject
+ (NSArray *)get:(NSString *)service withAppID:(NSString *)appID isCustomService:(BOOL)isCustomService;
+ (NSArray *)get:(NSString *)service;
+ (NSArray *)getCustom:(NSString *)service ref:(PSListController *)listController;
+ (NSArray *)getCustomShared:(NSString *)service withAppID:(NSString *)appID;
+ (NSArray *)getCustomShared:(NSString *)service;
+ (NSArray *)pushover:(NSString *)appID;
+ (NSArray *)pushbullet:(NSString *)appID;
+ (NSArray *)ifttt:(NSString *)appID;
+ (void)setPreferenceValue:(id)value forIFTTTSpecifier:(PSSpecifier *)specifier;
+ (id)readIFTTTPreferenceValue:(PSSpecifier *)specifier;
+ (void)setPreferenceValue:(id)value forCustomSpecifier:(PSSpecifier *)specifier;
+ (id)readCustomPreferenceValue:(PSSpecifier *)specifier;
@end
