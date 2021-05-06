#import "NSPPSViewControllerWithColoredUI.h"
#import "../global.h"
#import "../helpers.h"
#import <notify.h>

#define DEFAULT_SERVICE_IMAGE_NAME @"DefaultService"
#define DEFAULT_IMAGE [UIImage imageNamed:DEFAULT_SERVICE_IMAGE_NAME inBundle:PUSHER_BUNDLE]

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
