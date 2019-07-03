#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>
#import "NSPAppSelectionALApplicationTableDataSource.h"

typedef void (^PickerCallback)(id appIdOrIds);

@interface NSPAppSelectionController : UITableViewController <UITableViewDelegate, UISearchResultsUpdating> {
  ALApplicationList *_appList;
  NSPAppSelectionALApplicationTableDataSource *_appListDataSource;
  PickerCallback callback;
  UISearchController *_searchController;
}
@property (nonatomic, assign) BOOL selectingMultiple;
@property (nonatomic, retain) NSString *navItemTitle;
@property (nonatomic, retain) NSString *rightButtonTitle;
@property (nonatomic, retain) NSMutableArray *selectedAppIDs;
@property (nonatomic, copy) PickerCallback callback;
- (void)dismiss;
@end
