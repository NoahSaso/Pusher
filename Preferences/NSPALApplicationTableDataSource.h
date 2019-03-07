#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>
#import "NSPAppSelectionController.h"

@class NSPAppSelectionController;

@interface NSPALApplicationTableDataSource : ALApplicationTableDataSource
@property (nonatomic, retain) NSPAppSelectionController *appSelectionController;
@end
