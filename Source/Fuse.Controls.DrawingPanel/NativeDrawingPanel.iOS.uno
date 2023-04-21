using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native;
using Fuse.Controls.Internal;
using Fuse.Input;

namespace Fuse.Controls.Native.iOS
{
	extern (!iOS) internal class iOSDrawingPanel
	{
		[UXConstructor]
		public iOSDrawingPanel([UXParameter("Host")]ICanvasViewHost host) { }
	}

	[Require("Source.Include","iOS/CanvasViewGroup.h")]
	[Require("Source.Include","UIKit/UIKit.h")]
	extern(iOS) internal class iOSDrawingPanel : ViewHandle, ICanvasFactory
	{
		[UXConstructor]
		public iOSDrawingPanel([UXParameter("Host")]ICanvasViewHost host) : this(host, Create(host.PixelsPerPoint)) { }

		ICanvasViewHost _host;

		iOSDrawingPanel(ICanvasViewHost host, ObjC.Object handle) : base(handle, false, InputMode.Automatic, Invalidation.OnInvalidateVisual)
		{
			NeedsRenderBounds = true;
			_host = host;
			InstallDrawCallback(handle, OnDraw);
		}

		ICanvas ICanvasFactory.Create(float2 size, float pixelsPerPoint)
		{
			return new NativeCanvas(size, pixelsPerPoint);
		}

		class CanvasContext : ICanvasContext
		{
			CGContext _target;

			public CanvasContext(CGContext target)
			{
				_target = target;
			}

			void ICanvasContext.Draw(ICanvas canvas)
			{
				var nativeCanvas = canvas as NativeCanvas;
				if (nativeCanvas != null)
				{
					using (var image = nativeCanvas.CGContext.CreateImage())
					{
						_target.Draw(image);
					}
				}
			}
		}

		void OnDraw(IntPtr context)
		{
			CGContext ctx = extern<CGContext>(context)"(CGContextRef)$0";
			_host.OnDraw(new CanvasContext(ctx));
		}

		[Foreign(Language.ObjC)]
		static void InstallDrawCallback(ObjC.Object handle, Action<IntPtr> onDrawCallback)
		@{
			::CanvasViewGroup* cvg = (::CanvasViewGroup*)handle;
			[cvg setOnDrawCallback:onDrawCallback];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create(float density)
		@{
			::CanvasViewGroup* cvg = [[::CanvasViewGroup alloc] initWithDensity:density];
			[cvg setOpaque:false];
			[cvg setMultipleTouchEnabled:true];
			return cvg;
		@}
	}
}