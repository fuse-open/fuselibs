#include <Uno/Uno.h>

@{Fuse.Platform.SystemUI:IncludeDirective}
@{ObjC.Object:IncludeDirective}

#include <NotificationCenterContext.h>

@implementation uNotificationCenterContext

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

- (void)onUserSettingsChanged:(NSNotification*)notification
{
	uAutoReleasePool pool;

	CGFloat textScaleFactor = [self textScaleFactor];
	@{Fuse.Platform.SystemUI.uTextScaleFactorDidChange(float):Call(textScaleFactor)};
}

- (CGFloat)textScaleFactor
{
	// this values are based on the "body" text sizes in the Apple human interface guideline section typography : https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
	const CGFloat xs = 14;
	const CGFloat s = 15;
	const CGFloat m = 16;
	const CGFloat l = 17;
	const CGFloat xl = 19;
	const CGFloat xxl = 21;
	const CGFloat xxxl = 23;
	// Accessibility sizes for "body" text are:
	const CGFloat acc1 = 28;
  	const CGFloat acc2 = 33;
	const CGFloat acc3 = 40;
	const CGFloat acc4 = 47;
	const CGFloat acc5 = 53;
	// compute the scale as relative difference from size L, where L is assumed to have scale 1.0.
	UIContentSizeCategory category = [UIApplication sharedApplication].preferredContentSizeCategory;
	if ([category isEqualToString:UIContentSizeCategoryExtraSmall])
		return xs / l;
	else if ([category isEqualToString:UIContentSizeCategorySmall])
		return s / l;
	else if ([category isEqualToString:UIContentSizeCategoryMedium])
		return m / l;
	else if ([category isEqualToString:UIContentSizeCategoryLarge])
		return 1.0;
	else if ([category isEqualToString:UIContentSizeCategoryExtraLarge])
		return xl / l;
	else if ([category isEqualToString:UIContentSizeCategoryExtraExtraLarge])
		return xxl / l;
	else if ([category isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge])
		return xxxl / l;
	else if ([category isEqualToString:UIContentSizeCategoryAccessibilityMedium])
		return acc1 / l;
	else if ([category isEqualToString:UIContentSizeCategoryAccessibilityLarge])
		return acc2 / l;
	else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge])
		return acc3 / l;
	else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge])
		return acc4 / l;
	else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge])
		return acc5 / l;
	else
		return 1.0;
}

@end
