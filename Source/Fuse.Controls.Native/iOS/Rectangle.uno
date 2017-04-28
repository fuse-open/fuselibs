using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Require("Source.Include", "QuartzCore/QuartzCore.h")]
	extern(iOS) internal class Rectangle : Shape, IRectangleView
	{
		float4 _cornerRadius = float4(0.0f);
		float4 IRectangleView.CornerRadius
		{
			set
			{
				_cornerRadius = value;
				OnShapeChanged();
			}
		}

		protected sealed override ObjC.Object CreatePath()
		{
			var pos = ShapePosition;
			var size = ShapeSize;
			var mn = (float)Math.Min(size.X, size.Y) / 2;

			float4 cr = _cornerRadius;
			for (var i = 0; i < 4; i++)
				cr[i] = Math.Min(mn, cr[i]);

			var path = CreateUIBezierPath();

			MoveToPoint(path, pos.X + cr[0], pos.Y );

			var t = pos + float2(size.X - cr[1],0);
			AddLineToPoint( path, t.X, t.Y );

			t = pos + float2(size.X-cr[1],cr[1]);
			AddArcWithCenter( path, t.X, t.Y, cr[1], -Math.PIf/2, 0f);

			t = pos + float2(size.X,size.Y-cr[2]);
			AddLineToPoint( path,  t.X, t.Y );

			t = pos + float2(size.X-cr[2],size.Y-cr[2]);
			AddArcWithCenter( path, t.X, t.Y, cr[2], 0, Math.PIf/2 );

			t = pos + float2(cr[3],size.Y);
			AddLineToPoint( path, t.X, t.Y );

			t = pos + float2(cr[3],size.Y-cr[3]);
			AddArcWithCenter( path, t.X, t.Y, cr[3], Math.PIf/2, Math.PIf);

			t = pos + float2(0,cr[0]);
			AddLineToPoint( path, t.X, t.Y );

			t = pos + float2(cr[0],cr[0]);
			AddArcWithCenter( path, t.X, t.Y, cr[0], -Math.PIf, -Math.PIf/2);

			ClosePath(path);

			return path;
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateUIBezierPath()
		@{
			return  [[UIBezierPath alloc] init];
		@}

		[Foreign(Language.ObjC)]
		void ClosePath( ObjC.Object handle )
		@{
			UIBezierPath* path = (UIBezierPath*)handle;
			[path closePath];
		@}

		[Foreign(Language.ObjC)]
		void MoveToPoint( ObjC.Object handle, float x, float y )
		@{
			UIBezierPath* path = (UIBezierPath*)handle;
			[path moveToPoint: { x, y }];
		@}

		[Foreign(Language.ObjC)]
		void AddLineToPoint( ObjC.Object handle, float x, float y )
		@{
			UIBezierPath* path = (UIBezierPath*)handle;
			[path addLineToPoint: { x, y }];
		@}

		[Foreign(Language.ObjC)]
		void AddArcWithCenter( ObjC.Object handle, float centerX, float centerY, float radius, float startAngle, float endAngle)
		@{
			UIBezierPath* path = (UIBezierPath*)handle;
			[path addArcWithCenter: { centerX, centerY } radius:radius startAngle:startAngle endAngle:endAngle clockwise:true];
		@}

	}

}