#include <Uno/Uno.h>
#include "AppDelegateLocalNotify.h"
@{Fuse.Platform.Lifecycle:IncludeDirective}
@{Fuse.LocalNotifications.iOSImpl:IncludeDirective}

@implementation uContext (LocalNotify)

- (void)initializeLocalNotifications:(UIApplication *)application  {
	[application registerUserNotificationSettings:
	 [UIUserNotificationSettings settingsForTypes:
	  UIUserNotificationTypeAlert|
	  UIUserNotificationTypeBadge|
	  UIUserNotificationTypeSound
	  categories:nil]];
	@{Fuse.LocalNotifications.iOSImpl.SendPendingFromLaunchOptions():Call()};
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	uAutoReleasePool pool;
	NSError* err = NULL;
	NSMutableDictionary* userInfo;

	if (notification.userInfo)
		userInfo = [notification.userInfo mutableCopy];
	else
		userInfo = [NSMutableDictionary dictionary];

	if (notification.alertAction)
		[userInfo setObject:notification.alertAction forKey:@"title"];
	if (notification.alertBody)
		[userInfo setObject:notification.alertBody forKey:@"body"];

	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&err];
	if (jsonData)
	{
		NSString* nsJsonPayload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		@{Uno.String} jsonPayload = uPlatform::iOS::ToUno(nsJsonPayload);
		@{Fuse.LocalNotifications.iOSImpl.OnReceivedLocalNotification(string):Call(jsonPayload)};
	}
}

@end
