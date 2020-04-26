#include <Uno/Uno.h>

@{Fuse.Platform.SystemUI:IncludeDirective}
@{ObjC.Object:IncludeDirective}
@{Uno.Platform.iOS.Support:IncludeDirective}
@{Fuse.Platform.SystemUI:IncludeDirective}

#include <AppDelegateStatusBar.h>

@implementation uAppDelegate (StatusBar)

// On iOS 8 this is only called when Status Bar changes in response to external
// events
- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)frame
{
	uAutoReleasePool pool;
	@{Fuse.Platform.SystemUI._statusBarWillChangeFrame(Uno.Platform.iOS.uCGRect, double):Call(frame, 0)};
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)frame
{
	uAutoReleasePool pool;
	@{Fuse.Platform.SystemUI._statusBarDidChangeFrame(Uno.Platform.iOS.uCGRect):Call(frame)};
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	uAutoReleasePool pool;
	return @{Fuse.Platform.SystemUI.supportedOrientation:Get()};
}

- (BOOL)prefersStatusBarHidden
{
	uAutoReleasePool pool;
	return !@{Fuse.Platform.SystemUI.IsTopFrameVisible:Get()};
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	uAutoReleasePool pool;
	return (UIStatusBarStyle)@{Fuse.Platform.SystemUI.uStatusBarStyle:Get()};
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	uAutoReleasePool pool;
	return (UIStatusBarAnimation)@{Fuse.Platform.SystemUI.uStatusBarAnimation:Get()};
}
@end
