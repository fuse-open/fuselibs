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
		IScrollViewHost _host;

		[UXConstructor]
		public ScrollView([UXParameter("Host")]IScrollViewHost host) : base(Create())
		{
			_host = host;
			InstallCallback(NativeHandle, OnScrollChanged, OnInteractionChanged);
		}

		public override void Dispose()
		{
			_host = null;
			base.Dispose();
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new com.fuse.android.views.FuseScrollView(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		void InstallCallback(Java.Object handle, Action<int, int, int, int> callback, Action<bool> interactionCallback)
		@{
			((com.fuse.android.views.FuseScrollView)handle).setScrollEventHandler(
				new com.fuse.android.views.ScrollEventHandler() {
					public void onScrollChanged(int x, int y, int oldX, int oldY) {
						callback.run(x, y, oldX, oldY);
					}
				});

			((com.fuse.android.views.FuseScrollView)handle).setScrollInteractionEventHandler(
				new com.fuse.android.views.ScrollInteractionEventHandler() {
					public void onInteractionChanged(boolean isInteracting) {
						interactionCallback.run(isInteracting);
					}
				});
		@}

		[Foreign(Language.Java)]
		void SetIsHorizontal(Java.Object handle, bool isHorizontal)
		@{
			((com.fuse.android.views.FuseScrollView)handle).setIsHorizontal(isHorizontal);
		@}

		public ScrollDirections AllowedScrollDirections
		{
			set
			{
				SetIsHorizontal(NativeHandle, value.HasFlag(ScrollDirections.Horizontal));
			}
		}

		[Foreign(Language.Java)]
		void SetSnapMinTransform(Java.Object handle, bool value)
		@{
			((com.fuse.android.views.FuseScrollView)handle).setDisableBounceStart(value);
		@}

		[Foreign(Language.Java)]
		void SetSnapMaxTransform(Java.Object handle, bool value)
		@{
			((com.fuse.android.views.FuseScrollView)handle).setDisableBounceEnd(value);
		@}

		public bool SnapMinTransform
		{
			set { SetSnapMinTransform(NativeHandle, value); }
		}

		public bool SnapMaxTransform
		{
			set { SetSnapMaxTransform(NativeHandle, value); }
		}

		[Foreign(Language.Java)]
		void SetUserScroll(Java.Object handle, bool isScroll)
		@{
			((com.fuse.android.views.FuseScrollView)handle).setScrolling(isScroll);
		@}

		public bool UserScroll
		{
			set
			{
				SetUserScroll(NativeHandle, value);
			}
		}

		public float2 ScrollPosition
		{
			set
			{
				var x = (int2)(value * _host.PixelsPerPoint);
				SetScrollPosition(Handle, x.X, x.Y);
			}
		}

		public float2 Goto
		{
			set
			{
				var x = (int2)(value * _host.PixelsPerPoint);
				SetGoto(Handle, x.X, x.Y);
			}
		}

		void OnScrollChanged(int x, int y, int oldx, int oldy)
		{
			var p = _host.PixelsPerPoint;
			_host.OnScrollPositionChanged(float2(x / p, y / p));
		}

		void OnInteractionChanged(bool isInteracting)
		{
			_host.OnInteractionChanged(isInteracting);
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
			android.view.View sv = (android.view.View)handle;
			sv.setScrollX(x);
			sv.setScrollY(y);
		@}

		[Foreign(Language.Java)]
		static void SetGoto(Java.Object handle, int x, int y)
		@{
			((com.fuse.android.views.FuseScrollView)handle).smoothScrollTo(x, y);
		@}
	}
}
