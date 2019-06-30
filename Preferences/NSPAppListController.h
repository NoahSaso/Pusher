#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>
#import "NSPAppListALApplicationTableDataSource.h"
#import "NSPCustomizeAppsController.h"

@interface NSPAppListController : PSViewController <UITableViewDelegate, UISearchResultsUpdating> {
  UITableView *_table;
  ALApplicationList *_appList;
  NSPAppListALApplicationTableDataSource *_appListDataSource;
  NSString *_prefix;
  NSString *_label;
}
@property (nonatomic, retain) NSMutableArray *selectedAppIDs;
- (void)updatePreferencesForAppID:(NSString *)appID selected:(BOOL)selected;
- (void)updateTitle;
@end
