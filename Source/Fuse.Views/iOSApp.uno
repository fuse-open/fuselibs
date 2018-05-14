using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Fuse.Controls;
using Fuse.Controls.Native;

namespace Fuse
{

	using Fuse.Controls.Native.iOS;

	[Require("Xcode.PublicHeader", "iOS/ExportedViews.h")]
	[Require("Xcode.PublicHeader", "iOS/ViewHandle.h")]
	[Require("Xcode.PublicHeader", "iOS/Arguments.h")]
	extern (iOS && LIBRARY) public class App: AppBase
	{
		public App()
		{
			Fuse.Platform.SystemUI.OnCreate();

			Fuse.Controls.TextControl.TextRendererFactory = Fuse.iOS.Bindings.TextRenderer.Create;

			MobileBootstrapping.Init();

			Time.Init(Uno.Diagnostics.Clock.GetSeconds());
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

		protected override void OnUpdate()
		{
			CheckFocus();
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
	}
}
