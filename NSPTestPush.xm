#import "NSPTestPush.h"

@implementation NSPTestPush

+ (void)load {
  [self sharedInstance];
}

+ (id)sharedInstance {
  static dispatch_once_t once = 0;
  __strong static id sharedInstance = nil;
  dispatch_once(&once, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {
    CPDistributedMessagingCenter *messagingCenter =
        [CPDistributedMessagingCenter centerNamed:PUSHER_MESSAGING_CENTER_NAME];
    [messagingCenter runServerOnCurrentThread];
    [messagingCenter
        registerForMessageName:PUSHER_TEST_PUSH_MESSAGE_NAME
                        target:self
                      selector:@selector(handleMessageNamed:withUserInfo:)];
  }
  return self;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name
                        withUserInfo:(NSDictionary *)userInfo {
  NSString *service = userInfo[@"service"];
  BBServer *bbServer = [BBServer pusherSharedInstance];
  if (service == nil || ![service isKindOfClass:NSString.class] ||
      service.length < 1 || bbServer == nil ||
      ![bbServer isKindOfClass:BBServer.class]) {
    return @{@"success" : @NO};
  }

  BBBulletin *bulletin = [BBBulletin new];
  bulletin.title = PUSHER_TEST_NOTIFICATION_TITLE;
  bulletin.subtitle = PUSHER_TEST_NOTIFICATION_SUBTITLE;
  bulletin.message = PUSHER_TEST_NOTIFICATION_MESSAGE;
  bulletin.date = [NSDate date];
  bulletin.sectionID = PUSHER_TEST_NOTIFICATION_SECTION_ID;

  NSURL *attachmentURL =
      [NSURL fileURLWithPath:XStr(@"%@/icon@3x.png", PUSHER_BUNDLE_PATH)];
  BBAttachmentMetadata *attachment;
  // iOS 14
  if ([[%c(BBAttachmentMetadata) alloc]
        respondsToSelector:@selector(_initWithType:URL:identifier:uniformType:thumbnailGeneratorUserInfo:thumbnailHidden:hiddenFromDefaultExpandedView:)]) {
      attachment = [[%c(BBAttachmentMetadata) alloc]
                      _initWithType:1
                                URL:attachmentURL
                         identifier:@"TestImage"
                        // no idea what this is supposed to be
                        uniformType:@"TestImageUniformType"
         // no idea what this is supposed to be
         thumbnailGeneratorUserInfo:nil
                    thumbnailHidden:true
      hiddenFromDefaultExpandedView:false];
  } else {
      attachment = [[%c(BBAttachmentMetadata) alloc] _initWithUUID:@"TestImage" type:1 URL:attachmentURL];
  }
  [bulletin setPrimaryAttachment:attachment];

  [bbServer
      sendToPusherService:service
                 bulletin:bulletin
                    appID:bulletin.sectionID
                  appName:PUSHER_TEST_NOTIFICATION_APP_NAME
                    title:bulletin.title
                  message:XStr(@"%@\n%@", bulletin.subtitle, bulletin.message)
                   isTest:YES];

  return @{@"success" : @YES};
}

@end
