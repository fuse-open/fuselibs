using Uno;
using Uno.Collections;

using Fuse.Text.Bidirectional;

namespace Fuse.Text.Test
{
	static class Util
	{
		public static List<ShapedRun> MockLineShapedRuns(Substring xs, int startLevel)
		{
			var result = new List<ShapedRun>();
			var i = 0;
			while (i < xs.Length)
			{
				var start = i;

				var space = xs[i] == ' ';
				var upper = char.IsUpper(xs[i]);

				while (i < xs.Length && char.IsUpper(xs[i]) == upper && (xs[i] == ' ') == space)
					++i;

				if (!space)
				{
					var level = startLevel + (upper ? 1 : 0);
					result.Add(
						new ShapedRun(
							new Run(xs.GetSubstring(start, i - start), level),
							MockPositionedGlyphs(i - start, level)));
				}
			}
			return result;
		}

		public static PositionedGlyph[] MockPositionedGlyphs(int len, int level)
		{
			var result = new PositionedGlyph[len];

			var mockGlyph = new Glyph(0, 123);

			if (level % 2 == 0)
				for (var i = 0; i < len; ++i)
					result[i] = new PositionedGlyph(mockGlyph, float2(10, 0), float2(), i);
			else
				for (var i = 0; i < len; ++i)
					result[i] = new PositionedGlyph(mockGlyph, float2(10, 0), float2(), len - i - 1);
			return result;
		}

		public static List<List<ShapedRun>> MockShapedRuns(string xss, int startLevel)
		{
			var result = new List<List<ShapedRun>>();
			foreach (var xs in new Substring(xss).TrimmedLines())
				result.Add(MockLineShapedRuns(xs, startLevel));
			return result;
		}

		public static List<List<PositionedRun>> MockPositionedRuns(string xs, int startLevel)
		{
			var sruns = Util.MockShapedRuns(xs, startLevel);
			var result = new List<List<PositionedRun>>();
			var pos = float2(0, 0);
			foreach (var line in sruns)
			{
				var lineResult = new List<PositionedRun>();
				result.Add(lineResult);
				foreach (var srun in line)
				{
					var m = srun.Measure();
					lineResult.Add(new PositionedRun(srun, pos, m));
					pos += m;
				}
				pos = float2(0, pos.Y + 20);
			}
			return result;
		}
	}
}
