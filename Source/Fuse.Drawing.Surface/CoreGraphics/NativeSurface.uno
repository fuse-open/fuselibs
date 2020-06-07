using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Drawing.Primitives;

namespace Fuse.Drawing
{
	extern(iOS||OSX)
	class NativeSurface : CoreGraphicsSurface
	{

		IntPtr _cgContext = IntPtr.Zero;

		public void Begin(IntPtr cgContext, float pixelsPerPoint)
		{
			_pixelsPerPoint = pixelsPerPoint;
			_cgContext = cgContext;
			SetCGContext(_context, _cgContext);
		}

		public override void Begin( DrawContext dc, framebuffer fb, float pixelsPerPoint )
		{
			throw new NotSupportedException();
		}

		public override void End()
		{
			_cgContext = IntPtr.Zero;
			SetCGContext(_context, _cgContext);
		}

		protected override void VerifyBegun()
		{
			if (_cgContext == IntPtr.Zero)
				throw new Exception("NativeSurface.Begin was not called");
		}

		[Foreign(Language.CPlusPlus)]
		static void SetCGContext(IntPtr cp, IntPtr cgContext)
		@{
			auto ctx = (CGLib::Context*)cp;
			ctx->Context = (CGContextRef)cgContext;
		@}
	}
}
