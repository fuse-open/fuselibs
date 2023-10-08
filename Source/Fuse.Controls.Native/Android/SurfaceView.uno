
using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) public class SurfaceView : GraphicsViewBase { }
	extern(Android) public class SurfaceView : GraphicsViewBase
	{
		public SurfaceView() : base(Create())
		{
			AddCallback(GraphicsViewHandle);
		}

		void OnSurfaceRedrawNeeded(Java.Object holder) { }
		void OnSurfaceChanged(Java.Object holder, int f, int w, int h){ }
		void OnSurfaceCreated(Java.Object holder)
		{
			SetSurface(GetSurface(holder));
		}
		void OnSurfaceDestroyed(Java.Object holder)
		{
			DestroySurface();
		}

		[Foreign(Language.Java)]
		static Java.Object GetSurface(Java.Object holder)
		@{
			return ((android.view.SurfaceHolder)holder).getSurface();
		@}

		[Foreign(Language.Java)]
		void AddCallback(Java.Object handle)
		@{
			((android.view.SurfaceView)handle).getHolder().addCallback(new android.view.SurfaceHolder.Callback2() {
				public void surfaceRedrawNeeded(android.view.SurfaceHolder holder) {
					@{global::Fuse.Controls.Native.Android.SurfaceView:of(_this).OnSurfaceRedrawNeeded(Java.Object):call(holder)};
				}
				public void surfaceChanged(android.view.SurfaceHolder holder, int format, int width, int height) {
					@{global::Fuse.Controls.Native.Android.SurfaceView:of(_this).OnSurfaceChanged(Java.Object,int,int,int):call(holder, format, width, height)};
				}
				public void surfaceCreated(android.view.SurfaceHolder holder) {
					@{global::Fuse.Controls.Native.Android.SurfaceView:of(_this).OnSurfaceCreated(Java.Object):call(holder)};
				}
				public void surfaceDestroyed(android.view.SurfaceHolder holder) {
					@{global::Fuse.Controls.Native.Android.SurfaceView:of(_this).OnSurfaceDestroyed(Java.Object):call(holder)};
				}
			});
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			android.view.SurfaceView surfaceView = new android.view.SurfaceView(com.fuse.Activity.getRootActivity());
			surfaceView.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return surfaceView;
		@}
	}
}
