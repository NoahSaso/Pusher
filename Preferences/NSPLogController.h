#import "NSPPSViewControllerWithColoredUI.h"
#import "../global.h"
#import "../helpers.h"
#import <notify.h>
#import <AppList/AppList.h>

@interface NSPLogController : NSPPSViewControllerWithColoredUI <UITableViewDelegate, UITableViewDataSource> {
  UITableView *_table;
  NSString *_service;
  BOOL _global;
  NSMutableArray *_sections;
  NSMutableDictionary *_data;
  NSString *_logKey;
  NSString *_logEnabledKey;
  BOOL _logEnabled;
  NSMutableArray *_expandedIndexPaths;
  int _settingsSection;
  int _clearLogRow;
  int _logEnabledSwitchRow;
  int _networkResponseRow;
  int _appFilterRow;
  int _filterSection;
  int _firstLogSection;
  int _globalOnlyRow;
  int _endResultFilterRow;
  NSString *_filteredAppID;
  NSString *_filteredNetworkResponse;
  NSString *_filteredEndResult;
  ALApplicationList *_appList;
  BOOL _filteredGlobalOnly;
  NSMutableArray *_truncatedIndexPaths;
}
- (void)updateLog;
- (void)updateLogEnabled:(UISwitch *)logEnabledSwitch;
- (void)updateLogAndReload;
- (void)showAppFilterTutorial;
@end
