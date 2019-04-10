using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native.Android;
using Fuse.Controls.Native;

namespace Fuse.Android
{

	extern(Android && !Library) internal static class AppRoot
	{

		public static ViewHandle ViewHandle
		{
			get { return _viewHandle; }
		}

		public static Java.Object Handle
		{
			get { return _rootContainer; }
		}

		static readonly Java.Object _rootContainer;
		static readonly ViewHandle _viewHandle;

		static AppRoot()
		{
			_rootContainer = CreateRootView();
			_viewHandle = new ViewHandle(_rootContainer);
			SetAppRoot(_rootContainer);
		}

		public static void SetRootView(ViewHandle handle)
		{
			SetRootView(_rootContainer, handle.NativeHandle);
		}

		public static void ClearRoot(ViewHandle handle)
		{
			ClearRoot(_rootContainer);
		}

		[Foreign(Language.Java)]
		public static void ClearRoot(Java.Object handle)
		@{
			((android.widget.FrameLayout)handle).removeAllViews();
		@}

		[Foreign(Language.Java)]
		static void SetRootView(Java.Object handle, Java.Object rootHandle)
		@{
			((android.widget.FrameLayout)handle).addView(((android.view.View)rootHandle));
		@}

		static void SetAppRoot(Java.Object rootView)
		{
			Fuse.Platform.SystemUI.RootView = rootView;
		}

		static void OnTouchEvent__(Java.Object motionEvent)
		{
			var root = ((Fuse.App)(Uno.Application.Current)).ChildrenVisual;
			InputDispatch.RaiseEvent(root, _rootContainer, new MotionEvent(motionEvent));
		}

		[Foreign(Language.Java)]
		static Java.Object CreateRootView()
		@{
			android.widget.FrameLayout frameLayout = new android.widget.FrameLayout(com.fuse.Activity.getRootActivity()) {

					android.view.MotionEvent _currentEvent;

					public boolean onInterceptTouchEvent(android.view.MotionEvent motionEvent) {
						_currentEvent = motionEvent;
						return super.onInterceptTouchEvent(motionEvent);
					}

					public boolean onTouchEvent(android.view.MotionEvent motionEvent) {
						if (_currentEvent != motionEvent)
							return false;
						boolean result = super.onTouchEvent(motionEvent);
						@{global::Fuse.Android.AppRoot.OnTouchEvent__(Java.Object):Call(motionEvent)};
						return _currentEvent == motionEvent;
					}

				};
			frameLayout.setFocusable(true);
			frameLayout.setFocusableInTouchMode(true);
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}
	}
}
