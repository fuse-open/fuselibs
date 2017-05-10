using Fuse.Text.Bidirectional;
using Uno;
using Uno.Collections;

namespace Fuse.Text
{
	public static class Truncate
	{
		public static List<List<ShapedRun>> Lines(
			Font font,
			List<List<ShapedRun>> lines,
			float maxPixelWidth,
			out float minTolerance,
			out float maxTolerance)
		{
			minTolerance = 0;
			maxTolerance = float.PositiveInfinity;
			var result = new List<List<ShapedRun>>();
			foreach (var line in lines)
				result.Add(Truncate.Line(font, line, maxPixelWidth, ref minTolerance, ref maxTolerance));
			return result;
		}

		public static List<ShapedRun> Line(
			Font font,
			List<ShapedRun> lineRuns,
			float maxPixelWidth,
			ref float minTolerance,
			ref float maxTolerance)
		{
			float2 pos = float2(0);
			for (int runIndex = 0; runIndex < lineRuns.Count; ++runIndex)
			{
				var srun = lineRuns[runIndex];
				var srunMeasurements = srun.Measure();

				if ((pos + srunMeasurements).X <= maxPixelWidth)
				{
					pos += srunMeasurements;
				}
				else
				{
					var text = srun.Run.String;
					var ltr = srun.Run.IsLeftToRight;
					var i = ltr ? 0 : srun.Count - 1;
					var step = ltr ? 1 : -1;

					for (; 0 <= i && i < srun.Count; i += step)
					{
						pos += srun[i].Advance;
						var cluster = srun[i].Cluster;
						var clusterInBounds = 0 <= cluster && cluster < text.Length;
						if (pos.X > maxPixelWidth && clusterInBounds && !char.IsWhiteSpace(text[cluster]))
						{
							return TruncatedLine(
								font,
								lineRuns,
								maxPixelWidth,
								ref minTolerance, ref maxTolerance,
								pos,
								runIndex,
								i);
						}
					}
				}
			}
			minTolerance = Math.Max(minTolerance, pos.X);
			return lineRuns;
		}

		static List<ShapedRun> TruncatedLine(
			Font font,
			List<ShapedRun> lineRuns,
			float maxPixelWidth,
			ref float minTolerance, ref float maxTolerance,
			float2 pos,
			int runIndex,
			int i)
		{
			var truncationWidth = font.TruncationMeasurements.X;
			var truncationBoundary = maxPixelWidth - truncationWidth;

			var first = true;
			var lastAdvance = float2(0);
			for (; runIndex >= 0; --runIndex)
			{
				var srun = lineRuns[runIndex];
				var ltr = srun.Run.IsLeftToRight;
				if (first)
					first = false;
				else
					i = ltr ? srun.Count - 1 : 0;
				var step = ltr ? -1 : 1;

				for (; 0 <= i && i < srun.Count; i += step)
				{
					if (pos.X <= truncationBoundary)
					{
						var truncatedSrun = ltr
							? srun.SubShapedRun(0, i + 1)
							: srun.SubShapedRun(i);
						var truncationSrun = new ShapedRun(
							new Run(new Substring(Font.Truncation), srun.Run.Level),
							font.ShapedTruncation);

						var truncStart = Math.Min(maxPixelWidth, pos.X + truncationWidth);
						minTolerance = Math.Max(minTolerance, truncStart);
						maxTolerance = Math.Min(maxTolerance, truncStart + lastAdvance.X);

						var result = new List<ShapedRun>();
						for (int j = 0; j < runIndex; ++j)
							result.Add(lineRuns[j]);
						result.Add(truncatedSrun);
						result.Add(truncationSrun);
						return result;
					}

					lastAdvance = srun[i].Advance;
					pos -= lastAdvance;
				}
			}
			{
				minTolerance = Math.Max(minTolerance, 0);
				maxTolerance = Math.Min(maxTolerance, 0 + lastAdvance.X);
				var truncationSrun = new ShapedRun(
					new Run(new Substring(Font.Truncation), 0),
					font.ShapedTruncation);
				var result = new List<ShapedRun>(1);
				result.Add(truncationSrun);
				return result;
			}
		}
	}
}
