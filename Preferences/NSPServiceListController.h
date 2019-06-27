#import "NSPPSViewControllerWithColoredUI.h"

#define PUSHER_BUNDLE [NSBundle bundleWithPath:@"/Library/PreferenceBundles/Pusher.bundle"]
#define DEFAULT_SERVICE_IMAGE_NAME @"DefaultService"

@interface NSPServiceListController : NSPPSViewControllerWithColoredUI <UITableViewDelegate, UITableViewDataSource> {
  NSDictionary *_prefs;
  UITableView *_table;
  NSArray *_sections;
  NSMutableDictionary *_data;
  NSArray *_services;
  NSString *_lastTargetService;
  NSIndexPath *_lastTargetIndexPath;
  NSMutableDictionary *_loadedServiceControllers;
  UIBarButtonItem *_addNewServiceBarButtonItem;
  NSMutableDictionary *_customServices;
  NSMutableDictionary *_serviceImages;
  UIImage *_defaultImage;
}
- (void)showTutorial;
- (void)saveCustomServices;
@end

@interface UIImage (Private)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end
