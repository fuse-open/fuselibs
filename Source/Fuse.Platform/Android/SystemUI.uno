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
		"java.lang.reflect.Method")]

	static extern(android) class SystemUI
	{
		static public event EventHandler<SystemUIWillResizeEventArgs> TopFrameWillResize;
		static public event EventHandler<SystemUIWillResizeEventArgs> BottomFrameWillResize;

		static public Rect TopFrame { get { return GetStatusBarFrame(); } }
		static public Rect BottomFrame { public get; private set; }

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
		static int _topFrameSize;
		static int _bottomFrameSize;

		//------------------------------------------------------------
		// Taken from platform2 display

		static public float Density { get; private set; }
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

				@Override public void onPause() { @{OnPause():Call()}; }
				@Override public void onResume() { @{OnResume():Call()}; }
				@Override public void onDestroy() { @{OnDestroy():Call()}; }
				@Override public void onConfigurationChanged(android.content.res.Configuration config) { @{OnConfigChanged():Call()}; }
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
			@{UpdateStatusBar():Call()};
			((FrameLayout)@{RootLayout}).setVisibility(View.VISIBLE);
		@}

		static void OnDestroy()
		{
			Detach();
			_bottomFrameSize = 0;
		}

		static void OnConfigChanged()
		{
			CompensateRootLayoutForSystemUI();
		}

		[Foreign(Language.Java)]
		static public void OnCreate()
		@{
			Activity activity = com.fuse.Activity.getRootActivity();

			// status bar
			activity.getWindow().requestFeature(Window.FEATURE_ACTION_BAR);
			#if @(Project.Mobile.ShowStatusbar)
				@{HideActionBar():Call()};
			#endif

			// layouts
			if (@{SuperLayout}==null) @{CreateLayouts():Call()};
			activity.getWindow().setContentView(((FrameLayout)@{SuperLayout}));
			ViewTreeObserver.OnGlobalLayoutListener kl = new ViewTreeObserver.OnGlobalLayoutListener() { public void onGlobalLayout() { @{unoOnGlobalLayout():Call()}; }};
			@{_keyboardListener:Set(kl)};
			@{Attach(Java.Object):Call(@{RootLayout})};
			@{HookOntoRawActivityEvents():Call()};
		@}

		[Foreign(Language.Java)]
		static public void CreateLayouts()
		@{
			Activity activity = com.fuse.Activity.getRootActivity();

			FrameLayout superLayout = new FrameLayout(activity);
			FrameLayout rootLayout = new FrameLayout(activity);
			@{SuperLayout:Set(superLayout)};
			@{RootLayout:Set(rootLayout)};
			superLayout.addOnLayoutChangeListener((OnLayoutChangeListener)@{MakePostV11LayoutChangeListener():Call()});

			superLayout.addView(((FrameLayout)@{RootLayout}));
			@{SetFrame(Java.Object,int,int,int):Call(@{RootLayout}, 0, 0, @{GetRealDisplayHeight():Call()})};
			@{CompensateRootLayoutForSystemUI():Call()};
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
			#if @(Project.Mobile.ShowStatusbar)
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
					@{hasCachedStatusBarSize:Set(true)};
					@{cachedOpenSize:Set(result)};
				}
			}
			return (float)result;
		@}

		[Foreign(Language.Java)]
		static public void ShowStatusBar()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run()
			{
				@{_systemUIState:Set(@{SysUIState.Normal})};
				// If the Android version is lower than Jellybean, use this call to hide
				// the status bar.
				if (android.os.Build.VERSION.SDK_INT < 16)
				{
					com.fuse.Activity.getRootActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
				} else {
					View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
					// Hide the status bar.
					decorView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);
					@{HideActionBar():Call()};
				}
				@{CompensateRootLayoutForSystemUI():Call()};
				@{cppOnTopFrameChanged(int):Call((int)@{GetStatusBarHeight():Call()})};
			}});
		@}


		[Foreign(Language.Java)]
		static public void HideStatusBar()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run()
			{
				@{_systemUIState:Set(@{SysUIState.StatusBarHidden})};
				// If the Android version is lower than Jellybean, use this call to hide
				// the status bar.
				if (android.os.Build.VERSION.SDK_INT < 16) {
					com.fuse.Activity.getRootActivity().getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
				} else {
					View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
					// Hide the status bar.
					decorView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN);
					@{HideActionBar():Call()};
				}
				@{CompensateRootLayoutForSystemUI():Call()};
				@{cppOnTopFrameChanged(int):Call(0)};
			}});
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
		}


		[Foreign(Language.Java)]
		static void EnterFullscreen()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() { public void run() {
				@{_systemUIState:Set(@{SysUIState.Fullscreen})};
				// If the Android version is lower than Jellybean, use this call to hide
				// the status bar.
				if (android.os.Build.VERSION.SDK_INT < 19) {
					@{HideStatusBar():Call()};
				} else {
					View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
					// Hide the status bar.
					decorView.setSystemUiVisibility(
							View.SYSTEM_UI_FLAG_LAYOUT_STABLE
							| View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
							| View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
							| View.SYSTEM_UI_FLAG_HIDE_NAVIGATION // hide nav bar
							| View.SYSTEM_UI_FLAG_FULLSCREEN // hide status bar
							| View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
					@{HideActionBar():Call()};
				}
				@{CompensateRootLayoutForSystemUI():Call()};
				@{cppOnTopFrameChanged(int):Call(0)};
			}});
		@}

		static extern(Android) Rect GetStatusBarFrame()
		{
			var dispSize = _GetRootDisplaySize();
			var height = GetStatusBarHeight();
			return new Rect(float2(0, 0), float2(dispSize.X, height));
		}

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

		//======================================================================
		// Display
		//

		[Foreign(Language.Java)]
		static public void CalcRealSizes()
		@{
			//cache initialSize so we have something sane
			android.view.Display display = com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay();
			if (android.os.Build.VERSION.SDK_INT >= 17) {
				//new pleasant way to get real metrics
				DisplayMetrics realMetrics = new DisplayMetrics();
				display.getRealMetrics(realMetrics);
				@{realWidth:Set(realMetrics.widthPixels)};
				@{realHeight:Set(realMetrics.heightPixels)};
			} else if (android.os.Build.VERSION.SDK_INT >= 14) {
				//reflection for this weird in-between time
				try {
					Method mGetRawH = android.view.Display.class.getMethod("getRawHeight");
					Method mGetRawW = android.view.Display.class.getMethod("getRawWidth");
					@{realWidth:Set((Integer)mGetRawW.invoke(display))};
					@{realHeight:Set((Integer)mGetRawH.invoke(display))};
				} catch (Exception e) {
					//this may not be 100% accurate, but it's all we've got
					@{realWidth:Set(display.getWidth())};
					@{realHeight:Set(display.getHeight())};
				}
			} else {
				//This should be close, as lower API devices should not have window navigation bars
				@{realWidth:Set(display.getWidth())};
				@{realHeight:Set(display.getHeight())};
			}

			if (@{SuperLayout}!=null) {
				int tmp = ((FrameLayout)@{SuperLayout}).getWidth();
				if (tmp!=0 && tmp!= @{realHeight} && @{realWidth}!=tmp) {
					@{realWidth:Set(tmp)};
				}
			}
		@}

		[Foreign(Language.Java)]
		static public Java.Object GetDisplayMetrics()
		@{
			DisplayMetrics metrics = new DisplayMetrics();
			if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
				com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
				return metrics;
			} else {
				com.fuse.Activity.getRootActivity().getWindowManager().getDefaultDisplay().getMetrics(metrics);
				return metrics;
			}
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
			@{Fuse.Platform.SystemUI.OnCreate():Call()};

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


		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
		static void cppOnConfigChanged()
		{
			extern "GLHelper::SwapBackToBackgroundSurface()";
			ResetGeometry();
		}

		[Require("Source.Include", "Uno/Graphics/GLHelper.h")]
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
				DisplayMetrics m = (DisplayMetrics)@{GetDisplayMetrics():Call()};
			return m.density;
		@}


		[Foreign(Language.Java)]
		static Java.Object MakePostV11LayoutChangeListener()
		@{
			return new OnLayoutChangeListener() {

				int lastWidth = (int)@{GetRealDisplayWidth():Call()};
				int lastHeight = @{GetRealDisplayHeight():Call()};

				@Override
					public void onLayoutChange(View v, int left, int top, int right, int bottom, int oldLeft, int oldTop, int oldRight, int oldBottom) {
					int newWidth = right - left;
					int newHeight = bottom - top;
					if (newWidth!=lastWidth || newHeight!=lastHeight) {
						lastHeight = newHeight;
						lastWidth = newWidth;
						@{cppOnConfigChanged():Call()};
						ViewTreeObserver.OnGlobalLayoutListener kl = ((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener});
						if (kl!=null) @{ResendFrameSizes():Call()};
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
			if (android.os.Build.VERSION.SDK_INT < 14) {
				lp.gravity = Gravity.TOP;
			}
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
			@{layoutAttachedTo:Set(layout)};
			layout.getViewTreeObserver().addOnGlobalLayoutListener(((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener}));
		@}

		[Foreign(Language.Java)]
		static public void Detach() // Also use this for DetachFromActivity()
		@{
			if (@{layoutAttachedTo}!=null) {
				if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
					((FrameLayout)@{RootLayout}).getViewTreeObserver().removeOnGlobalLayoutListener(((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener}));
				} else {
					((FrameLayout)@{RootLayout}).getViewTreeObserver().removeGlobalOnLayoutListener(((ViewTreeObserver.OnGlobalLayoutListener)@{_keyboardListener}));
				}
			}
			@{layoutAttachedTo:Set(null)};
		@}

		[Foreign(Language.Java)]
		static void unoOnGlobalLayout()
		@{
			int heightDiff = @{GetRealDisplayHeight():Call()}-((FrameLayout)@{SuperLayout}).getHeight();
			heightDiff -= @{GetStatusBarHeight():Call()};
			int contentViewTop = com.fuse.Activity.getRootActivity().getWindow().findViewById(Window.ID_ANDROID_CONTENT).getTop();
			boolean keyboardClosed = (heightDiff-contentViewTop)<(@{GetRealDisplayHeight():Call()}/4);
			if (heightDiff!=@{lastKeyboardHeight} || @{firstSizing}) {
				if (keyboardClosed) {
					@{onHideKeyboard(int,bool):Call(heightDiff, @{firstSizing})};
				} else {
					@{onShowKeyboard(int,bool):Call(heightDiff, @{firstSizing})};
				}
			}
			@{firstSizing:Set(false)};
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

			if (_bottomFrameSize==0 && height>0) {
				resizeReason = SystemUIResizeReason.WillShow;
			} else if (_bottomFrameSize>0 && height==0) {
				resizeReason = SystemUIResizeReason.WillHide;
			} else if (_bottomFrameSize>0 && height > 0 && height != _bottomFrameSize) {
				resizeReason = SystemUIResizeReason.WillChangeFrame;
			}
			_bottomFrameSize = height;

			// make the event args
			SystemUIWillResizeEventArgs args = new SystemUIWillResizeEventArgs(SystemUIID.BottomFrame, resizeReason, endFrame, startFrame, 1, 0);

			//Make the call
			SystemUI.OnWillResize(args);
		}

		static void cppOnTopFrameChanged (int height)
		{
			if (_topFrameSize != height)
			{
				SystemUIResizeReason resizeReason = SystemUIResizeReason.WillChangeFrame;

				float2 size = _GetRootDisplaySize();

				float2 start_pos = float2(0, size.Y - _topFrameSize);
				float2 start_size = float2(size.X, _topFrameSize);

				float2 end_pos = float2(0, size.Y - height);
				float2 end_size = float2(size.X, height);

				Rect startFrame = new Rect(start_pos, start_size);
				Rect endFrame = new Rect(end_pos, end_size);

				if (_topFrameSize==0 && height>0) {
					resizeReason = SystemUIResizeReason.WillShow;
				} else if (_topFrameSize>0 && height==0) {
					resizeReason = SystemUIResizeReason.WillHide;
				} else if (_topFrameSize>0 && height > 0 && height != _topFrameSize) {
					resizeReason = SystemUIResizeReason.WillChangeFrame;
				}
				_topFrameSize = height;

				// make the event args
				SystemUIWillResizeEventArgs args = new SystemUIWillResizeEventArgs(SystemUIID.TopFrame, resizeReason, endFrame, startFrame, 1, 0);

				//Make the call
				OnWillResize(args);
			}
		}

		// from android
		static float2 _GetRootDisplaySize()
		{
			float w = (int)GetRealDisplayWidth();
			float h = (int)GetRealDisplayHeight();
			return float2(w, h);
		}
	}
}
