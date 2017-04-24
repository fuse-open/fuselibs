#pragma once

#ifdef __OBJC__
#include <UIKit/UIKit.h>
#include <Uno-iOS/AppDelegate.h>
#include <Uno-iOS/Uno-iOS.h>

@(AppDelegate.HeaderFile.Declaration:Join())

@{Uno.Rect:IncludeDirective}

@interface uAppDelegate (StatusBar)

- (BOOL)prefersStatusBarHidden;
- (UIStatusBarStyle)preferredStatusBarStyle;
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation;

@end

#endif
