using Fuse.Text.Bidirectional;
using Uno.Collections;
using Uno;

namespace Fuse.Text.Edit
{
	public enum CaretIndex {}

	struct Caret
	{
		public readonly int Cluster;
		public readonly int LineIndex;
		public readonly int RunIndex;
		public readonly float2 VisualPos;

		public Caret(int cluster, int lineIndex, int runIndex, float2 visualPos)
		{
			Cluster = cluster;
			LineIndex = lineIndex;
			RunIndex = runIndex;
			VisualPos = visualPos;
		}
	}

	public struct CaretContext
	{
		readonly List<List<PositionedRun>> _runs;
		readonly string _source;
		readonly List<Caret> _carets;
		readonly int[] _runIndices;

		public CaretContext(List<List<PositionedRun>> pruns, string source)
		{
			_runs = pruns;
			_source = source;

			_carets = PossibleCaretPositions(_runs, _source);
		}

		static List<Caret> PossibleCaretPositions(List<List<PositionedRun>> lines, string source)
		{
			List<Caret> result = new List<Caret>();

			for (var lineIndex = 0; lineIndex < lines.Count; ++lineIndex)
			{
				var pruns = lines[lineIndex];
				for (var runIndex = 0; runIndex < pruns.Count; ++runIndex)
				{
					var prun = pruns[runIndex];
					var srun = prun.ShapedRun;
					var position = prun.Position;
					var logicalStart = prun.Run.LogicalStart;

					var glyphIndex = 0;
					if (prun.Run.IsLeftToRight)
					{
						while (glyphIndex < srun.Count)
						{
							var startIndex = glyphIndex;
							var startCluster = logicalStart + srun[startIndex].Cluster;
							var startPosition = position;

							while (glyphIndex < srun.Count &&
								srun[glyphIndex].Cluster == srun[startIndex].Cluster)
							{
								position += srun[glyphIndex].Advance;
								++glyphIndex;
							}

							var cluster = glyphIndex < srun.Count
								? logicalStart + srun[glyphIndex].Cluster
								: prun.Run.VisualRight;
							LerpClustersLTR(
								source,
								startCluster, startPosition,
								cluster, position,
								lineIndex, runIndex,
								result);
						}

						result.Add(new Caret(prun.Run.VisualRight, lineIndex, runIndex, position));
					}
					else
					{
						result.Add(new Caret(prun.Run.VisualLeft, lineIndex, runIndex, position));

						while (glyphIndex < srun.Count)
						{
							var startIndex = glyphIndex;
							var startCluster = logicalStart + srun[startIndex].Cluster;
							var startPosition = position;

							while (glyphIndex < srun.Count &&
								srun[glyphIndex].Cluster == srun[startIndex].Cluster)
							{
								position += srun[glyphIndex].Advance;
								++glyphIndex;
							}

							var cluster = glyphIndex < srun.Count
								? logicalStart + srun[glyphIndex].Cluster
								: source.PrevCharIndex(prun.Run.VisualRight);
							LerpClustersRTL(
								source,
								startCluster, startPosition,
								cluster, position,
								lineIndex, runIndex,
								result);
						}

					}
				}
			}

			return result;
		}

		static void LerpClustersLTR(
			string source,
			int cluster1, float2 pos1,
			int cluster2, float2 pos2,
			int lineIndex, int runIndex,
			List<Caret> result)
		{
			var diff = Math.Abs(pos2 - pos1);
			var len = StringRangeLength(source, cluster1, cluster2);
			var i = 0;
			var end = Math.Min(source.Length, cluster2);
			for (var c = cluster1; c < end; c = source.NextCharIndex(c))
			{
				var pos = pos1 + ((float)i / len) * diff;
				result.Add(new Caret(c, lineIndex, runIndex, pos));
				++i;
			}
		}

		static void LerpClustersRTL(
			string source,
			int cluster1, float2 pos1,
			int cluster2, float2 pos2,
			int lineIndex, int runIndex,
			List<Caret> result)
		{
			var diff = Math.Abs(pos2 - pos1);
			var len = StringRangeLength(source, cluster2, cluster1);
			var i = 0;
			for (var c = cluster1; c > cluster2; c = source.PrevCharIndex(c))
			{
				var pos = pos1 + ((float)(i + 1) / len) * diff;
				result.Add(new Caret(c, lineIndex, runIndex, pos));
				++i;
			}
		}

		static int StringRangeLength(string source, int cluster1, int cluster2)
		{
			var len = 0;
			var end = Math.Min(source.Length, cluster2);
			for (var i = cluster1; i < end; i = source.NextCharIndex(i))
				++len;
			return len;
		}

		public CaretIndex LeftMost() { return (CaretIndex)0; }
		public CaretIndex RightMost() { return _carets.Count > 0 ? (CaretIndex)(_carets.Count - 1) : LeftMost(); }

		public CaretIndex MoveRight(CaretIndex i) { return Clamp((CaretIndex)((int)i + 1)); }
		public CaretIndex MoveLeft(CaretIndex i) { return Clamp((CaretIndex)((int)i - 1)); }

		CaretIndex Clamp(CaretIndex i)
		{
			return (CaretIndex)Math.Clamp((int)i, (int)LeftMost(), (int)RightMost());
		}

		public float2 GetVisualPosition(CaretIndex i)
		{
			i = Clamp(i);
			if (_carets.Count == 0)
				return float2();

			return _carets[i].VisualPos;
		}

		public CaretIndex GetClosest(float2 pos, float lineHeight)
		{
			pos -= float2(0, lineHeight / 2);
			var minSquaredDist = float.PositiveInfinity;
			var minIndex = 0;
			for (var i = 0; i < _carets.Count; ++i)
			{
				// Give a high weight to the y coordinate to favour the line before
				// characters within the line.
				var squaredDist = WeightedSquaredDist(pos, _carets[i].VisualPos, 1000);
				if (squaredDist < minSquaredDist)
				{
					minSquaredDist = squaredDist;
					minIndex = i;
				}
			}
			return (CaretIndex)minIndex;
		}

		static float WeightedSquaredDist(float2 p, float2 q, float yweight)
		{
			var x = p.X - q.X;
			var y = p.Y - q.Y;
			return x * x + yweight * y * y;
		}

		static float SquaredDist(float2 p, float2 q)
		{
			var x = p.X - q.X;
			var y = p.Y - q.Y;
			return x * x + y * y;
		}

		public CaretIndex MoveUp(CaretIndex currentIndex)
		{
			currentIndex = Clamp(currentIndex);
			if (_carets.Count == 0)
				return LeftMost();

			return ClosestCaretOnLine(
				_carets[currentIndex].VisualPos,
				_carets[currentIndex].LineIndex - 1,
				LeftMost());
		}

		public CaretIndex MoveDown(CaretIndex currentIndex)
		{
			currentIndex = Clamp(currentIndex);
			if (_carets.Count == 0)
				return LeftMost();

			return ClosestCaretOnLine(
				_carets[currentIndex].VisualPos,
				_carets[currentIndex].LineIndex + 1,
				RightMost());
		}

		CaretIndex ClosestCaretOnLine(float2 pos, int desiredLine, CaretIndex def)
		{
			var minIndex = def;
			var minSquaredDist = float.PositiveInfinity;

			for (var i = 0; i < _carets.Count; ++i)
			{
				var caret = _carets[i];
				if (caret.LineIndex == desiredLine)
				{
					var dist = SquaredDist(pos, caret.VisualPos);
					if (dist < minSquaredDist)
					{
						minSquaredDist = dist;
						minIndex = (CaretIndex)i;
					}
				}
			}
			return minIndex;
		}

		public List<Rect> GetVisualRects(CaretIndex i1, CaretIndex i2, float lineHeight)
		{
			if (_carets.Count == 0)
				return new List<Rect>();

			i1 = Clamp(i1);
			i2 = Clamp(i2);

			if (_carets[i1].Cluster > _carets[i2].Cluster)
			{
				var tmp = i1;
				i1 = i2;
				i2 = tmp;
			}

			var caret1 = _carets[i1];
			var caret2 = _carets[i2];
			var cluster1 = caret1.Cluster;
			var cluster2 = caret2.Cluster;

			var result = new List<Rect>();
			var lh = float2(0, lineHeight);

			for (var lineIndex = 0; lineIndex < _runs.Count; ++lineIndex)
			{
				var pruns = _runs[lineIndex];
				for (var runIndex = 0; runIndex < pruns.Count; ++runIndex)
				{
					var contains1 = lineIndex == caret1.LineIndex && runIndex == caret1.RunIndex;
					var contains2 = lineIndex == caret2.LineIndex && runIndex == caret2.RunIndex;
					var prun = pruns[runIndex];
					if (contains1 && contains2)
					{
						if ((int)i1 < (int)i2)
							result.Add(new Rect(caret1.VisualPos, caret2.VisualPos - caret1.VisualPos + lh));
						else
							result.Add(new Rect(caret2.VisualPos, caret1.VisualPos - caret2.VisualPos + lh));
					}
					else if (contains1)
					{
						if ((int)i1 < (int)i2 == prun.Run.IsLeftToRight)
							result.Add(new Rect(
								caret1.VisualPos,
								prun.Measurements - (caret1.VisualPos - prun.Position) + lh));
						else
							result.Add(new Rect(
								prun.Position,
								caret1.VisualPos - prun.Position + lh));
					}
					else if (contains2)
					{
						if ((int)i1 < (int)i2 == prun.Run.IsLeftToRight)
							result.Add(new Rect(
								prun.Position,
								caret2.VisualPos - prun.Position + lh));
						else
							result.Add(new Rect(
								caret2.VisualPos,
								prun.Measurements - (caret2.VisualPos - prun.Position) + lh));
					}
					else if (cluster1 <= prun.Run.LogicalStart && prun.Run.LogicalEnd < cluster2)
					{
						result.Add(new Rect(prun.Position, prun.Measurements + lh));
					}
				}
			}

			return result;
		}

		bool LeftToRight(CaretIndex i)
		{
			var caret = _carets[i];
			return _runs[caret.LineIndex][caret.RunIndex].Run.IsLeftToRight;
		}

		public string Insert(char c, ref CaretIndex i)
		{
			i = Clamp(i);
			var insertionPos = _carets.Count > 0 ? _carets[i].Cluster : 0;
			if (_carets.Count == 0 || LeftToRight(i))
				i = (CaretIndex)((int)i + 1);

			return _source.SafeInsert(insertionPos, c.ToString());
		}

		public string Delete(ref CaretIndex i)
		{
			i = Clamp(i);
			if (_carets.Count == 0)
				return _source;

			var deletionPos = _carets[i].Cluster;
			if (!LeftToRight(i) && i > 0)
				i = (CaretIndex)((int)i - 1);
			if (deletionPos < _source.Length)
				return _source.DeleteAt(ref deletionPos);
			return _source;
		}

		public string Backspace(ref CaretIndex i)
		{
			i = Clamp(i);
			if (_carets.Count == 0)
				return _source;


			var deletionPos = _source.PrevCharIndex(_carets[i].Cluster);

			if (LeftToRight(i) && i > 0)
				i = (CaretIndex)((int)i - 1);

			if (0 <= deletionPos)
				return _source.DeleteAt(ref deletionPos);
			return _source;
		}

		public string DeleteSpan(CaretIndex start, ref CaretIndex caret)
		{
			start = Clamp(start);
			caret = Clamp(caret);
			if (_carets.Count == 0)
				return _source;

			int deletionStart = _carets[start].Cluster;
			int deletionEnd = _carets[caret].Cluster;

			if (deletionStart == deletionEnd)
				return _source;

			if (deletionStart > deletionEnd)
			{
				var tmp = deletionStart;
				deletionStart = deletionEnd;
				deletionEnd = tmp;
			}

			deletionEnd = _source.PrevCharIndex(deletionEnd);
			caret = (CaretIndex)Math.Min((int)start, (int)caret);

			return _source.DeleteSpan(deletionStart, deletionEnd);
		}
	}
}
