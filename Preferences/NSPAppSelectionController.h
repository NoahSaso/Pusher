#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>
#import "NSPALApplicationTableDataSource.h"
#import "NSPCustomizeAppsController.h"

@interface NSPAppSelectionController : UITableViewController <UITableViewDelegate> {
  ALApplicationList *_appList;
  NSPALApplicationTableDataSource *_appListDataSource;
}
@property (nonatomic, retain) NSMutableArray *selectedAppIDs;
@property (nonatomic, retain) NSPCustomizeAppsController *customizeAppsController;
- (void)dismiss;
@end
