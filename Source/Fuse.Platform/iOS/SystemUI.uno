using Uno;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Platform;
using Uno.Platform.iOS;

namespace Fuse.Platform
{
	public enum StatusBarStyle
	{
		Dark,
		Light
	}

	public enum StatusBarAnimation
	{
		// UIStatusBarAnimationNone:
		// UIStatusBarAnimationFade:
		// UIStatusBarAnimationSlide:
		None,
		Fade,
		Slide
	}

	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Require("Source.Include", "@{Uno.Platform.iOSDisplay:Include}")]
	[Require("Source.Include", "@{Uno.Platform.iOS.Application:Include}")]
	[Require("Source.Include", "Uno-iOS/AppDelegate.h")]
	[Require("Source.Include", "AppDelegateSoftKeyboard.h")]
	public static extern(iOS) class SystemUI
	{
		static public event EventHandler<SystemUIWillResizeEventArgs> TopFrameWillResize;
		static public event EventHandler<SystemUIWillResizeEventArgs> BottomFrameWillResize;

		static public Rect TopFrame { get { return GetStatusBarFrame(); } }
		static public Rect BottomFrame { public get; private set; }

		static public Rect Frame { get; private set; }

		// @property (nonatomic, setter=uSetStatusBarAnimation:) UIStatusBarAnimation uStatusBarAnimation;
		public static StatusBarAnimation uStatusBarAnimation { get; set; }

		static public event EventHandler FrameChanged;
		static private void OnFrameChanged(object s, object a)
		{
			var iDisplay = ((Uno.Platform.iOSDisplay)Uno.Platform.Displays.MainDisplay);
			Frame = iDisplay.Frame;

			var handler = FrameChanged;
			if (handler != null)
				handler(null, EventArgs.Empty);
		}

		//------------------------------------------------------------

		static public void OnCreate()
		{
			((Uno.Platform.iOSDisplay)Uno.Platform.Displays.MainDisplay).FrameChanged += OnFrameChanged;
			OnFrameChanged(null, null);
			EnableKeyboardResizeNotifications();
		}

		static public void OnDestroy()
		{
			DisableKeyboardResizeNotifications();
		}

		[Foreign(Language.ObjC)]
		static void EnableKeyboardResizeNotifications()
		@{
			uAppDelegate* _delegate = (uAppDelegate*)[UIApplication sharedApplication].delegate;

			[[NSNotificationCenter defaultCenter]
			 addObserver:_delegate selector:@selector(uKeyboardWillChangeFrame:)
			 name:UIKeyboardWillShowNotification object:nil];
			
			[[NSNotificationCenter defaultCenter]
			 addObserver:_delegate
			 selector:@selector(uKeyboardWillChangeFrame:)
			 name:UIKeyboardWillHideNotification object:nil];
		@}

		
		[Foreign(Language.ObjC)]
		static void DisableKeyboardResizeNotifications()
		@{
			uAppDelegate* _delegate = (uAppDelegate*)[UIApplication sharedApplication].delegate;
			
			[[NSNotificationCenter defaultCenter]
			 removeObserver:_delegate
			 name:UIKeyboardWillShowNotification object:nil];
			
			[[NSNotificationCenter defaultCenter]
			 removeObserver:_delegate
			 name:UIKeyboardWillHideNotification object:nil];
		@}

		//------------------------------------------------------------
		static bool _isTopFrameVisible = true;
		public static bool IsTopFrameVisible
		{
			get { return _isTopFrameVisible; }
			set
			{
				if (value == _isTopFrameVisible)
					return;

				_isTopFrameVisible = value;

				var endFrame = uCGRect.Zero;
				double animationDuration = 0.5;

				if (!value)
				{
					var screenSize = Pre_iOS8_HandleDeviceOrientation_Size(extern<uCGSize>"[UIScreen mainScreen].bounds.size", null);

					// Assume standard status bar, here.
					// application:willChangeStatusBarFrame: will handle deviations.

					endFrame = extern<uCGRect>(screenSize)"CGRectMake(0., 0., $0.width, 20.)";
					animationDuration = 0.25;
				}

				if (uStatusBarAnimation == extern<int>"(int)UIStatusBarAnimationNone")
					animationDuration = 0;

				_statusBarWillChangeFrame(endFrame, animationDuration);
				extern(!value)"[UIApplication sharedApplication].statusBarHidden = $0";

				extern(animationDuration)"[UIView animateWithDuration:$0 animations:^{ [(::uAppDelegate*)[UIApplication sharedApplication].delegate setNeedsStatusBarAppearanceUpdate]; }]";
			}
		}

		public static extern uCGSize Pre_iOS8_HandleDeviceOrientation_Size(uCGSize cgsize, ObjC.Object view)
		@{
			if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1
				&& @{Uno.Platform.iOS.Application.IsLandscape():Call()}
				&& (!$1 || @{Uno.Platform.iOS.Application.IsRootView(ObjC.Object):Call($1)}))
			{
				// Transpose dimensions
				return CGSizeMake($0.height, $0.width);
			}

			return $0;
		@}

		static public bool IsBottomFrameVisible
		{
			//{TODO} need better metric than this
			get { return (BottomFrame.Top - BottomFrame.Bottom) > 0; }
		}

		public static ObjC.Object RootView
		{
			get { return Uno.Platform.iOS.Application.GetRootView(); }
			set { Uno.Platform.iOS.Application.SetRootView(value); }
		}

		[Foreign(Language.ObjC)]
		static void SetAsRootView(ObjC.Object view)
		@{

		@}

		static void OnWillResize(SystemUIWillResizeEventArgs args)
		{
			if (args.ID==SystemUIID.TopFrame) {
				EventHandler<SystemUIWillResizeEventArgs> handler = TopFrameWillResize;
				if (handler != null)
					handler(null, args);
			} else {
				BottomFrame = args.EndFrame;
				EventHandler<SystemUIWillResizeEventArgs> handler = BottomFrameWillResize;
				if (handler != null)
					handler(null, args);
			}
		}

		static Rect GetStatusBarFrame()
		{
			var density = Uno.Platform.Displays.MainDisplay.Density;
			return Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(
					extern<Uno.Platform.iOS.uCGRect>"[UIApplication sharedApplication].statusBarFrame", null),
				density);
		}

		static void _statusBarWillChangeFrame(Uno.Platform.iOS.uCGRect _endFrame, double animationDuration)
		{
			if (Lifecycle.State == ApplicationState.Uninitialized)
				return;

			var density = Uno.Platform.Displays.MainDisplay.Density;

			Rect startFrame = Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(
					extern<Uno.Platform.iOS.uCGRect>"[UIApplication sharedApplication].statusBarFrame", null),
				density);

			Rect endFrame = Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(_endFrame, null),
				density);

			Fuse.Platform.SystemUIResizeReason reason;

			if (startFrame.Height == 0)
				reason = Fuse.Platform.SystemUIResizeReason.WillShow;
			else if (endFrame.Height == 0)
				reason = Fuse.Platform.SystemUIResizeReason.WillHide;
			else
				reason = Fuse.Platform.SystemUIResizeReason.WillChangeFrame;

			var args = new SystemUIWillResizeEventArgs(SystemUIID.TopFrame, reason, endFrame, startFrame, animationDuration, 1);

			OnWillResize(args);
		}

		static void uKeyboardWillChangeFrame (Uno.Platform.iOS.uCGRect frameBegin, Uno.Platform.iOS.uCGRect frameEnd, double animationDuration, int animationCurve, Fuse.Platform.SystemUIResizeReason reason)
		{
			var density = Uno.Platform.Displays.MainDisplay.Density;

			Rect startFrame = Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(frameBegin, null),
				density);

			Rect endFrame = Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(frameEnd, null),
				density);

			var args = new SystemUIWillResizeEventArgs(SystemUIID.BottomFrame, reason, endFrame, startFrame, animationDuration, 1);

			OnWillResize(args);
		}

		//------------------------------------------------------------

		// @property (nonatomic, readonly) @{Uno.Rect} uStatusBarFrame;
		static Rect uStatusBarFrame()
		{
			uCGRect frame = extern<uCGRect>"[UIApplication sharedApplication].statusBarFrame";
			var scale = Uno.Platform.Displays.MainDisplay.Density;
			return Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(frame, null),
				scale);
		}

		static StatusBarStyle _style = StatusBarStyle.Dark;
		// @property (nonatomic, setter=uSetStatusBarStyle:) UIStatusBarStyle uStatusBarStyle;
		public static StatusBarStyle uStatusBarStyle
		{
			get { return _style; }
			set
			{
				if (value == _style)
					return;

				_style = value;
				if (extern<bool>"[[UIApplication sharedApplication].delegate respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]")
				{
					if (uStatusBarAnimation == extern<int>"(int)UIStatusBarAnimationNone")
						extern "[(::uAppDelegate*)[UIApplication sharedApplication].delegate setNeedsStatusBarAppearanceUpdate]";
					else
						extern "[UIView animateWithDuration:0.33 animations:^{ [(::uAppDelegate*)[UIApplication sharedApplication].delegate setNeedsStatusBarAppearanceUpdate]; }]";
				}
			}
		}

		static public void EnterFullscreen()
		{
			IsTopFrameVisible = false;
		}
	}
}
