#import "NSPServiceController.h"
#import "NSPSharedSpecifiers.h"
#import "NSPCustomizeAppsController.h"

#import "../global.h"
#import <Custom/defines.h>
#import <notify.h>

@implementation NSPServiceController

- (id)initWithService:(NSString *)service image:(UIImage *)image isCustom:(BOOL)isCustom {
	if (self = [super init]) {
		_service = service;
		_image = image;
		_isCustom = isCustom;
		_colorCube = [CCColorCube new];
		_uiColor = nil;
	}
	return self;
}

- (void)addObjectsFromArray:(NSArray *)source atIndex:(int)idx toArray:(NSMutableArray *)dest {
	for (id object in source) {
		[dest insertObject:object atIndex:idx];
		idx += 1;
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// [self setTitle:_service];
	if (!_imageTitleView) {
		UILabel *label = [UILabel new];
		label.text = _service;
		label.font = [UIFont boldSystemFontOfSize:17];

		UIImageView *imageView = [[UIImageView alloc] initWithImage:_image];

		_imageTitleView = [[UIStackView alloc] initWithArrangedSubviews:@[imageView, label]];
		_imageTitleView.alignment = UIStackViewAlignmentCenter;
		_imageTitleView.spacing = 10.0;

		self.navigationItem.titleView = _imageTitleView;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (!_uiColor) {
		CCFlags flags = (CCFlags) (CCOnlyDistinctColors | CCAvoidWhite | CCAvoidBlack);
		NSArray *imgColors = [_colorCube extractColorsFromImage:_image flags:flags];
		if (!imgColors.count) return;
		_uiColor = [imgColors[0] copy];
	}

	// load each time to override NSPRootListController
	[self setPusherUIColor:_uiColor override:YES];
}

- (NSArray *)specifiers {
	if (!_specifiers) {

		NSMutableArray *allSpecifiers = nil;
		NSArray *sharedSpecifiers = nil;

		if (_isCustom) {
			allSpecifiers = [[NSPSharedSpecifiers getCustom:_service ref:self] mutableCopy];
			sharedSpecifiers = [NSPSharedSpecifiers getCustomShared:_service];
		} else {
			allSpecifiers = [[self loadSpecifiersFromPlistName:_service target:self] mutableCopy];
			sharedSpecifiers = [NSPSharedSpecifiers get:_service];
		}

		BOOL insertOnNext = NO;
		BOOL inserted = NO;
		int idx = 0;
		for (PSSpecifier *specifier in allSpecifiers) {
			if (insertOnNext && specifier.cellType == PSGroupCell) {
				[self addObjectsFromArray:sharedSpecifiers atIndex:idx toArray:allSpecifiers];
				inserted = YES;
				break;
			} else if (specifier.cellType == PSGroupCell && Xeq(specifier.identifier, @"Options")) { // insert at end of options group
				insertOnNext = YES;
			}
			idx += 1;
		}

		if (!inserted) {
			[allSpecifiers addObjectsFromArray:sharedSpecifiers];
		}

		PSSpecifier *sendTestNotificationGroup = [PSSpecifier emptyGroupSpecifier];
		PSSpecifier *sendTestNotification = [PSSpecifier preferenceSpecifierNamed:@"Send Test Notification" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
		[sendTestNotification setButtonAction:@selector(sendTestNotification:)];
		[sendTestNotification setProperty:@YES forKey:@"enabled"];

		[allSpecifiers addObjectsFromArray:@[sendTestNotificationGroup, sendTestNotification]];

		_specifiers = [allSpecifiers copy];
	}

	return _specifiers;
}

- (void)sendTestNotification:(PSSpecifier *)specifier {
	[self.view endEditing:YES];

	XLog(@"Sending test for %@", _service);

	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:PUSHER_MESSAGING_CENTER_NAME];

	// Two-way (wait for reply)
	NSDictionary *reply;
	reply = [messagingCenter sendMessageAndReceiveReplyName:PUSHER_TEST_PUSH_MESSAGE_NAME userInfo:@{ @"service": _service }];

	UIAlertController *alert = nil;
	if (reply[@"success"] && ((NSNumber *)reply[@"success"]).boolValue) {
		alert = Xalert(@"Sent test notification");
	} else {
		alert = Xalert(@"Failed to send");
	}
	[alert addAction:XalertBtn(@"Ok")];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)openPushoverAppBuild {
	Xurl(@"https://pushover.net/apps/build");
}

- (void)openPushoverDashboard {
	Xurl(@"https://pushover.net/dashboard");
}

- (void)openPushbulletAccount {
	Xurl(@"https://www.pushbullet.com/#settings/account");
}

- (void)openIFTTTAccount {
	Xurl(@"https://ifttt.com/services/maker_webhooks/settings");
}

- (void)openDateFormatInstructions {
	Xurl(@"https://nsdateformatter.com");
}

- (void)openPusherReceiverFirefoxExtension {
	Xurl(@"https://addons.mozilla.org/en-US/firefox/addon/pusher-receiver/");
}

- (void)openPusherReceiverChromeExtension {
	Xurl(@"https://chrome.google.com/webstore/detail/pusher-receiver/cegndpdokeeegijbkidfcolhomffhibh");
}

- (void)openTwitterBurkybang {
	[self openTwitter:@"burkybang"];
}

@end
