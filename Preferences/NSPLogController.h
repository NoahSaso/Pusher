#import <Preferences/PSViewController.h>
#import "../global.h"
#import <Custom/defines.h>

@interface NSPLogController : PSViewController <UITableViewDelegate> {
  UITableView *_table;
  NSString *_service;
  NSMutableArray *_sections;
  NSMutableDictionary *_data;
}
- (void)updateLog;
@end
