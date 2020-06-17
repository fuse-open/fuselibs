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
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "@{Uno.Platform.iOSDisplay:Include}")]
	[Require("Source.Include", "@{Uno.Platform.iOS.Application:Include}")]
	[Require("Source.Include", "Uno-iOS/AppDelegate.h")]
	[Require("Source.Include","objc/message.h")]
	[Require("Source.Include", "NotificationCenterContext.h")]
	static extern(iOS) class SystemUI
	{
		static Rect _bottomFrame;

		static public Rect Frame { get; private set; }

		static public float4 DeviceMargins
		{
			get
			{
				return GetSafeFrame();
			}
		}
		static public float4 SafeMargins
		{
			get
			{
				float4 sf = GetSafeFrame();
				sf.Y = Math.Max(sf.Y, GetStatusBarFrame().Height);
				sf.W = Math.Max(sf.W, _bottomFrame.Height);
				return sf;
			}
		}
		static public float4 StaticMargins
		{
			get
			{
				float4 sm = GetSafeFrame();
				sm.Y = Math.Max(sm.Y, GetStatusBarFrame().Height);
				return sm;
			}
		}

		static public event Action MarginsChanged;
		static public event Action<ScreenOrientation> DeviceOrientationChanged;
		static public event Action<float> TextScaleFactorChanged;

		static float _textScaleFactor = 1.0f;
		static public float TextScaleFactor
		{
			get { return _textScaleFactor; }
			private set
			{
				if (_textScaleFactor != value)
				{
					_textScaleFactor = value;
					if (TextScaleFactorChanged != null)
						TextScaleFactorChanged(value);
				}
			}
		}

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
			Uno.Platform.CoreApp.EnteringForeground += OnEnteringForeground;
			OnFrameChanged(null, null);
			SetupNotificationCenterObservers(_notificationContext);
		}

		static public void OnDestroy()
		{
			RemoveNotificationCenterObservers(_notificationContext);
			Uno.Platform.CoreApp.EnteringForeground -= OnEnteringForeground;
		}

		static void OnEnteringForeground(Uno.Platform.ApplicationState newState)
		{
			ReadConfiguration(_notificationContext);
		}

		[Foreign(Language.ObjC)]
		static void ReadConfiguration(ObjC.Object notificationContext)
		@{
			uNotificationCenterContext* ctx = (uNotificationCenterContext*)notificationContext;
			CGFloat textScaleFactor = [ctx textScaleFactor];
			@{uTextScaleFactorDidChange(float):Call(textScaleFactor)};
		@}

		static ObjC.Object _notificationContext = NewNotificationCenterContext();

		[Foreign(Language.ObjC)]
		static ObjC.Object NewNotificationCenterContext()
		@{
			return [[uNotificationCenterContext alloc] init];
		@}

		[Foreign(Language.ObjC)]
		static void SetupNotificationCenterObservers(ObjC.Object notificationContext)
		@{
			uNotificationCenterContext* ctx = (uNotificationCenterContext*)notificationContext;
			 NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

			[center
			 addObserver:ctx selector:@selector(uKeyboardWillChangeFrame:)
			 name:UIKeyboardWillShowNotification object:nil];

			[center
			 addObserver:ctx
			 selector:@selector(uKeyboardWillChangeFrame:)
			 name:UIKeyboardWillHideNotification object:nil];

			[center
			 addObserver:ctx
			 selector:@selector(onUserSettingsChanged:)
			 name:UIContentSizeCategoryDidChangeNotification object:nil];
		@}


		[Foreign(Language.ObjC)]
		static void RemoveNotificationCenterObservers(ObjC.Object notificationContext)
		@{
			uNotificationCenterContext* ctx = (uNotificationCenterContext*)notificationContext;

			[[NSNotificationCenter defaultCenter]
			 removeObserver:ctx
			 name:UIKeyboardWillShowNotification object:nil];

			[[NSNotificationCenter defaultCenter]
			 removeObserver:ctx
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

		static public int3 OSVersion
		{
			get
			{
				int m,n,r;
				GetOSVersion(out m, out n, out r);
				return int3(m,n,r);
			}
		}

		[Foreign(Language.ObjC)]
		static void GetOSVersion( out int major, out int minor, out int revision )
		@{
			if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_8_0)
			{
				//we don't really need specifics before this point
				*major = (int)NSFoundationVersionNumber;
				*minor = ((int)NSFoundationVersionNumber * 10) % 10;
				*revision = 0;
			}
			else
			{
				NSOperatingSystemVersion ver = [[NSProcessInfo processInfo] operatingSystemVersion];
				*major = (int)ver.majorVersion;
				*minor = (int)ver.minorVersion;
				*revision = (int)ver.patchVersion;
			}
		@}

		static public bool IsBottomFrameVisible
		{
			//{TODO} need better metric than this
			get { return (_bottomFrame.Top - _bottomFrame.Bottom) > 0; }
		}

		public static ObjC.Object RootView
		{
			get { return Uno.Platform.iOS.Application.GetRootView(); }
			set { Uno.Platform.iOS.Application.SetRootView(value); }
		}

		static void OnWillResize()
		{
			if (MarginsChanged != null)
				MarginsChanged();
		}

		static Rect GetStatusBarFrame()
		{
			return Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(
					extern<Uno.Platform.iOS.uCGRect>"[UIApplication sharedApplication].statusBarFrame", null),
				1);
		}

		static float4 GetSafeFrame()
		{
			int major, minor, revision;
			GetOSVersion(out major, out minor, out revision);
			if (major >= 11)
			{
				float l, t, r, b;
				GetSafeArea( out l, out t, out r, out b );
				return float4(l,t,r,b);
			}

			return float4(0);
		}

		//TODO: https://github.com/fuse-open/fuselibs/issues/1015
		//we also need to listen for safeAreInsets changes and call MarginsChanged
		[Foreign(Language.ObjC)]
		static void GetSafeArea(out float l, out float t, out float r, out float b)
		@{
			UIView* view = [UIApplication sharedApplication].keyWindow.rootViewController.view;

		#if defined(__IPHONE_11_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
			//Only on iOS11, taken care of in the GetSafeFrame code (we don't use @available in order to support older XCode version)
			UIEdgeInsets insets = view.safeAreaInsets;
			*l = insets.left;
			*t = insets.top;
			*r = insets.right;
			*b = insets.bottom;
		#else
			*l = *t = *r = *b = 0;
		#endif
		@}

		static void _statusBarWillChangeFrame(Uno.Platform.iOS.uCGRect _endFrame, double animationDuration)
		{
			if (Lifecycle.State == ApplicationState.Uninitialized)
				return;
			OnWillResize();
		}

		static void _statusBarDidChangeFrame(Uno.Platform.iOS.uCGRect _endFrame)
		{
		}

		static void uKeyboardWillChangeFrame (Uno.Platform.iOS.uCGRect frameBegin, Uno.Platform.iOS.uCGRect frameEnd, double animationDuration, int animationCurve, Fuse.Platform.SystemUIResizeReason reason)
		{
			_bottomFrame = Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(frameEnd, null),
				1);
			OnWillResize();
		}

		static void uTextScaleFactorDidChange(float _textScaleFactor)
		{
			TextScaleFactor = _textScaleFactor;
		}

		//------------------------------------------------------------

		// @property (nonatomic, readonly) @{Uno.Rect} uStatusBarFrame;
		static Rect uStatusBarFrame()
		{
			uCGRect frame = extern<uCGRect>"[UIApplication sharedApplication].statusBarFrame";
			return Uno.Platform.iOS.Support.CGRectToUnoRect(
				Uno.Platform.iOS.Support.Pre_iOS8_HandleDeviceOrientation_Rect(frame, null),
				1);
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

		static public int supportedOrientation = extern<int>"UIInterfaceOrientationMaskAll";

		public static ScreenOrientation DeviceOrientation
		{
			get
			{
				var orientation = GetCurrentScreenOrientation();
				switch (orientation)
				{
					case 0:
						return ScreenOrientation.Portrait;
					case 1:
						return ScreenOrientation.LandscapeLeft;
					case 2:
						return ScreenOrientation.LandscapeRight;
					case 3:
						return ScreenOrientation.PortraitUpsideDown;
					default:
						return ScreenOrientation.Default;
				}
			}
			set
			{
				if (DeviceOrientation != value)
				{
					SetCurrentScreenOrientation(value);
					if (DeviceOrientationChanged != null)
						DeviceOrientationChanged(value);
				}
			}
		}

		[Foreign(Language.ObjC)]
		static int GetCurrentScreenOrientation()
		@{
			#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
			 UIInterfaceOrientation mask = [[UIApplication sharedApplication].windows firstObject].windowScene.interfaceOrientation;
			 switch (mask)
			 {
			 	case UIInterfaceOrientationPortrait:
			 		return 0;
			 	case UIInterfaceOrientationLandscapeLeft:
			 		return 1;
			 	case UIInterfaceOrientationLandscapeRight:
			 		return 2;
			 	case UIInterfaceOrientationPortraitUpsideDown:
			 		return 3;
			 	case UIInterfaceOrientationUnknown:
			 		return 4;
			 }
			#else
			UIInterfaceOrientationMask mask = [[UIApplication sharedApplication] statusBarOrientation];
			switch (mask)
			{
				case UIInterfaceOrientationMaskPortrait:
					return 0;
				case UIInterfaceOrientationMaskLandscapeLeft:
					return 1;
				case UIInterfaceOrientationMaskLandscapeRight:
					return 2;
				case UIInterfaceOrientationMaskPortraitUpsideDown:
					return 3;
				default:
					return 4;
			}
			#endif
		@}

		[Foreign(Language.ObjC)]
		static void SetCurrentScreenOrientation(int orientation)
		@{
			NSNumber * value;
			switch (orientation)
			{
				case 0:
				{
					@{supportedOrientation:Set(UIInterfaceOrientationMaskPortrait)};
					value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
					break;
				}
				case 1:
				{
					@{supportedOrientation:Set(UIInterfaceOrientationMaskLandscapeLeft)};
					value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
					break;
				}
				case 2:
				{
					@{supportedOrientation:Set(UIInterfaceOrientationMaskLandscapeRight)};
					value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
					break;
				}
				case 3:
				{
					@{supportedOrientation:Set(UIInterfaceOrientationMaskPortraitUpsideDown)};
					value = [NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown];
					break;
				}
				default:
				{
					@{supportedOrientation:Set(UIInterfaceOrientationMaskAll)};
					value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
				}
			}
			[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
		@}
	}
}
