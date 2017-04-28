using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Require("Source.Include", "QuartzCore/QuartzCore.h")]
	extern(iOS) internal class Circle : Shape, ICircleView
	{
		float _startAngleDegrees;
		float ICircleView.StartAngleDegrees
		{
			set
			{
				_startAngleDegrees = value;
				OnShapeChanged();
			}
		}

		float ICircleView.EndAngleDegrees { set { } }

		bool _useAngle;
		bool ICircleView.UseAngle
		{
			set
			{
				_useAngle = value;
				OnShapeChanged();
			}
		}

		float _effectiveEndAngleDegrees;
		float ICircleView.EffectiveEndAngleDegrees
		{
			set
			{
				_effectiveEndAngleDegrees = value;
				OnShapeChanged();
			}
		}

		protected sealed override ObjC.Object CreatePath()
		{
			var size = ShapeSize;
			var radius = Math.Min(size.X, size.Y) / 2.0f;
			var center = ShapePosition + (size / 2.0f);
			var start = _useAngle ? Math.DegreesToRadians(_startAngleDegrees) : 0.0f;
			var end = _useAngle ? Math.DegreesToRadians(_effectiveEndAngleDegrees) : 360.0f;
			return CreateUIBezierPath(center.X, center.Y, radius, start, end);
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateUIBezierPath(
			float x,
			float y,
			float r,
			float start,
			float end)
		@{
			return [UIBezierPath bezierPathWithArcCenter:{x, y} radius:r startAngle:start endAngle:end clockwise:true];
		@}

	}

}