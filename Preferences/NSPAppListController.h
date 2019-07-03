#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <AppList/AppList.h>
#import "NSPAppListALApplicationTableDataSource.h"
#import "NSPCustomizeAppsController.h"

@interface NSPAppListController : PSViewController <UITableViewDelegate, UISearchResultsUpdating> {
  UITableView *_table;
  ALApplicationList *_appList;
  NSPAppListALApplicationTableDataSource *_appListDataSource;
  NSString *_prefix;
  NSString *_label;
  NSDictionary *_prefs;
  UISearchController *_searchController;
}
@property (nonatomic, retain) NSMutableArray *selectedAppIDs;
- (void)updatePreferencesForAppID:(NSString *)appID selected:(BOOL)selected;
- (void)updateTitle;
- (void)showTutorial;
@end
