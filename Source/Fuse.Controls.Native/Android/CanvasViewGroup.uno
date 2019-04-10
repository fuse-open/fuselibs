using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{
	extern(Android)
	public class CanvasViewGroup : ViewHandle, INativeSurfaceOwner
	{

		ISurfaceDrawable _surfaceDrawable;
		float _pixelsPerPoint;

		public CanvasViewGroup(ISurfaceDrawable surfaceDrawable, float pixelsPerPoint)
			: base(Instantiate(), false, false, ViewHandle.Invalidation.OnInvalidateVisual)
		{
			_surfaceDrawable = surfaceDrawable;
			_pixelsPerPoint = pixelsPerPoint;
		}

		NativeSurface _nativeSurface;

		internal Surface INativeSurfaceOwner.GetSurface()
		{
			if (_nativeSurface == null)
			{
				InstallDrawlistener(NativeHandle, OnDraw);
				_nativeSurface = new NativeSurface();
			}
			return _nativeSurface;
		}

		void OnDraw(Java.Object canvas)
		{
			if (_nativeSurface == null)
			{
				Fuse.Diagnostics.InternalError( "Attempt to draw native canvas without surface", this );
				return;
			}

 			_nativeSurface.Begin(canvas, _pixelsPerPoint);
 			_nativeSurface.DrawLocal(_surfaceDrawable);
 			_nativeSurface.End();
		}

		[Foreign(Language.Java)]
		void InstallDrawlistener(Java.Object handle, Action<Java.Object> callback)
		@{
			com.fuse.android.views.CanvasViewGroup viewGroup = (com.fuse.android.views.CanvasViewGroup)handle;
			viewGroup.setWillNotDraw(false);
			viewGroup.invalidate();
			viewGroup.setDrawListener(new com.fuse.android.views.CanvasViewGroup.DrawListener() {
				public void onDraw(android.graphics.Canvas canvas) {
					callback.run(canvas);
				}
			});
		@}

		[Foreign(Language.Java)]
		static Java.Object Instantiate()
		@{
			android.widget.FrameLayout frameLayout = new com.fuse.android.views.CanvasViewGroup(com.fuse.Activity.getRootActivity());
			frameLayout.setFocusable(true);
			frameLayout.setFocusableInTouchMode(true);
			frameLayout.setClipChildren(false);
			frameLayout.setClipToPadding(false);
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}

		public override void Dispose()
		{
			base.Dispose();
			_surfaceDrawable = null;
			_nativeSurface = null;
		}
	}
}