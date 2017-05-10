#pragma once

#ifdef __OBJC__
#include <UIKit/UIKit.h>
#include <Uno-iOS/Context.h>
#include <Uno-iOS/Uno-iOS.h>

@interface uContext (LocalNotify)
- (void)initializeLocalNotifications:(UIApplication *)application;
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;
@end

#endif
