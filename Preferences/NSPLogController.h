#import <Preferences/PSViewController.h>
#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@interface NSPLogController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
  UITableView *_table;
  NSString *_service;
  BOOL _global;
  NSMutableArray *_sections;
  NSMutableDictionary *_data;
  NSString *_logKey;
  NSString *_logEnabledKey;
  BOOL _logEnabled;
}
- (void)updateLog;
- (void)updateLogEnabled:(UISwitch *)logEnabledSwitch;
@end
