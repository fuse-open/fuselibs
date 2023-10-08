#pragma once

#ifdef __OBJC__
#include <UIKit/UIKit.h>
#include <Uno-iOS/AppDelegate.h>
#include <Uno-iOS/Uno-iOS.h>

@(appDelegate.headerFile.declaration:join())

@{Uno.Rect:includeDirective}

@interface uAppDelegate (StatusBar)

- (BOOL)prefersStatusBarHidden;
- (UIStatusBarStyle)preferredStatusBarStyle;
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation;

@end

#endif
