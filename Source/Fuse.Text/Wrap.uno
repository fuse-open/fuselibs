using Fuse.Text.Bidirectional;
using Uno.Collections;
using Uno.IO;
using Uno;

namespace Fuse.Text
{
	public static class Wrap
	{
		public static List<List<Run>> ActualLineBreaks(List<Run> logicalRuns)
		{
			var result = new List<List<Run>>();
			var currentLine = new List<Run>();
			foreach (var run in logicalRuns)
			{
				bool first = true;
				foreach (var line in run.String.TrimmedLines())
				{
					if (!first)
					{
						result.Add(currentLine);
						currentLine = new List<Run>();
					}
					currentLine.Add(new Run(line, run.Level));
					first = false;
				}
			}
			result.Add(currentLine);
			return result;
		}

		public static List<List<ShapedRun>> Lines(
			Font font,
			List<List<ShapedRun>> logicalLineRuns,
			float maxPixelWidth,
			out float minTolerance, out float maxTolerance)
		{
			minTolerance = 0;
			maxTolerance = float.PositiveInfinity;
			var result = new List<List<ShapedRun>>(logicalLineRuns.Count);
			foreach (var line in logicalLineRuns)
			{
				WrapLine(font, maxPixelWidth, ref minTolerance, ref maxTolerance, line, result);
			}
			return result;
		}

		static void WrapLine(
			Font font, float maxPixelWidth,
			ref float minTolerance, ref float maxTolerance,
			List<ShapedRun> line,
			List<List<ShapedRun>> result)
		{
			var currentLine = new List<ShapedRun>(line.Count);
			float2 pos = float2(0);

			foreach (var srun in line)
			{
				if (srun.Count == 0)
				{
					// Make sure empty lines are not completely empty
					if (currentLine.Count == 0)
						currentLine.Add(srun);
					continue;
				}

				// Give the ShapedRun a chance to cache
				var srunMeasurements = srun.Measure();
				if ((pos + srunMeasurements).X <= maxPixelWidth)
				{
					pos += srunMeasurements;
					currentLine.Add(srun);
				}
				else
				{
					WrapRun(font, maxPixelWidth,
						ref minTolerance, ref maxTolerance,
						srun,
						ref pos, ref currentLine,
						result);
				}
			}
			result.Add(currentLine);
		}

		static void WrapRun(
			Font font, float maxPixelWidth,
			ref float minTolerance, ref float maxTolerance,
			ShapedRun srun,
			ref float2 pos,
			ref List<ShapedRun> currentLine,
			List<List<ShapedRun>> result)
		{
			var text = srun.Run.String;
			var textLength = text.Length;
			var localPos = float2(0);
			var wrapIndex = -1;
			var wrapPos = pos;

			var ltr = srun.Run.IsLeftToRight;
			var i = ltr ? 0 : srun.Count - 1;
			var step = ltr ? 1 : -1;

			srun.CacheLineBreaks();

			bool firstIteration = true;

			for (; 0 <= i && i < srun.Count; i += step)
			{
				var pg = srun[i];

				var clusterInBounds = 0 <= pg.Cluster && pg.Cluster < textLength;

				if (!firstIteration && clusterInBounds && srun.CanLineBreak(pg.Cluster))
				{
					wrapIndex = i;
					wrapPos = pos;
				}

				pos += pg.Advance;
				localPos += pg.Advance;

				if (pos.X > maxPixelWidth && clusterInBounds && !char.IsWhiteSpace(text[pg.Cluster]))
				{
					minTolerance = Math.Max(minTolerance, wrapPos.X);
					maxTolerance = Math.Min(maxTolerance, pos.X);

					if (wrapIndex == -1)
					{
						if (currentLine.Count > 0)
						{
							result.Add(currentLine);
							currentLine = new List<ShapedRun>();
							pos = localPos;
						}
					}
					else
					{
						var prefixRun = srun.SubShapedRun(0, wrapIndex);
						var postfixRun = srun.SubShapedRun(wrapIndex);
						currentLine.Add(ltr ? prefixRun : postfixRun);
						result.Add(currentLine);
						currentLine = new List<ShapedRun>();
						pos = float2(0);
						WrapRun(font, maxPixelWidth,
							ref minTolerance, ref maxTolerance,
							ltr ? postfixRun : prefixRun,
							ref pos, ref currentLine,
							result);
						return;
					}
				}

				firstIteration = false;
			}
			currentLine.Add(srun);
			minTolerance = Math.Max(minTolerance, pos.X);
		}
	}
}
