#import <Preferences/PSViewController.h>
#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>
#import <AppList/AppList.h>

@interface NSPLogController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
  UITableView *_table;
  NSString *_service;
  BOOL _global;
  NSMutableArray *_sections;
  NSMutableDictionary *_data;
  NSString *_logKey;
  NSString *_logEnabledKey;
  BOOL _logEnabled;
  NSMutableArray *_expandedIndexPaths;
  int _clearLogRow;
  int _logEnabledSwitchRow;
  int _networkResponseRow;
  int _appFilterRow;
  int _filterSection;
  int _firstLogSection;
  NSString *_filteredAppID;
  NSString *_filteredNetworkResponse;
  ALApplicationList *_appList;
}
- (void)updateLog;
- (void)updateLogEnabled:(UISwitch *)logEnabledSwitch;
- (void)updateLogAndReload;
@end
