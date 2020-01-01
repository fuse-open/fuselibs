#include <Uno/Uno.h>

@{Fuse.Platform.SystemUI:IncludeDirective}
@{ObjC.Object:IncludeDirective}

#include <KeyboardContext.h>

@implementation uKeyboardContext

- (void)uKeyboardWillChangeFrame:(NSNotification *)notification
{
	uAutoReleasePool pool;
	CGRect frameBegin = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect frameEnd = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	double animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve animationCurve = (UIViewAnimationCurve) [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];

	@{Fuse.Platform.SystemUIResizeReason} resizeReason;

	if (notification.name == UIKeyboardWillShowNotification)
		resizeReason = @{Fuse.Platform.SystemUIResizeReason.WillShow};
	else if (notification.name == UIKeyboardWillHideNotification)
	{
		resizeReason = @{Fuse.Platform.SystemUIResizeReason.WillHide};
		frameEnd.size.height = 0.;
	}
	else // UIKeyboardWillChangeFrameNotification
		resizeReason = @{Fuse.Platform.SystemUIResizeReason.WillChangeFrame};	
	
	@{Fuse.Platform.SystemUI.uKeyboardWillChangeFrame(Uno.Platform.iOS.uCGRect, Uno.Platform.iOS.uCGRect, double, int, Fuse.Platform.SystemUIResizeReason):Call(frameBegin, frameEnd, animationDuration, static_cast<int32_t>(animationCurve), resizeReason)};
}

@end
