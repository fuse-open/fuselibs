#include <Uno/Uno.h>
#include "AppDelegatePushNotify.h"
@{Fuse.Platform.Lifecycle:IncludeDirective}
@{Fuse.PushNotifications.iOSImpl:IncludeDirective}

@implementation uContext (PushNotify)

- (void)application:(UIApplication *)application initializePushNotifications:(NSDictionary *)launchOptions {
	if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
		[self application:application dispatchPushNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] fromBar:YES];
	}
#if (!@(Project.iOS.PushNotifications.RegisterOnLaunch:IsSet)) || @(Project.iOS.PushNotifications.RegisterOnLaunch:Or(0))
	@{Fuse.PushNotifications.iOSImpl.RegisterForPushNotifications():Call()};
#endif
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	uAutoReleasePool pool;
	const unsigned* tokenBytes = (unsigned*)[deviceToken bytes];
	NSString* hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
						  ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
						  ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
						  ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
	@{Uno.String} token = uPlatform::iOS::ToUno(hexToken);
	@{Fuse.PushNotifications.iOSImpl.OnNotificationRegistrationSucceeded(string):Call(token)};
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	uAutoReleasePool pool;
	@{Uno.String} errorReason = uPlatform::iOS::ToUno(error.localizedDescription);
	@{Fuse.PushNotifications.iOSImpl.OnNotificationRegistrationFailed(string):Call(errorReason)};
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	uAutoReleasePool pool;
	@{Fuse.Platform.ApplicationState} state = @{Fuse.Platform.Lifecycle.State:Get()};
	bool fromNotifBar = application.applicationState != UIApplicationStateActive;
	[self application:application dispatchPushNotification:userInfo fromBar:fromNotifBar];
}

- (void)application:(UIApplication *)application dispatchPushNotification:(NSDictionary *)userInfo fromBar:(BOOL)fromBar {
	uAutoReleasePool pool;
	NSError* err = NULL;
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&err];
	if (jsonData)
	{
		NSString* nsJsonPayload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		@{Uno.String} jsonPayload = uPlatform::iOS::ToUno(nsJsonPayload);
		@{Fuse.PushNotifications.iOSImpl.OnReceivedNotification(string, bool):Call(jsonPayload, fromBar)};
	}
}

@end
