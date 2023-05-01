using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native;
using Fuse.Controls.Internal;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal class NativeCanvas : ICanvas
	{
		public CGContext CGContext { get { return _ctx; } }
		public int2 PixelSize { get { return _pixelSize; } }

		readonly int2 _pixelSize;
		readonly float _pixelsPerPoint;

		CGContext _ctx;

		public NativeCanvas(float2 size, float pixelsPerPoint)
		{
			_pixelSize = (int2)Math.Ceil(size * pixelsPerPoint);
			_pixelsPerPoint = pixelsPerPoint;
			_ctx = CGContext.NewBitmapContext(_pixelSize.X, _pixelSize.Y);
		}

		public NativeCanvas(int2 pixelSize) : this((float2)pixelSize, 1.0f) { }

		public void Clear(float4 color)
		{
			var rect = new Rect(0, 0, _pixelSize.X, _pixelSize.Y);
			_ctx.ClearRect(rect);
			_ctx.FillColor = color;
			_ctx.FillRect(rect);
		}

		public void Draw(Line line)
		{
			_ctx.DrawLine(line.Scale(_pixelsPerPoint));
		}

		public void Draw(IList<Line> lines)
		{
			foreach (var line in lines)
				Draw(line);
		}

		public void Draw(Internal.Circle circle)
		{
			_ctx.DrawCircle(circle.Scale(_pixelsPerPoint));
		}

		public void Draw(IList<Internal.Circle> circles)
		{
			foreach (var circle in circles)
				Draw(circle);
		}

		public void Draw(Stroke stroke)
		{
			Draw(stroke.Lines);
			Draw(stroke.Circles);
		}

		public void Draw(CGImage cgImage)
		{
			_ctx.Draw(cgImage);
		}

		public void PushTransform(float3x3 transform)
		{
			_ctx.PushTransform(transform);
		}

		public void PopTransform()
		{
			_ctx.PopTransform();
		}

		public void Dispose()
		{
			_ctx.Dispose();
			_ctx = CGContext.Null;
		}

		public CGImage AsCGImage()
		{
			return _ctx.CreateImage();
		}
	}

	extern(iOS) static class CGContextExtensions
	{
		public static void DrawLine(this CGContext ctx, Internal.Line line)
		{
			ctx.StrokeColor = line.Color;
			var from = line.From;
			var to = line.To;
			extern(ctx)"CGContextSetLineCap($0, kCGLineCapRound)";
			extern(ctx,line.Width)"CGContextSetLineWidth($0, $1)";
			extern(ctx,from.X,from.Y)"CGContextMoveToPoint($0, $1, $2)";
			extern(ctx,to.X,to.Y)"CGContextAddLineToPoint($0, $1, $2)";
			extern(ctx)"CGContextStrokePath($0)";
		}

		public static void DrawCircle(this CGContext ctx, Internal.Circle circle)
		{
			ctx.FillColor = circle.Color;
			var center = circle.Center;
			extern(ctx,center.X,center.Y,circle.Radius)
				"CGContextAddArc($0, $1, $2, $3, 0, 360, 0)";
			extern(ctx)"CGContextFillPath($0)";
		}

		public static void PushTransform(this CGContext ctx, float3x3 t)
		{
			ctx.SaveGState();
			extern(ctx,
				t.M11, t.M12,
				t.M21, t.M22,
				t.M31, t.M32)
				"CGContextConcatCTM($0, CGAffineTransformMake($1, $2, $3, $4, $5, $6))";
		}

		public static void PopTransform(this CGContext ctx)
		{
			ctx.RestoreGState();
		}
	}
}