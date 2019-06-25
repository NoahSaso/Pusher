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
		CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:PUSHER_MESSAGING_CENTER_NAME];
		[messagingCenter runServerOnCurrentThread];
		[messagingCenter registerForMessageName:PUSHER_TEST_PUSH_MESSAGE_NAME target:self selector:@selector(handleMessageNamed:withUserInfo:)];
	}
	return self;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	NSString *service = userInfo[@"service"];
	BBServer *bbServer = [BBServer pusherSharedInstance];
	if (service == nil || ![service isKindOfClass:NSString.class] || service.length < 1 || bbServer == nil || ![bbServer isKindOfClass:BBServer.class]) {
		return @{ @"success": @NO };
	}

	BBBulletin *bulletin = [BBBulletin new];
	bulletin.title = @"Title";
	bulletin.subtitle = @"Subtitle";
	bulletin.message = @"Message";
	bulletin.date = [NSDate date];
	bulletin.sectionID = @"com.apple.Preferences";
	[bbServer sendToPusherService:service bulletin:bulletin appID:@"com.apple.Preferences" appName:@"Settings" title:@"Title" message:@"Subtitle\nMessage" isTest:YES];

	return @{ @"success": @YES };
}

@end
