#import <Preferences/PSViewController.h>
#import <AppList/AppList.h>
#import "NSPAppSelectionController.h"

@class NSPAppSelectionController;

@interface NSPAppSelectionALApplicationTableDataSource : ALApplicationTableDataSource
@property (nonatomic, retain) NSPAppSelectionController *appSelectionController;
@end
