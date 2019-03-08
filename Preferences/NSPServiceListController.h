#import <Preferences/PSViewController.h>

@interface NSPServiceListController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
  NSDictionary *_prefs;
  UITableView *_table;
  NSArray *_sections;
  NSMutableDictionary *_data;
  NSArray *_services;
  NSString *_lastTargetService;
  NSIndexPath *_lastTargetIndexPath;
  NSMutableDictionary *_loadedServiceControllers;
}
@end
