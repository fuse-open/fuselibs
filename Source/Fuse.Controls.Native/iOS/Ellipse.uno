using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Require("Source.Include", "QuartzCore/QuartzCore.h")]
	extern(iOS) internal class Ellipse : Shape
	{
		protected sealed override ObjC.Object CreatePath()
		{
			return CreateUIBezierPath(ShapePosition.X, ShapePosition.Y, ShapeSize.X, ShapeSize.Y);
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateUIBezierPath(float x, float y, float width, float height)
		@{
			return [UIBezierPath bezierPathWithOvalInRect:CGRectMake(x, y, width, height)];
		@}
	}
}