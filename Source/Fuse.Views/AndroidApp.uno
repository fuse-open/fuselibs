using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse
{
	using Fuse.Controls;

	extern (Android && Library) public abstract class App: AppBase
	{
		public App()
		{
			Fuse.Platform.SystemUI.OnCreate();
			Fuse.Controls.TextControl.TextRendererFactory = Fuse.Android.TextRenderer.Create;
			MobileBootstrapping.Init();
			Uno.Platform.Displays.MainDisplay.Tick += OnTick;
			Fuse.Views.ExportedViews.Initialize(ExportedViews.FindTemplate);
		}

		public sealed override IList<Node> Children
		{
			get { return new Panel().Children; }
		}

		public sealed override Visual ChildrenVisual
		{
			get { return new Panel(); }
		}

		void OnTick(object sender, Uno.Platform.TimerEventArgs args)
		{
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
	}
}
