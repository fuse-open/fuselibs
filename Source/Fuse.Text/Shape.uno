using Fuse.Text.Bidirectional;
using Uno.Collections;
using Uno;

namespace Fuse.Text
{
	public static class Shape
	{
		public static List<List<ShapedRun>> ShapeLines(Font font, List<List<Run>> lines)
		{
			var result = new List<List<ShapedRun>>(lines.Count);

			foreach (var line in lines)
			{
				var sline = new List<ShapedRun>(line.Count);
				foreach (var run in line)
				{
					var srun = new ShapedRun(
						run,
						font.Shape(
							run.String.TrimLeadingNewline(),
							0,
							run.Direction));
					sline.Add(srun);
				}
				result.Add(sline);
			}

			return result;
		}

		public static List<List<PositionedRun>> PositionLines(
			Font font,
			float pixelWidth,
			float lineSpacing,
			float alignment, /* 0 = Left, 0.5 = Center, 1.0 = Right */
			List<List<ShapedRun>> lines)
		{
			var result = new List<List<PositionedRun>>();
			float y = 0;
			foreach (var line in lines)
			{
				var positionedRuns = new List<PositionedRun>(line.Count);
				var lineMeasure = float2(0);
				foreach (var srun in line)
				{
					var runMeasure = srun.Measure();
					positionedRuns.Add(new PositionedRun(srun, lineMeasure, runMeasure));
					lineMeasure += runMeasure;
				}
				float x = Math.Floor(alignment * (pixelWidth - lineMeasure.X) + 0.5f);
				var pos = float2(x, y);

				for (int i = 0; i < positionedRuns.Count; ++i)
					positionedRuns[i] = PositionedRun.Translate(positionedRuns[i], pos);
				result.Add(positionedRuns);

				y = Math.Floor(y + font.LineHeight + lineSpacing + lineMeasure.Y + 0.5f);
			}
			return result;
		}
	}
}
