using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Fuse.Controls;
using Fuse.Controls.Native;

namespace Fuse
{

	using Fuse.Controls.Native.iOS;

	extern (iOS && !LIBRARY) public class App: AppBase
	{
		class RootViewHost : INativeViewRoot
		{
			void INativeViewRoot.Add(ViewHandle handle) { AppRoot.SetRootView(handle); }
			void INativeViewRoot.Remove(ViewHandle handle) { AppRoot.ClearRoot(handle); }
		}

		TreeRendererPanel _renderPanel;
		Fuse.Controls.GraphicsView _graphicsView;

		public App()
		{
			Fuse.Platform.SystemUI.OnCreate();

			Fuse.Controls.TextControl.TextRendererFactory = Fuse.iOS.Bindings.TextRenderer.Create;

			MobileBootstrapping.Init();

			RootViewport = new NativeRootViewport(new ViewHandle(AppRoot.Handle));

			Time.Init(Uno.Diagnostics.Clock.GetSeconds());
			Uno.Platform.Displays.MainDisplay.Tick += OnTick;

			_renderPanel = new TreeRendererPanel(new RootViewHost());
			_graphicsView = new Fuse.Controls.GraphicsView();
			_renderPanel.Children.Add(_graphicsView);

			InputDispatch.AddListener(_renderPanel, AppRoot.Handle);

			RootViewport.Children.Add(_renderPanel);
		}

		public sealed override IList<Node> Children
		{
			get { return _graphicsView.Children; }
		}
		
		public sealed override Visual ChildrenVisual
		{
			get { return _graphicsView; }
		}

		void OnTick(object sender, Uno.Platform.TimerEventArgs args)
		{
			try
			{
				PropagateBackground();
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
			Time.Set(Uno.Diagnostics.Clock.GetSeconds());
			
			try
			{
				OnUpdate();
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		void PropagateBackground()
		{
			Fuse.AppRoot.ClearColor = Background;
		}

		protected override void OnUpdate()
		{
			CheckFocus();
			CheckStatusBarOrientation();
			base.OnUpdate();
		}
		
		//iOS: has no events to detect focus change thus we need this stupid polling
 		ObjC.Object _currentFocus;
 		void CheckFocus()
 		{
 			var newFocus = Fuse.Controls.Native.iOS.FocusHelpers.GetCurrentFirstResponder();

 			if (!Compare(_currentFocus, newFocus))
 			{
 				if (!IsNull(_currentFocus))
 					Fuse.Controls.Native.iOS.NativeFocus.RaiseFocusLost(_currentFocus);

 				_currentFocus = newFocus;

 				if (!IsNull(_currentFocus))
 					Fuse.Controls.Native.iOS.NativeFocus.RaiseFocusGained(_currentFocus);
 			}
 		}

 		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static bool Compare(ObjC.Object x, ObjC.Object y)
		@{
			return [x isEqual: y];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static bool IsNull(ObjC.Object x)
		@{
			return x == nil;
		@}

 		int _prevStatusBarOrientation = -1;
 		void CheckStatusBarOrientation()
 		{
 			var o = Device.StatusBarOrientation;
 			if (_prevStatusBarOrientation != o)
 			{
 				_prevStatusBarOrientation = o;
 				UpdateManager.PerformNextFrame(_renderPanel.InvalidateVisual);
 			}
 		}

	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) internal static class Device
	{
		public static int Orientation
		{
			get { return GetCurrentOrientation(); }
		}

		public static int StatusBarOrientation
		{
			get { return GetStatusBarOrientation(); }
		}

		[Foreign(Language.ObjC)]
		static int GetCurrentOrientation()
		@{
			return (int)[[UIDevice currentDevice] orientation];
		@}

		[Foreign(Language.ObjC)]
		static int GetStatusBarOrientation()
		@{
			return (int)[[UIApplication sharedApplication] statusBarOrientation];
		@}

	}

}
