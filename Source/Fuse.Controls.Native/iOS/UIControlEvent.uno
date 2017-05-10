using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/Helpers.h")]
	extern(iOS) class UIControlEvent : IDisposable
	{
		public static IDisposable AddAllTouchEventsCallback(ObjC.Object uiControl, Action<ObjC.Object, ObjC.Object> handler)
		{
			return new UIControlEvent(uiControl, handler, extern<int>"(int)UIControlEventAllTouchEvents");
		}

		public static IDisposable AddValueChangedCallback(ObjC.Object uiControl, Action<ObjC.Object, ObjC.Object> handler)
		{
			return new UIControlEvent(uiControl, handler, extern<int>"(int)UIControlEventValueChanged");
		}

		public static IDisposable AddAllEditingEventsCallback(ObjC.Object uiControl, Action<ObjC.Object, ObjC.Object> handler)
		{
			return new UIControlEvent(uiControl, handler, extern<int>"(int)UIControlEventAllEditingEvents");
		}

		ObjC.Object _handle;
		ObjC.Object _uiControl;
		readonly int _type;

		UIControlEvent(ObjC.Object uiControl, Action<ObjC.Object, ObjC.Object> handler, int type)
		{
			_handle = Create(uiControl, handler, type);
			_uiControl = uiControl;
			_type = type;
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create(ObjC.Object uiControl, Action<ObjC.Object, ObjC.Object> handler, int type)
		@{
			UIControlEventHandler* h = [[UIControlEventHandler alloc] init];
			[h setCallback:handler];
			::UIControl* control = (::UIControl*)uiControl;
			[control addTarget:h action:@selector(action:forEvent:) forControlEvents:(UIControlEvents)type];
			return h;
		@}

		void IDisposable.Dispose()
		{
			RemoveHandler(_uiControl, _handle, _type);
			_handle = null;
			_uiControl = null;
		}

		[Foreign(Language.ObjC)]
		static void RemoveHandler(ObjC.Object uiControl, ObjC.Object eventHandler, int type)
		@{
			UIControlEventHandler* h = (UIControlEventHandler*)eventHandler;
			::UIControl* control = (::UIControl*)uiControl;
			[control removeTarget:h action:@selector(action:forEvent:) forControlEvents:(UIControlEvents)type];
		@}

	}

}