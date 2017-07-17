using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include","iOS/CanvasViewGroup.h")]
	extern(iOS) internal class CanvasViewGroup : ViewHandle, INativeSurfaceOwner
	{
		ISurfaceDrawable _surfaceDrawable;
		float _pixelsPerPoint;

		public CanvasViewGroup(ISurfaceDrawable surfaceDrawable, float pixelsPerPoint) : base(Create(pixelsPerPoint))
		{
			_surfaceDrawable = surfaceDrawable;
			_pixelsPerPoint = pixelsPerPoint;
		}

		public override void Dispose()
		{
			SetDrawCallback(NativeHandle, null);
			base.Dispose();
			_nativeSurface = null;
		}

		void OnDraw(IntPtr cgContextRef)
		{
			if (_nativeSurface == null)
			{
				Fuse.Diagnostics.InternalError( "Attempt to draw native canvas without surface", this );
				return;
			}

			_nativeSurface.Begin(cgContextRef, _pixelsPerPoint);
			_nativeSurface.DrawLocal(_surfaceDrawable);
			_nativeSurface.End();
		}

		NativeSurface _nativeSurface;

		internal Surface INativeSurfaceOwner.GetSurface()
		{
			if (_nativeSurface == null)
			{
				SetDrawCallback(NativeHandle, OnDraw);
				Invalidate();
				_nativeSurface = new NativeSurface();
			}
			return _nativeSurface;
		}

		[Foreign(Language.ObjC)]
		static void SetDrawCallback(ObjC.Object handle, Action<IntPtr> onDrawCallback)
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

		public override void SetRenderBounds(VisualBounds bounds)
		{
			Rect r = (!bounds.IsEmpty && !bounds.IsInfinite)
				? bounds.FlatRect
				: new Rect(0, 0, Size.X, Size.Y);
			SetRenderBounds(NativeHandle, r.Position.X, r.Position.Y, r.Width, r.Height);
		}

		[Foreign(Language.ObjC)]
		static void SetRenderBounds(ObjC.Object handle, float x, float y, float w, float h)
		@{
			::CanvasViewGroup* cvg = [[::CanvasViewGroup alloc] init];
			[cvg setRenderBounds:CGRectMake(x, y, w, h)];
		@}
	}
}
