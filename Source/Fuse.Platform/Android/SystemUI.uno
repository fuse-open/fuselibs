using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform2;
using Fuse.Platform;

namespace Fuse.Platform
{

	[ForeignInclude(Language.Java,
		"android.annotation.SuppressLint", "android.app.ActionBar",
		"android.app.Activity", "android.os.Build",
		"android.util.DisplayMetrics", "android.view.Gravity",
		"android.view.View.OnLayoutChangeListener", "android.view.View",
		"android.view.ViewTreeObserver", "android.view.Window",
		"android.view.WindowManager", "android.widget.FrameLayout",
		"android.content.Context", "android.content.pm.ActivityInfo",
		"android.view.Surface", "java.lang.reflect.Method",
		"android.graphics.Color", "android.view.WindowManager.LayoutParams")]

	static extern(android) class SystemUI
	{
		static Rect TopFrame { get { return GetStatusBarFrame(); } }
		static  Rect BottomFrame { get { return GetBottomBarFrame(); } }

		static public event Action MarginsChanged;
		static public event Action<ScreenOrientation> DeviceOrientationChanged;
		static public event Action<float> TextScaleFactorChanged;

		static public float4 DeviceMargins
		{
			get
			{
				//TODO: https://github.com/fuse-open/fuselibs/issues/1014
				return float4(0);
			}
		}

		static public float4 SafeMargins
		{
			get
			{
				var top = TopFrame.Height;
				var bottom = BottomFrame.Height;
				return float4(0,top,0,bottom) / Density;
			}
		}

		static public float4 StaticMargins
		{
			get
			{
				var top = TopFrame.Height;
				var bottom = _staticBottomFrameSize;
				return float4(0,top,0,bottom) / Density;
			}
		}

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

		static Java.Object _keyboardListener; //ViewTreeObserver.OnGlobalLayoutListener
		static Java.Object SuperLayout; //FrameLayout
		static Java.Object RootLayout; //FrameLayout
		static Java.Object layoutAttachedTo; //FrameLayout
		static int realWidth = 0;
		static int realHeight = 0;
		static bool firstSizing = true;
		static bool keyboardVisible = false;
		static int lastKeyboardHeight = 0;
		static bool hasCachedStatusBarSize = false;
		static int cachedOpenSize = 0;
		static int _systemUIState;
		static int _statusbarStyle = 0; // dark
		static int _topFrameSize;
		static int _bottomFrameSize;
		static int _staticBottomFrameSize;

		//------------------------------------------------------------
		// Taken from platform2 display

		static float _density = 1;
		static public float Density
		{
			get { return _density; }
			private set { _density = value; }
		}
		static private Rect _frame;
		static public Rect Frame
		{
			get { return _frame; }
			private set
			{
				if (Rect.Equals(_frame, value))
					return;

				_frame = value;
				OnFrameChanged();
			}
		}

		static public event EventHandler FrameChanged;
		static private void OnFrameChanged()
		{
			EventHandler handler = FrameChanged;
			if (handler != null)
				handler(null, EventArgs.Empty);
		}

		//------------------------------------------------------------

		[Foreign(Language.Java)]
		static void HookOntoRawActivityEvents()
		@{
			com.fuse.Activity.SubscribeToLifecycleChange(new com.fuse.Activity.ActivityListener()
			{
				@Override public void onStop() {}
				@Override public void onStart() {}
				@Override public void onWindowFocusChanged(boolean hasFocus) {}

				@Override public void onPause() { @{OnPause():call()}; }
				@Override public void onResume() { @{OnResume():call()}; }
				@Override public void onDestroy() { @{OnDestroy():call()}; }
				@Override public void onConfigurationChanged(android.content.res.Configuration config) { @{OnConfigChanged():call()}; }
			});
		@}


		[Foreign(Language.Java)]
		static void OnPause()
		@{
			((FrameLayout)@{RootLayout}).setVisibility(View.GONE);
		@}

		[Foreign(Language.Java)]
		static void OnResume()
		@{
			@{UpdateStatusBar():call()};
			((FrameLayout)@{RootLayout}).setVisibility(View.VISIBLE);
			@{ReadConfiguration():call()};
		@}

		static void OnDestroy()
		{
			Detach();
			_bottomFrameSize = 0;
		}

		static void OnConfigChanged()
		{
			ReadConfiguration();
			CompensateRootLayoutForSystemUI();
		}

		[Foreign(Language.Java)]
		static public void ReadConfiguration()
		@{
			float fontScale = com.fuse.Activity.getRootActivity().getResources().getConfiguration().fontScale;
			@{UpdateTextScaleFactor(float):call(fontScale)};

		@}

		static void UpdateTextScaleFactor(float _textScaleFactor)
		{
			TextScaleFactor = _textScaleFactor;
		}

		[Foreign(Language.Java)]
		static public void OnCreate()
		@{
			Activity activity = com.fuse.Activity.getRootActivity();

			// status bar
			activity.getWindow().requestFeature(Window.FEATURE_ACTION_BAR);
			#if @(project.mobile.showStatusbar)
				@{HideActionBar():call()};
			#endif

			// layouts
			if (@{SuperLayout}==null) @{CreateLayouts():call()};
			activity.getWindow().setContentView(((FrameLayout)@{SuperLayout}));
			ViewTreeObserver.OnGlobalLayoutListener kl = new ViewTreeObserver.OnGlobalLayoutListener() { public void onGlobalLayout() { @{unoOnGlobalLayout():call()}; }};
			@{_keyboardListener:set(kl)};
			@{Attach(Java.Object):call(@{RootLayout})};
			@{HookOntoRawActivityEvents():call()};
		@}

		[Foreign(Language.Java)]
		static public void CreateLayouts()
		@{
			Activity activity = com.fuse.Activity.getRootActivity();

			FrameLayout superLayout = new FrameLayout(activity);
			FrameLayout rootLayout = new FrameLayout(activity);
			@{SuperLayout:set(superLayout)};
			@{RootLayout:set(rootLayout)};
			superLayout.addOnLayoutChangeListener((OnLayoutChangeListener)@{MakePostV11LayoutChangeListener():call()});

			superLayout.addView(((FrameLayout)@{RootLayout}));
			@{SetFrame(Java.Object,int,int,int):call(@{RootLayout}, 0, 0, @{GetRealDisplayHeight():call()})};
			@{CompensateRootLayoutForSystemUI():call()};
		@}

		//------------------------------------------------------------

		static public bool IsTopFrameVisible
		{
			get {
				return GetStatusBarHeight() > 0.0;
			}
			set {
				if (value)
					ShowStatusBar();
				else
					HideStatusBar();
			}
		}

		static public bool IsBottomFrameVisible
		{
			//{TODO} need better metric than this
			get { return (BottomFrame.Top - BottomFrame.Bottom) > 0; }
		}


		[Foreign(Language.Java)]
		static void HideActionBar()
		@{
			// ActionBar is ugly, hide it
			// details: http://stackoverflow.com/a/14167949/574033
			ActionBar actionBar = com.fuse.Activity.getRootActivity().getActionBar();
			#if @(project.mobile.showStatusbar)
			if (actionBar!=null)
				actionBar.hide();
			#endif
		@}

		[Foreign(Language.Java)]
		static float GetStatusBarHeight()
		@{
			int result = 0;
			if (@{_systemUIState}==@{SysUIState.Normal})
			{
				int resourceId = com.fuse.Activity.getRootActivity().getResources().getIdentifier("status_bar_height", "dimen", "android");
				if (resourceId > 0)
				{
					result = com.fuse.Activity.getRootActivity().getResources().getDimensionPixelSize(resourceId);
				}
				if (result == 0)
				{
					if (@{hasCachedStatusBarSize})
					{
					result = @{cachedOpenSize};
					}
				} else {
					@{hasCachedStatusBarSize:set(true)};
					@{cachedOpenSize:set(result)};
				}
			}
			return (float)result;
		@}

		[Foreign(Language.Java)]
		static public void ShowStatusBar()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run()
			{
				@{_systemUIState:set(@{SysUIState.Normal})};
				View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
				// Hide the status bar.
				decorView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);
				@{HideActionBar():call()};
				@{CompensateRootLayoutForSystemUI():call()};
				@{cppOnTopFrameChanged(int):call((int)@{GetStatusBarHeight():call()})};
			}});
		@}


		[Foreign(Language.Java)]
		static public void HideStatusBar()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run()
			{
				@{_systemUIState:set(@{SysUIState.StatusBarHidden})};
				View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
				// Hide the status bar.
				decorView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN);
				@{HideActionBar():call()};
				@{CompensateRootLayoutForSystemUI():call()};
				@{cppOnTopFrameChanged(int):call(0)};
			}});
		@}

		[Foreign(Language.Java)]
		public static int GetStatusBarColor()
		@{
			Window window = com.fuse.Activity.getRootActivity().getWindow();
			if (Build.VERSION.SDK_INT >= 21)
				return window.getStatusBarColor();
			else
				return Color.BLACK;
		@}

		[Foreign(Language.Java)]
		public static bool SetStatusBarColor(int color)
		@{
			Window window = com.fuse.Activity.getRootActivity().getWindow();
			if (Build.VERSION.SDK_INT >= 21)
			{
				window.addFlags(LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
				window.setStatusBarColor(color);
				return true;
			}
			else
				return false;
		@}

		[Foreign(Language.Java)]
		public static bool SetDarkStatusBarStyle()
		@{
			if (android.os.Build.VERSION.SDK_INT >= 23)
			{
				View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
				int flags = decorView.getSystemUiVisibility();
				flags |= 0x2000;
				decorView.setSystemUiVisibility(flags);
				@{_statusbarStyle:set(@{StatusBarStyle.Dark})};
				return true;
			}
			return false;
		@}

		[Foreign(Language.Java)]
		public static bool SetLightStatusBarStyle()
		@{
			if (android.os.Build.VERSION.SDK_INT >= 23)
			{
				View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
				int flags = decorView.getSystemUiVisibility();
				flags &= ~0x2000;
				decorView.setSystemUiVisibility(flags);
				@{_statusbarStyle:set(@{StatusBarStyle.Light})};
				return true;
			}
			return false;
		@}

		static public void UpdateStatusBar()
		{
			// this method reapplies the current status bar settings.
			// It does not change whether it is show or hiding.
			switch(_systemUIState)
			{
			case SysUIState.Normal:
				ShowStatusBar();
				break;
			case SysUIState.StatusBarHidden:
				HideStatusBar();
				break;
			case SysUIState.Fullscreen:
				EnterFullscreen();
				break;
			}
			// this method reapplies the current status bar style settings.
			// It does not change whether it is dark or lightt.
			switch(_statusbarStyle)
			{
				case StatusBarStyle.Dark:
					SetDarkStatusBarStyle();
					break;
				case StatusBarStyle.Light:
					SetLightStatusBarStyle();
					break;
			}
		}


		[Foreign(Language.Java)]
		static void EnterFullscreen()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run() {
				@{_systemUIState:set(@{SysUIState.Fullscreen})};
				View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
				// Hide the status bar.
				decorView.setSystemUiVisibility(
						View.SYSTEM_UI_FLAG_LAYOUT_STABLE
						| View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
						| View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
						| View.SYSTEM_UI_FLAG_HIDE_NAVIGATION // hide nav bar
						| View.SYSTEM_UI_FLAG_FULLSCREEN // hide status bar
						| View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
				@{HideActionBar():call()};
				@{CompensateRootLayoutForSystemUI():call()};
				@{cppOnTopFrameChanged(int):call(0)};
			}});
		@}

		static extern(Android) Rect GetStatusBarFrame()
		{
			var dispSize = _GetRootDisplaySize();
			var height = GetStatusBarHeight();
			return new Rect(float2(0, 0), float2(dispSize.X, height));
		}

		static extern(Android) Rect GetBottomBarFrame()
		{
			var dispSize = _GetRootDisplaySize();
			var height = _bottomFrameSize;
			return new Rect(float2(0, 0), float2(dispSize.X, height));
		}

		static void OnWillResize()
		{
			if (MarginsChanged != null)
				MarginsChanged();
		}

		//======================================================================
		// Display
		//

		[Foreign(Language.Java)]
		static public void CalcRealSizes()
		@{
			//cache initialSize so we have something sane
			android.view.Display display = com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay();
			DisplayMetrics realMetrics = new DisplayMetrics();
			display.getRealMetrics(realMetrics);
			@{realWidth:set(realMetrics.widthPixels)};
			@{realHeight:set(realMetrics.heightPixels)};
			if (@{SuperLayout}!=null) {
				int tmp = ((FrameLayout)@{SuperLayout}).getWidth();
				if (tmp!=0 && tmp!= @{realHeight} && @{realWidth}!=tmp) {
					@{realWidth:set(tmp)};
				}
			}
		@}

		[Foreign(Language.Java)]
		static public Java.Object GetDisplayMetrics()
		@{
			DisplayMetrics metrics = new DisplayMetrics();
			com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
			return metrics;
		@}

		static public int GetRealDisplayWidth()
		{
			CalcRealSizes();
			return realWidth;
		}

		static public int GetRealDisplayHeight()
		{
			CalcRealSizes();
			return realHeight;
		}

		//======================================================================
		// AppLayout
		//

		public static Java.Object RootView
		{
			get { return RootLayout; }
			set { SetAsRootView(value); }
		}

		[Foreign(Language.Java)]
		static void SetAsRootView(Java.Object view)
		@{
			@{Fuse.Platform.SystemUI.OnCreate():call()};

			final View uview = (View)view;
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run() {
				if (uview==null)
				{
					((FrameLayout)@{RootLayout}).removeAllViews();
				}
				else
				{
					if (((FrameLayout)@{RootLayout}).getChildCount()>0)
					{
						((FrameLayout)@{RootLayout}).removeAllViews();
					}
					((FrameLayout)@{RootLayout}).addView(uview, 0);
				}
			}});
		@}


		[Require("source.include", "uDroid/GLHelper.h")]
		static void cppOnConfigChanged()
		{
			extern "GLHelper::SwapBackToBackgroundSurface()";
			ResetGeometry();
		}

		[Require("source.include", "uDroid/GLHelper.h")]
		static void ResetGeometry()
		{
			extern "GLHelper::SwapBackToBackgroundSurface()";
			var density = GetDensity();
			var pos = float2(0f, 0f);
			var size = _GetRootDisplaySize();
			var frame = new Rect(pos, size);
			Frame = frame;
			Density = density;
		}

		[Foreign(Language.Java)]
		static float GetDensity()
		@{
				DisplayMetrics m = (DisplayMetrics)@{GetDisplayMetrics():call()};
			return m.density;
		@}


		[Foreign(Language.Java)]
		static Java.Object MakePostV11LayoutChangeListener()
		@{
			return new OnLayoutChangeListener() {

				int lastWidth = (int)@{GetRealDisplayWidth():call()};
				int lastHeight = @{GetRealDisplayHeight():call()};

				@Override
					public void onLayoutChange(View v, int left, int top, int right, int bottom, int oldLeft, int oldTop, int oldRight, int oldBottom) {
					int newWidth = right - left;
					int newHeight = bottom - top;
					if (newWidth!=lastWidth || newHeight!=lastHeight) {
						lastHeight = newHeight;
						lastWidth = newWidth;
						@{cppOnConfigChanged():call()};
						ViewTreeObserver.OnGlobalLayoutListener kl = ((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener});
						if (kl!=null) @{ResendFrameSizes():call()};
					}
				}
			};
		@}

		static public void CompensateRootLayoutForSystemUI()
		{
			CalcRealSizes();
			if (RootLayout != null) {
				int compensation = -(int)GetStatusBarHeight();
				SetFrame(RootLayout, 0, compensation, GetRealDisplayHeight());
			}
		}

		[Foreign(Language.Java)]
		static void SetFrame(Java.Object view, int originX, int originY, int height)
		@{
		int width = FrameLayout.LayoutParams.MATCH_PARENT;
			View uview = (View)view;
			FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(width,height);
			lp.leftMargin = originX;
			lp.topMargin = originY;
			uview.setLayoutParams(lp);
		@}

		//======================================================================
		// KeyboardListener
		//

		[Foreign(Language.Java)]
		static public void Attach(Java.Object _layout)
		@{
			FrameLayout layout = (FrameLayout)_layout;
			if (@{layoutAttachedTo}!=null) { return; }
			@{layoutAttachedTo:set(layout)};
			layout.getViewTreeObserver().addOnGlobalLayoutListener(((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener}));
		@}

		[Foreign(Language.Java)]
		static public void Detach() // Also use this for DetachFromActivity()
		@{
			if (@{layoutAttachedTo}!=null) {
				((FrameLayout)@{RootLayout}).getViewTreeObserver().removeOnGlobalLayoutListener(((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener}));
			}
			@{layoutAttachedTo:set(null)};
		@}

		[Foreign(Language.Java)]
		static void unoOnGlobalLayout()
		@{
			int heightDiff = @{GetRealDisplayHeight():call()}-((FrameLayout)@{SuperLayout}).getHeight();
			heightDiff -= @{GetStatusBarHeight():call()};
			int contentViewTop = com.fuse.Activity.getRootActivity().getWindow().findViewById(Window.ID_ANDROID_CONTENT).getTop();
			boolean keyboardClosed = (heightDiff-contentViewTop)<(@{GetRealDisplayHeight():call()}/4);
			if (heightDiff!=@{lastKeyboardHeight} || @{firstSizing}) {
				if (keyboardClosed) {
					@{onHideKeyboard(int,bool):call(heightDiff, @{firstSizing})};
				} else {
					@{onShowKeyboard(int,bool):call(heightDiff, @{firstSizing})};
				}
			}
			@{firstSizing:set(false)};
		@}

		static void onShowKeyboard(int keyboardHeight, bool force)
		{
			keyboardVisible=true;
			if (lastKeyboardHeight!=keyboardHeight || force)
			{
				lastKeyboardHeight = keyboardHeight;
				cppOnBottomFrameChanged(keyboardHeight);
			}
		}

		static void onHideKeyboard(int keyboardHeight, bool force)
		{
			if (keyboardVisible || force)
			{
				keyboardVisible=false;
				lastKeyboardHeight = keyboardHeight;
				cppOnBottomFrameChanged(keyboardHeight);
			}
		}

		[Foreign(Language.Java)]
		static int GetSuperLayoutHeight()
		@{
			return (int)((FrameLayout)@{SuperLayout}).getHeight();
		@}

		static public void ResendFrameSizes()
		{
			int heightDiff = GetRealDisplayHeight()-GetSuperLayoutHeight();
			heightDiff -= (int)GetStatusBarHeight();
			lastKeyboardHeight = heightDiff;
			cppOnBottomFrameChanged(heightDiff);
		}


		static void cppOnBottomFrameChanged (int height)
		{
			SystemUIResizeReason resizeReason = SystemUIResizeReason.WillChangeFrame;

			float2 size = _GetRootDisplaySize();

			float2 start_pos = float2(0, size.Y - _bottomFrameSize);
			float2 start_size = float2(size.X, _bottomFrameSize);

			float2 end_pos = float2(0, size.Y - height);
			float2 end_size = float2(size.X, height);

			Rect startFrame = new Rect(start_pos, start_size);
			Rect endFrame = new Rect(end_pos, end_size);

			_bottomFrameSize = height;
			//TODO: There must be a proper way to do this. This horrible check is inhereted from the BottomFrameBackground to detect a keyboard size
			if (height < 150)
				_staticBottomFrameSize = height;

			SystemUI.OnWillResize();
		}

		static void cppOnTopFrameChanged (int height)
		{
			if (_topFrameSize != height)
			{
				_topFrameSize = height;
				OnWillResize();
			}
		}

		// from android
		static float2 _GetRootDisplaySize()
		{
			float w = (int)GetRealDisplayWidth();
			float h = (int)GetRealDisplayHeight();
			return float2(w, h);
		}


		static public int APILevel { get { return GetAPILevel(); } }
		static public int3 OSVersion
		{
			get
			{
				int major = 0;
				int minor = 0;
				int revision = 0;
				try {
					var ver = GetOSVersion();
					string[] parts = ver.Split( new []{'.'});
					if (parts.Length > 0)
						Int.TryParse( parts[0], out major );
					if (parts.Length > 1)
						Int.TryParse( parts[1], out minor );
					if (parts.Length > 2)
						Int.TryParse( parts[2], out revision );
				} catch( Exception ex ) {
					//safe to ignore, may have partial results in major/minor, which is good
				}
				return int3(major, minor, revision);
			}
		}

		[Foreign(Language.Java)]
		static int GetAPILevel()
		@{
			return android.os.Build.VERSION.SDK_INT;
		@}

		[Foreign(Language.Java)]
		static string GetOSVersion()
		@{
			return android.os.Build.VERSION.RELEASE;
		@}

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

		[Foreign(Language.Java)]
		static int GetCurrentScreenOrientation()
		@{
			final int rotation = ((WindowManager) com.fuse.Activity.getRootActivity().getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation();
			switch (rotation)
			{
				case Surface.ROTATION_0:
					return 0;
				case Surface.ROTATION_270:
					return 1;
				case Surface.ROTATION_90:
					return 2;
				case Surface.ROTATION_180:
					return 3;
				default:
					return 4;
			}
		@}

		[Foreign(Language.Java)]
		static void SetCurrentScreenOrientation(int orientation)
		@{
			switch (orientation)
			{
				case 0:
				{
					com.fuse.Activity.getRootActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
					return;
				}
				case 1:
				{
					com.fuse.Activity.getRootActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
					return;
				}
				case 2:
				{
					com.fuse.Activity.getRootActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
					return;
				}
				case 3:
				{
					com.fuse.Activity.getRootActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT);
					return;
				}
				default:
				{
					com.fuse.Activity.getRootActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER);
				}
			}
		@}
	}
}
