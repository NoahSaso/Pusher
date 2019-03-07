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
}
- (id)initWithService:(NSString *)service;
- (void)addAppIDs:(NSArray *)appIDs;
- (void)saveAppState;
- (void)sortAppIDArray:(NSMutableArray *)array;
@end
