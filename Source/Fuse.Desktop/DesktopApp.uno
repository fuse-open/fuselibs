using Uno;
using Uno.Platform;
using Uno.Collections;
using Uno.UX;

using Fuse.Desktop;

namespace Fuse
{
	internal class RootPanel : Fuse.Controls.Panel
	{
		public override Fuse.Elements.ITreeRenderer TreeRenderer
		{
			get { return Fuse.Controls.DefaultTreeRenderer.Instance; }
		}
	}

	/**
		Base class for apps.
		A Fuse project should contain exactly one `App` tag, which is the root
		node for the entire application.
		@mount UX Classes
	*/
	extern (!MOBILE) public abstract class App: AppBase
	{
		DesktopRootViewport DesktopRootViewport
		{
			get { return (DesktopRootViewport)RootViewport; }
		}
		
		readonly RootPanel _rootPanel = new RootPanel();
		protected App()
		{
			RootViewport = new Fuse.Desktop.DesktopRootViewport(Window);
			RootViewport.Children.Add(_rootPanel);
		}

		public override float4 Background
		{
			get
			{
				return Application.Current.GraphicsController.ClearColor;
			}
			set
			{
				Application.Current.GraphicsController.ClearColor = value;
			}
		}

		public override IList<Node> Children
		{
			get { return _rootPanel.Children; }
		}
		
		public override Visual ChildrenVisual
		{
			get { return _rootPanel; }
		}

		public sealed override void Draw()
		{
			if defined(FUSELIBS_PROFILING)
				Profiling.BeginDraw();

			DesktopRootViewport.Draw();

			if defined(FUSELIBS_PROFILING)
				Profiling.EndDraw();

			// See the note in Update about frame index
			UpdateManager.IncreaseFrameIndex();
		}

		public override bool NeedsRedraw 
		{ 
			get { return DesktopRootViewport.IsDirty; } 
		}

		public sealed override void Update()
		{
			try
			{
				Time.Set(Uno.Diagnostics.Clock.GetSeconds());
				OnUpdate();
				
				// It's important that the FrameIndex is incremented every frame even if nothing draws. The increment
				// should happen after drawing, but if there is nothing to draw it won't reach that code, thus we
				// check for that condition here.
				if (!NeedsRedraw)
					UpdateManager.IncreaseFrameIndex();
			}
			catch (Exception e)
			{
				OnUnhandledException(e);
			}
		}
	
	}
}
