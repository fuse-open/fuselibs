using Uno;
using Uno.Collections;

using Fuse.Internal;

namespace Fuse.Drawing
{
	class LineSplitter
	{
		List<LineSegment> _segments;

		struct LSInfo
		{
			public float StartT, EndT;
			public float StartDistance, EndDistance;
		}
		List<LSInfo> _info;
		
		public LineSplitter(IList<LineSegment> segments)
		{
			//writing proper elliptic arc splitting is difficult due to SVG sizing rules, so get rid of them and use bezier's instead (OPT: optimize to just use `segments` fi there are no arcs, which is incredibly common for SVG data)
			_segments = new List<LineSegment>();
			var from = float2(0);
			for (int i=0; i < segments.Count; ++i)
			{
				if (segments[i].Type == LineSegmentType.Close)
					; //partials with close are undefined, should this be a warning?
				else if (segments[i].Type != LineSegmentType.EllipticArc)
					_segments.Add(segments[i]);
				else 
					SurfaceUtil.EllipticArcToBezierCurve( from, segments[i], _segments);
				
				from = segments[i].To;
			}
			
			//avoid dealing with empty segments in this class
			if (_segments.Count == 0)
				_segments.Add( new LineSegment{ Type = LineSegmentType.Close, To = float2(0) });
			
			CalcInfo();
		}
		
		void CalcInfo()
		{
			_info = new List<LSInfo>();
			var t = 0;
			var from = float2(0);
			float distance = 0;
			for (int i=0; i < _segments.Count; ++i)
			{
				LSInfo lsi;
				lsi.StartT = t;
				if (_segments[i].IsDrawing)
					t += 1;
				lsi.EndT = t;

				var length = _segments[i].EstimateLength(from);
				lsi.StartDistance = distance;
				distance += length;
				lsi.EndDistance = distance;
				
				_info.Add(lsi);
				from = _segments[i].To;
			}
			
			for (int i=0; i < _info.Count; ++i) 
			{
				var lsi = _info[i];
				lsi.StartT /= t;
				lsi.EndT /= t;
				lsi.StartDistance /= distance;
				lsi.EndDistance /= distance;
				_info[i] = lsi;
			}
		}
		
		/**
			Requires:	
				- start in (0,1)
				- end >= start
				- (end-start) <= 1
		*/
		public void SplitTime( float start, float end, IList<LineSegment> to )
		{
			if (start < 0 || start > 1 || (end < start) || (end-start) > 1)
				throw new Exception( "Invalid SplitTime arguments" );
			
			bool hasLocation = false;
			
			//the outer loop allows an overlap over the end of the curve
			while (end > 0) 
			{
				for (int i=0; i < _segments.Count; ++i)
				{
					var seg = _segments[i];
					var lsi = _info[i];
					if (lsi.StartT > end)
						break;
						
					if (lsi.EndT < start)
						continue;
						
					if (seg.Type == LineSegmentType.Move)
						hasLocation = true;
					else if (seg.Type == LineSegmentType.Close)
						hasLocation = false;
						
					var lastPos = i > 0 ? _segments[i-1].To : float2(0);
					bool fullStart = start <= lsi.StartT;
					bool fullEnd = end >= lsi.EndT;
					
					if (!seg.IsDrawing) //not splittable
					{
						to.Add(seg);
					}
					else if (fullStart && fullEnd) //full segment
					{
						if (!hasLocation)
						{
							to.Add( new LineSegment{ To = lastPos, Type = LineSegmentType.Move } );
							hasLocation = true;
						}
						to.Add(seg);
					}
					else
					{
						LineSegment left, right;
						var t = ((fullStart ? end : start) - lsi.StartT) / (lsi.EndT - lsi.StartT);
						seg.SplitAtTime( lastPos, t, out left, out right );
						
						if (fullStart)
						{
							to.Add(left);
						}
						else
						{
							// move to start of segment
							to.Add( new LineSegment{ To = left.To, Type = LineSegmentType.Move } );
							hasLocation = true;
							
							if (fullEnd)
							{
								to.Add(right);
							}
							else
							{
								//need to split further as end/start within this segment
								var nt = (end - start) / (lsi.EndT - start);
								LineSegment nleft, nright;
								right.SplitAtTime( left.To, nt, out nleft, out nright );
								to.Add(nleft);
							}
						}
					}
				}
			
				end -= 1;
				start -= 1;
			}
		}
		
		public float DistanceToTime( float distance )
		{
			//express in 0...1 range and adjust output back to source range
			float adjust = 0;
			if (distance < 0 || distance > 1)
			{
				adjust = Math.Floor(distance);
				distance -= adjust;
			}
			
			float accumZero = 0;
			float found = 0;
			for (int i=0; i < _segments.Count; ++i)
			{
				var lsi = _info[i];
				if (lsi.EndDistance < distance)
					continue;
				
				var length = lsi.EndDistance - lsi.StartDistance + accumZero;
				if (length < 1e-5)
				{
					accumZero += length;
					//accumStart might be needed, but I don't have a test case showing any problems
					continue;
				}
					
				//very rough estimate
				var off = (distance - lsi.StartDistance) / length;
				found = off * (lsi.EndT - lsi.StartT) + lsi.StartT;
				break;
			}
			
			return found + adjust;
		}
		
		struct SegmentAt
		{
			public int Index;
			public float Relative;
			public float2 From;
		}
		SegmentAt GetSegmentAtTime( float time )
		{
			time -= Math.Floor(time);
			
			var from = float2(0);
			for (int i=0; i < _segments.Count; ++i)
			{
				var seg = _segments[i];
				var lsi = _info[i];
				
				var length = lsi.EndT - lsi.StartT;
				if (lsi.EndT >= time && length > 1e-5)
				{
					var relT = (time - lsi.StartT) / length;
					return new SegmentAt{ Index = i, Relative = relT, From = from };
				}
				
				from = seg.To;
			}
			
			return new SegmentAt{ Index = 0, Relative = 0, From = from };
		}
		
		public float2 PointAtTime( float time )
		{
			var sa = GetSegmentAtTime(time);
			return _segments[sa.Index].PointAtTime(sa.From, sa.Relative);
		}
		
		public float2 DirectionAtTime( float time )
		{
			var sa = GetSegmentAtTime(time);
			return _segments[sa.Index].DirectionAtTime(sa.From, sa.Relative);
		}
	}
	
}
