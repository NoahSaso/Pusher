#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>
#import "NSPAppListController.h"

@class NSPAppListController;

@interface NSPAppListALApplicationTableDataSource : ALApplicationTableDataSource
@property (nonatomic, retain) NSPAppListController *appListController;
@end
