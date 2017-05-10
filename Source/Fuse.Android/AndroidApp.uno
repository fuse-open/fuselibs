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
		GraphicsView _graphicsView;

		public App()
		{
			Fuse.Platform.SystemUI.OnCreate();

			Fuse.Android.StatusBarConfig.SetStatusBarColor(float4(0));

			Fuse.Controls.TextControl.TextRendererFactory = Fuse.Android.TextRenderer.Create;

			_renderPanel = new TreeRendererPanel(new RootViewHost());
			_graphicsView = new RootGraphicsView();
			_renderPanel.Children.Add(_graphicsView);

			MobileBootstrapping.Init();

			RootViewport = new NativeRootViewport(new ViewHandle(AppRoot.Handle));
			RootViewport.Children.Add(_renderPanel);

			Uno.Platform.Displays.MainDisplay.Tick += OnTick;
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
			_graphicsView.Color = Background;
		}
	}
}
