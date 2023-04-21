using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native;
using Fuse.Controls.Internal;
using Fuse.Input;

namespace Fuse.Controls.Native.Android
{
	extern (!ANDROID) internal class AndroidDrawingPanel
	{
		[UXConstructor]
		public AndroidDrawingPanel([UXParameter("Host")]ICanvasViewHost host) { }
	}

	[ForeignInclude(Language.Java,
		"com.fuse.android.views.CanvasViewGroup",
		"android.graphics.Canvas",
		"android.graphics.Bitmap")]
	extern(ANDROID) internal class AndroidDrawingPanel : ViewHandle, ICanvasFactory
	{
		[UXConstructor]
		public AndroidDrawingPanel([UXParameter("Host")]ICanvasViewHost host) : this(host, Create()) { }

		ICanvasViewHost _host;
		AndroidDrawingPanel(ICanvasViewHost host, Java.Object handle) : base(handle, false, false, Invalidation.OnInvalidateVisual)
		{
			_host = host;
			InstallDrawListener(handle, OnDraw);
		}

		class CanvasContext : ICanvasContext
		{
			Java.Object _target;

			public CanvasContext(Java.Object target)
			{
				_target = target;
			}

			void ICanvasContext.Draw(ICanvas canvas)
			{
				var nativeCanvas = canvas as NativeCanvas;
				if (nativeCanvas != null)
					_target.DrawBitmap(nativeCanvas.Bitmap);
			}
		}

		void OnDraw(Java.Object canvas)
		{
			_host.OnDraw(new CanvasContext(canvas));
		}

		ICanvas ICanvasFactory.Create(float2 size, float pixelsPerPoint)
		{
			return new NativeCanvas(size, pixelsPerPoint);
		}

		[Foreign(Language.Java)]
		static void InstallDrawListener(Java.Object handle, Action<Java.Object> onDrawCallback)
		@{
			((CanvasViewGroup)handle).setDrawListener(new CanvasViewGroup.DrawListener() {
				public void onDraw(Canvas canvas) {
					onDrawCallback.run(canvas);
				}
			});
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			CanvasViewGroup canvasViewGroup = new CanvasViewGroup(com.fuse.Activity.getRootActivity());
			canvasViewGroup.setWillNotDraw(false);
			return canvasViewGroup;
		@}
	}
}