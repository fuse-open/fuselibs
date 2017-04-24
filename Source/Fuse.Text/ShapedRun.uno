using Fuse.Text.Bidirectional;
using Uno.Collections;
using Uno;

namespace Fuse.Text
{
	public class ShapedRun : IEnumerable<PositionedGlyph>
	{
		readonly Run _run;
		public Run Run { get { return _run; } }
		internal readonly PositionedGlyph[] _parent;
		internal readonly int _start;
		public int Count;
		readonly int _clusterOffset;
		Implementation.BitArray _lineBreakClusters;
		readonly int _lineBreakClusterOffset;

		public ShapedRun(Run run, PositionedGlyph[] parent)
			: this(run, parent, 0, parent.Length, 0, null, 0)
		{
		}

		ShapedRun(
			Run run,
			PositionedGlyph[] parent,
			int start, int count,
			int clusterOffset,
			Implementation.BitArray lineBreakClusters, int lineBreakClusterOffset)
		{
			if (count > 0 && (start < 0 || start >= parent.Length))
				throw new ArgumentOutOfRangeException(nameof(start));
			if (start + count < 0 || start + count > parent.Length)
				throw new ArgumentOutOfRangeException(nameof(count));
			_run = run;
			_parent = parent;
			_start = start;
			Count = count;
			_clusterOffset = clusterOffset;
			_lineBreakClusters = lineBreakClusters;
			_lineBreakClusterOffset = lineBreakClusterOffset;
		}

		public ShapedRun SubShapedRun(int start, int count)
		{
			if (count > 0 && (start < 0 || start >= Count))
				throw new ArgumentOutOfRangeException(nameof(start));
			if (start + count < 0 || start + count > Count)
				throw new ArgumentOutOfRangeException(nameof(count));

			var firstCluster = count > 0
				? this[start].Cluster
				: 0;
			var lastCluster = count > 0
				? this[start + count - 1].Cluster
				: 0;
			var smallestCluster = Math.Min(firstCluster, lastCluster);
			var largestCluster = Math.Max(firstCluster, lastCluster);
			var clusterOffset = - smallestCluster;
			var newRun = new Run(Run.String.InclusiveRange(smallestCluster, largestCluster), Run.Level);
			return new ShapedRun(
				newRun,
				_parent,
				_start + start,
				count,
				_clusterOffset + clusterOffset,
				_lineBreakClusters,
				_lineBreakClusters == null ? 0 : _lineBreakClusterOffset + smallestCluster);
		}

		public ShapedRun SubShapedRun(int start)
		{
			return SubShapedRun(start, Count - start);
		}

		float2 _measureCache;

		public float2 Measure()
		{
			if (_measureCache == default(float2))
			{
				var measurements = float2(0, 0);
				var end = _start + Count;
				var strLen = Run.String.Length;
				for (int i = _start; i < end; ++i)
				{
					measurements += _parent[i].Advance;
					var cluster = _parent[i].Cluster + _clusterOffset;
					var clusterInBounds = 0 <= cluster && cluster < strLen;
					if (clusterInBounds && !char.IsWhiteSpace(Run.String[cluster]))
						_measureCache = measurements;
				}
			}
			return _measureCache;
		}

		public PositionedGlyph this[int index]
		{
			get
			{
				if (index < 0 || index >= Count)
					throw new ArgumentOutOfRangeException(nameof(index));
				var pg = _parent[index + _start];
				return new PositionedGlyph(pg.Glyph, pg.Advance, pg.Offset, pg.Cluster + _clusterOffset);
			}
		}

		public void CacheLineBreaks()
		{
			if (_lineBreakClusters == null)
				_lineBreakClusters = LineBreaks.Get(Run.String);
		}

		public bool CanLineBreak(int cluster)
		{
			return _lineBreakClusters[cluster + _lineBreakClusterOffset];
		}

		public IEnumerator<PositionedGlyph> GetEnumerator()
		{
			return new PGEnumerator(this);
		}

		class PGEnumerator : IEnumerator<PositionedGlyph>
		{
			int _index;
			readonly ShapedRun _shapedRun;

			public PGEnumerator(ShapedRun shapedRun)
			{
				_shapedRun = shapedRun;
				Reset();
			}

			public void Reset()
			{
				_index = -1;
			}

			public bool MoveNext()
			{
				++_index;
				return _index < _shapedRun.Count;
			}

			public PositionedGlyph Current
			{
				get
				{
					return _shapedRun[_index];
				}
			}

			public void Dispose()
			{
				// Nothing to do
			}
		}
	}
}
