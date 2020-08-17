#pragma once

#ifdef __OBJC__

#include <UIKit/UIKit.h>
#include <Uno-iOS/AppDelegate.h>
#include <Uno-iOS/Uno-iOS.h>

@{Uno.Rect:IncludeDirective}

@interface uNotificationCenterContext : NSObject
- (void)uKeyboardWillChangeFrame:(NSNotification *)notification;
- (void)onUserSettingsChanged:(NSNotification*)notification;
- (CGFloat)textScaleFactor;
@end

#endif
