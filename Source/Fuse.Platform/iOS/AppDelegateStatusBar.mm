#include <uno.h>

@{Fuse.Platform.SystemUI:includeDirective}
@{ObjC.Object:includeDirective}
@{Uno.Platform.iOS.Support:includeDirective}
@{Fuse.Platform.SystemUI:includeDirective}

#include <AppDelegateStatusBar.h>

@implementation uAppDelegate (StatusBar)

// On iOS 8 this is only called when Status Bar changes in response to external
// events
- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)frame
{
	uAutoReleasePool pool;
	@{Fuse.Platform.SystemUI._statusBarWillChangeFrame(Uno.Platform.iOS.uCGRect, double):call(frame, 0)};
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)frame
{
	uAutoReleasePool pool;
	@{Fuse.Platform.SystemUI._statusBarDidChangeFrame(Uno.Platform.iOS.uCGRect):call(frame)};
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	uAutoReleasePool pool;
	return @{Fuse.Platform.SystemUI.supportedOrientation:get()};
}

- (BOOL)prefersStatusBarHidden
{
	uAutoReleasePool pool;
	return !@{Fuse.Platform.SystemUI.IsTopFrameVisible:get()};
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	uAutoReleasePool pool;
	return (UIStatusBarStyle)@{Fuse.Platform.SystemUI.uStatusBarStyle:get()};
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	uAutoReleasePool pool;
	return (UIStatusBarAnimation)@{Fuse.Platform.SystemUI.uStatusBarAnimation:get()};
}
@end
