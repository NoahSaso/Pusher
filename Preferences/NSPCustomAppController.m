#import "NSPCustomAppController.h"
#import "NSPSharedSpecifiers.h"

#import "../global.h"
#import "../helpers.h"
#import <notify.h>

@implementation NSPCustomAppController

- (id)initWithService:(NSString *)service
                appID:(NSString *)appID
             appTitle:(NSString *)appTitle
      isCustomService:(BOOL)isCustomService {
  if (self = [super init]) {
    _service = service;
    _appID = appID;
    _appTitle = [appTitle copy];
    _isCustomService = isCustomService;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.title = _appTitle;
}

- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [[[@[ [PSSpecifier groupSpecifierWithName:@"Customize"] ]
        arrayByAddingObjectsFromArray:[NSPSharedSpecifiers
                                                      get:_service
                                                withAppID:_appID
                                          isCustomService:_isCustomService]]
        mutableCopy] retain];
  }

  return _specifiers;
}

@end
