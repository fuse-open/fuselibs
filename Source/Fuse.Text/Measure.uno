using Fuse.Text.Bidirectional;
using Uno.Collections;
using Uno;

namespace Fuse.Text
{
	public static class Measure
	{
		public static float2 Lines(
			Font font,
			float lineSpacing,
			List<List<ShapedRun>> lines)
		{
			float y = 0;
			float maxX = 0;
			foreach (var line in lines)
			{
				float2 lineMeasure = float2(0);
				foreach (var run in line)
					lineMeasure += run.Measure();
				float x = lineMeasure.X;
				maxX = Math.Max(maxX, x);
				y = Math.Floor(y + font.LineHeight + lineSpacing + lineMeasure.Y + 0.5f);
			}
			return float2(maxX, y);
		}

		public static Rect AlignedRectForSize(
			float2 size,
			float pixelWidth,
			float alignment) /* 0 = Left, 0.5 = Center, 1.0 = Right */
		{
			var left = alignment * (pixelWidth - size.X);
			var right = left + size.X;

			return new Rect(left, 0, right, size.Y);
		}
	}
}
