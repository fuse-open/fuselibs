using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Internal;

namespace Fuse.Controls
{
	public enum PathMeasureMode
	{
		/** Offset on the path measured in time: a value from 0..1, where each segment is considered the same length. The actual length of the segments is not considered. */
		Time,
		/** Offset on the path measured in an approximate distance. Each offset step will cover roughly the same amount of length along the path.
		
		For performance reasons this is a rough estimate of distance. Its precision may also change in future version (for the better) */
		Distance,
	}
	
	public abstract class SegmentedShape : Shape
	{
		internal SegmentedShape() { }

		/** These values are protected as not all derived classes can reasonably support them, at least not yet. 
			Possibly there should be an intermediate SegmentedShape type instead. */
		float _pathStart = 0, _pathEnd = 1, _pathLength = 1;
		bool _hasPathLength = false;
		
		static Selector NamePathStart = "PathStart";
		static Selector NamePathEnd = "PathEnd";
		static Selector NamePathLength = "PathLength";

		/**
			Start drawing the path from this offset in the path data.
			
			Path offsets are measured in a normalized 0..1 range.  PathStart must be in the range 0..1.
			
			@experimental The precise defintion of offsets, in Time or Distance, may need to be varied, and possibly changes in API due to performance considerations.
		*/
		public float PathStart
		{
			get { return _pathStart; }
			set
			{
				if (_pathStart == value)
					return;
					
				_pathStart = value;
				OnPropertyChanged( NamePathStart );
				InvalidateSurfacePath();
			}
		}
		
		/**
			Draw the path until this offset in the path data.
			
			Only one of `PathEnd` or `PathLength` should be specified. Choose `PathEnd` when the end location is independent of the starting location `PathState`. Choose `PathLength` when the end location is dependent on the starting location -- when you know only the desired length of the path.
			
			@see PathStart
			
			Requirements: PathEnd >= PathStart; (PathEnd - PathStart) <= 1
			
			@experimental
		*/
		public float PathEnd
		{
			get { return _pathEnd; }
			set
			{
				if (_pathEnd == value && !_hasPathLength)
					return;
					
				_pathEnd = value;
				_hasPathLength = false;
				OnPropertyChanged( NamePathEnd );
				InvalidateSurfacePath();
			}
		}
		
		/**
			Draw the path for this length along the path data.
			
			Only one of `PathEnd` or `PathLength` should be specified.
			
			Requirements: 0 <= PathLength  <= 1
			
			@see PathEnd
			@see PathStart
			
			@experimental
		*/
		public float PathLength
		{
			get { return _pathLength; }
			set
			{
				if (_pathLength == value && _hasPathLength)
					return;
					
				_hasPathLength = true;
				_pathLength = value;
				OnPropertyChanged( NamePathLength );
				InvalidateSurfacePath();
			}
		}
		
		PathMeasureMode _pathMeasureMode = PathMeasureMode.Distance;
		/**
			How the offset along the path is measured.
			
			The default is `Distance`. Be aware this is an estimated value and doesn't correlate to a precise distance.
			
			@experimental The precise meaning of these offsets may need to change, and the precision of Distance may be altered.
		*/
		public PathMeasureMode PathMeasureMode
		{
			get { return _pathMeasureMode; }
			set 
			{
				if (value == _pathMeasureMode)
					return;
				_pathMeasureMode = value;
				InvalidateSurfacePath();
			}
		}
		
		float EffectivePathEnd
		{
			get { return _hasPathLength ? (_pathStart + _pathLength) : _pathEnd; }
		}

		protected sealed override SurfacePath CreateSurfacePath(Surface surface)
		{
			if (PathStart != 0 || PathEnd != 1 || _hasPathLength)
				return CreatePartialSurfacePath(surface);
			return surface.CreatePath(Segments);
		}
		
		internal event Action SegmentsChanged;
		
		protected override void InvalidateSurfacePath()
		{
			base.InvalidateSurfacePath();
			_splitter = null; //the splitter is invalid on any segments change
			_segments = null;
			InvalidateVisual();
			
			if (SegmentsChanged != null)
				SegmentsChanged();
		}
		
		IList<LineSegment> _segments;
		IList<LineSegment> Segments
		{
			get
			{
				if (_segments == null)
					_segments = GetSegments();
				return _segments;
			}
		}
		
		LineSplitter _splitter;
		LineSplitter Splitter
		{
			get
			{
				if (_splitter == null)
					_splitter = new LineSplitter(Segments);
				return _splitter;
			}
		}
		
		SurfacePath CreatePartialSurfacePath(Surface surface)
		{	
			List<LineSegment> list = new List<LineSegment>();
			var start = PathStart;
			var end = EffectivePathEnd;
			
			//start in the 0...1 range
			if (start < 0 || start >1)
			{
				var inc = -Math.Floor(start);
				start += inc;
				end += inc;
			}
			
			if (end < start || (end-start) > 1)
			{
				//overlength and reverse could have logical meanings, so issue error instead of adjusting
				Fuse.Diagnostics.UserError( "Unsupported Path start=" + start + 
					", end=" + end, this );
				return surface.CreatePath(list);
			}

			//convert to distnace if desired
			var startT = start;
			var endT = end;
			if (PathMeasureMode == PathMeasureMode.Distance) 
			{
				startT = Splitter.DistanceToTime(startT);
				endT = Splitter.DistanceToTime(endT);
			}
			
			Splitter.SplitTime( startT, endT, list );
			return surface.CreatePath(list);
		}
		
		internal float2 PointAtDistance( float distance )
		{
			var t = Splitter.DistanceToTime(distance);
			return Splitter.PointAtTime(t);
		}
		
		internal float2 TangentAtDistance( float distance )
		{
			var t = Splitter.DistanceToTime(distance);
			return Vector.Normalize(Splitter.DirectionAtTime(t));
		}

		internal float2 PointAtTime( float time )
		{
			return Splitter.PointAtTime(time);
		}
		
		internal float2 TangentAtTime( float time )
		{
			return Vector.Normalize(Splitter.DirectionAtTime(time));
		}
		
		internal abstract IList<LineSegment> GetSegments();
	}
}