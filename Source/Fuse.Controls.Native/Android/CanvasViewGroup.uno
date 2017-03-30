using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{
	extern(Android)
	public class CanvasViewGroup : ViewHandle
	{

		ISurfaceDrawable _surfaceDrawable;

		public CanvasViewGroup(ISurfaceDrawable surfaceDrawable) : base(Instantiate())
		{
			_surfaceDrawable = surfaceDrawable;
			InstallDrawlistener(NativeHandle, OnDraw);
		}

		NativeSurface _nativeSurface = new NativeSurface();

		void OnDraw(Java.Object canvas)
		{
			_nativeSurface.SetCanvas(canvas);
			_surfaceDrawable.Draw(_nativeSurface);
		}

		[Foreign(Language.Java)]
		void InstallDrawlistener(Java.Object handle, Action<Java.Object> callback)
		@{
			((com.fuse.android.views.CanvasViewGroup)handle).setDrawListener(new com.fuse.android.views.CanvasViewGroup.DrawListener() {
				public void onDraw(android.graphics.Canvas canvas) {
					callback.run(canvas);
				}
			});
		@}

		[Foreign(Language.Java)]
		static Java.Object Instantiate()
		@{
			android.widget.FrameLayout frameLayout = new com.fuse.android.views.CanvasViewGroup(@(Activity.Package).@(Activity.Name).GetRootActivity());
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