using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) public class ScrollView
	{
		[UXConstructor]
		public ScrollView([UXParameter("Host")]IScrollViewHost host) { }
	}

	extern(Android) public class ScrollView : View, IScrollView
	{
		readonly Java.Object _callbackHandle;

		IScrollViewHost _host;

		[UXConstructor]
		public ScrollView([UXParameter("Host")]IScrollViewHost host) : base(Create())
		{
			_host = host;
			_callbackHandle = AddCallback(Handle);
		}

		public override void Dispose()
		{
			_host = null;
			base.Dispose();
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new com.fuse.android.views.VerticalScrollView(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		Java.Object AddCallback(Java.Object handle)
		@{
			com.fuse.android.views.IScroll iscroll = new com.fuse.android.views.IScroll() {
				public void OnScrollChanged(int x, int y, int oldX, int oldY) {
					@{global::Fuse.Controls.Native.Android.ScrollView:Of(_this).OnScrollChanged(int,int,int,int):Call(x, y, oldX, oldY)};
				}
			};
			((com.fuse.android.views.VerticalScrollView)handle).SetIScroll(iscroll);
			return iscroll;
		@}

		public ScrollDirections AllowedScrollDirections
		{
			set { }
		}

		public float2 ScrollPosition
		{
			set
			{
				var x = (int2)(value * _host.PixelsPerPoint);
				SetScrollPosition(Handle, x.X, x.Y);
			}
		}

		void OnScrollChanged(int x, int y, int oldx, int oldy)
		{
			var p = _host.PixelsPerPoint;
			_host.OnScrollPositionChanged(float2(x / p, y / p));
		}

		[Foreign(Language.Java)]
		static void SetClipToBounds(Java.Object handle, bool clipToBounds)
		@{
			android.view.ViewGroup viewGroup = (android.view.ViewGroup)handle;
			viewGroup.setClipChildren(clipToBounds);
			viewGroup.setClipToPadding(clipToBounds);
		@}

		[Foreign(Language.Java)]
		static void SetScrollPosition(Java.Object handle, int x, int y)
		@{
			android.widget.ScrollView sv = (android.widget.ScrollView)handle;
			sv.setScrollX(x);
			sv.setScrollY(y);
		@}
	}
}