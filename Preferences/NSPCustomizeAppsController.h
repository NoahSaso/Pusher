#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>

@interface NSPCustomizeAppsController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
  UITableView *_table;
  NSArray *_sections;
  NSMutableDictionary *_data;
  NSString *_service;
  NSMutableDictionary *_customApps;
  ALApplicationList *_appList;
  NSString *_prefsKey;
  NSString *_lastTargetAppID;
  NSIndexPath *_lastTargetIndexPath;

  NSArray *_defaultDevices;
  NSArray *_defaultSounds;
  NSString *_defaultEventName;
  NSNumber *_defaultIncludeIcon;
  NSNumber *_defaultCurateData;

  NSMutableDictionary *_loadedAppControllers;

  BOOL _isCustomService;
}
- (void)addAppIDs:(NSArray *)appIDs;
- (void)setEnabledWithDefaults:(NSString *)appID enabled:(BOOL)enabled;
- (void)saveAppState;
- (void)sortAppIDArray:(NSMutableArray *)array;
@end
