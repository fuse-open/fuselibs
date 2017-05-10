#pragma once

#ifdef __OBJC__
#include <UIKit/UIKit.h>
#include <Uno-iOS/Context.h>
#include <Uno-iOS/Uno-iOS.h>

@interface uContext (PushNotify)
- (void)application:(UIApplication *)application initializePushNotifications:(NSDictionary *)launchOptions;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)application:(UIApplication *)application dispatchPushNotification:(NSDictionary *)userInfo fromBar:(BOOL)fromBar;
@end

#endif
