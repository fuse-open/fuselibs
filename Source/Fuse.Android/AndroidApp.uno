using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse
{

	using Fuse.Controls;
	using Fuse.Controls.Native;
	using Fuse.Android;

	extern (Android && !Library) public abstract class App: AppBase
	{

		class RootViewHost : INativeViewRoot
		{
			void INativeViewRoot.Add(ViewHandle handle) { AppRoot.SetRootView(handle); }
			void INativeViewRoot.Remove(ViewHandle handle) { AppRoot.ClearRoot(handle); }
		}

		TreeRendererPanel _renderPanel;

		extern(!DISABLE_IMPLICIT_GRAPHICSVIEW)
		GraphicsView _graphicsView = new RootGraphicsView();

		Visual RootVisual
		{
			get
			{
				if defined(!DISABLE_IMPLICIT_GRAPHICSVIEW)
					return _graphicsView;
				else
					return _renderPanel;
			}
		}

		public App()
		{
			Fuse.Android.StatusBarConfig.SetStatusBarColor(float4(0));

			Fuse.Controls.TextControl.TextRendererFactory = Fuse.Android.TextRenderer.Create;

			_renderPanel = new TreeRendererPanel(new RootViewHost());

			if defined(!DISABLE_IMPLICIT_GRAPHICSVIEW)
				_renderPanel.Children.Add(_graphicsView);

			MobileBootstrapping.Init();

			RootViewport = new NativeRootViewport(AppRoot.ViewHandle);
			RootViewport.Children.Add(_renderPanel);

			Uno.Platform.Displays.MainDisplay.Tick += OnTick;
		}

		public sealed override IList<Node> Children
		{
			get { return RootVisual.Children; }
		}

		public sealed override Visual ChildrenVisual
		{
			get { return RootVisual; }
		}

		void OnTick(object sender, Uno.Platform.TimerEventArgs args)
		{
			RootViewport.InvalidateLayout();
			try
			{
				PropagateBackground();
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}

			Time.Set(args.CurrentTime);

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
			if defined(!DISABLE_IMPLICIT_GRAPHICSVIEW)
				_graphicsView.Color = Background;
			else
				AppRoot.ViewHandle.SetBackgroundColor((int)Uno.Color.ToArgb(Background));
		}
	}
}
