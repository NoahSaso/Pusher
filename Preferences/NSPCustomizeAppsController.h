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
  NSDictionary *_defaultDevices;
  NSString *_defaultDevicesKey;
  NSMutableDictionary *_loadedAppControllers;
}
- (void)addAppIDs:(NSArray *)appIDs;
- (void)saveAppState;
- (void)sortAppIDArray:(NSMutableArray *)array;
@end