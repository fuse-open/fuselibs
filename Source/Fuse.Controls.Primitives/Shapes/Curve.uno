using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Graphics;

using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Internal;

namespace Fuse.Controls
{
	public enum CurveStyle
	{
		Straight,
		Smooth,
	}
	
	public enum CurveClose
	{
		/** The path is not closed. */
		None,
		/** The first and last point are assumed to overlap and create an continuous path. A straight line segment will be added, post smoothing, to cover any gap. */
		Overlap,
		/** An extra line segment is introduced between the last and first points. This is done prior to the smoothing calculations. */
		Auto,
	}

	//TODO: This should not be a `Node` sinec it's too heavy of an object
	//it only needs to be a `PropertyObject`, but until `Each` supports non-node types we need to use `Node`
	//https://github.com/fusetools/fuselibs-private/issues/3676
	/**
		Defines a point inside a @Curve
		
		Only one of each pair `ControlIn`/`TangentIn` and `ControlOut/TangentOut` can be defined, as they both define the same tangent to a point. These tangent definitions override the default values: if not specfied the `Curve` will assign appropriate defaults depending on the `Style`.
		
		The `ControlIn/Out` values define a bezier style control point before and after the point.
		
		The `TangenIn/Out` values define the direction and strenght of the tangent at the point. These are defined according to the Cubic Hermite definition.
	*/
	public class CurvePoint : Node
	{
		static public Selector NameAt = "At";
		static public Selector NameTangentIn = "TangentIn";
		static public Selector NameTangentOut = "TangentOut";
		static public Selector NameControlIn = "ControlIn";
		static public Selector NameControlOut = "ControlOut";
		
		float2 _at;
		/**
			The position of the point. This is relative to the size of the @Curve control.
		*/
		public float2 At 
		{ 
			get { return _at; }
			set 
			{ 
				if (_at == value && _has.HasFlag(HasFlags.X|HasFlags.Y))
					return;
					
				_at = value; 
				_has |= HasFlags.X | HasFlags.Y;
				OnPropertyChanged(NameAt);
			}
		}
		
		[Flags]
		enum HasFlags
		{
			None = 0,
			X = 1 << 0,
			Y = 1 << 1,
			TangentIn = 1 << 2,
			TangentOut = 1 << 3,
			ControlIn = 1 << 4,
			ControlOut = 1 << 5,
		}
		HasFlags _has = HasFlags.None;
		
		/**
			Access to the `At.X` value
		*/
		public float X
		{
			get { return _at.X; }
			set 
			{
				if (_at.X == value && _has.HasFlag(HasFlags.X))
					return;
					
				_at.X = value;
				_has |= HasFlags.X;
				OnPropertyChanged(NameAt);
			}
		}
		
		/**
			Access to the `At.Y` value.
		*/
		public float Y
		{
			get { return _at.Y; }
			set 
			{
				if (_at.Y == value && _has.HasFlag(HasFlags.Y))
					return;
					
				_at.Y = value;
				_has |= HasFlags.Y;
				OnPropertyChanged(NameAt);
			}
		}
		
		float2 _a, _b;

		/**
			The direction and strength of the tangent leading into this point.
		*/
		public float2 TangentIn
		{
			get { return _a; }
			set
			{
				if (_a == value && _has.HasFlag(HasFlags.TangentIn))
					return;
					
				_a = value;
				_has |= HasFlags.TangentIn;
				OnPropertyChanged(NameTangentIn);
			}
		}
		
		public bool HasTangentIn { get { return _has.HasFlag(HasFlags.TangentIn); } }
		
		/** 
			The direction and strength of the tangent leading out of this point.
		*/
		public float2 TangentOut
		{
			get { return _b; }
			set
			{
				if (_b == value && _has.HasFlag(HasFlags.TangentOut))
					return;
					
				_b = value;
				_has |= HasFlags.TangentOut;
				OnPropertyChanged(NameTangentOut);
			}
		}
		
		public bool HasTangentOut { get { return _has.HasFlag(HasFlags.TangentOut); } }
		
		/**
			Use the same value for both TangentIn and TangentOut.
		*/
		public float2 Tangent
		{
			get { return TangentIn; }
			set
			{
				TangentIn = value;
				TangentOut = value;
			}
		}

		/**
			The control point of a bezier on the incoming side of this point.
		*/
		public float2 ControlIn
		{
			get { return _a; }
			set
			{
				if (_a == value && _has.HasFlag(HasFlags.ControlIn))
					return;
					
				_a = value;
				_has |= HasFlags.ControlIn;
				OnPropertyChanged(NameControlIn);
			}
		}
		
		public bool HasControlIn { get { return _has.HasFlag(HasFlags.ControlIn); } }
		
		/**
			The control point of a bezier on the outgoing side of this point.
		*/
		public float2 ControlOut
		{
			get { return _b; }
			set
			{
				if (_b == value && _has.HasFlag(HasFlags.ControlOut))
					return;
					
				_b = value;
				_has |= HasFlags.ControlOut;
				OnPropertyChanged(NameControlOut);
			}
		}
		
		public bool HasControlOut { get { return _has.HasFlag(HasFlags.ControlOut); } }
	}

	public enum CurveExtrude
	{
		/** No extrusion */
		None,
		/** Extend to the bottom edge */
		Bottom,
		/** Extend to the top edge */
		Top,
		/** extend to the left edge */
		Left,
		/** Extend to the right edge */
		Right,
		/** A vertical extrusion with ExtrudeTo */
		Vertical,
		/** A horiziontal extrusion with ExtrudeTo */
		Horizontal,
	}
	
	/**
		Draws a curve connecting several points, specified as @CurvePoint.
		
		The points of the curve are relative to the size of the `Curve`; the values have the range `0..1`.
		
		## Example
		
			Draws a simple line graph.
			
			<Panel Alignment="Center" Width="300" Height="200">
				<Curve StrokeWidth="10" StrokeColor="#ABC">
					<CurvePoint At="0.00,0.0"/>
					<CurvePoint At="0.25,0.4"/>
					<CurvePoint At="0.50,0.1"/>
					<CurvePoint At="0.75,0.9"/>
					<CurvePoint At="1.00,0.6"/>
				</Curve>
			</Panel>
	*/
	public class Curve : SegmentedShape, IPropertyListener
	{
		List<CurvePoint> _points = new List<CurvePoint>();
		
		protected override void OnChildAdded(Node elm)
		{
			base.OnChildAdded(elm);
			if (IsRootingCompleted && elm is CurvePoint)
			{
				(elm as CurvePoint).AddPropertyListener(this);
				ResetLines();
			}
		}
		
		protected override void OnChildRemoved(Node elm)
		{
			base.OnChildRemoved(elm);
			if (IsRootingCompleted && elm is CurvePoint)
			{
				(elm as CurvePoint).RemovePropertyListener(this);
				ResetLines();
			}
		}
		
		void ResetLines()
		{
			InvalidateSurfacePath();
			_points.Clear();
			for (var n = FirstChild<CurvePoint>(); n != null; n = n.NextSibling<CurvePoint>())
				_points.Add(n);
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj is CurvePoint)
			{
				InvalidateSurfacePath();
			}
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			ResetLines();
			for (int i=0; i < _points.Count; ++i)
				_points[i].AddPropertyListener(this);
		}
		
		protected override void OnUnrooted()
		{
			for (int i=0; i < _points.Count; ++i)
				_points[i].RemovePropertyListener(this);
				
			base.OnUnrooted();
		}
		
		float _tension = 0;
		/**
			Specifies the relative "length" of the tangent vector.
			
			Range -1..1
		*/
		public float Tension
		{
			get { return _tension; }
			set
			{
				if (_tension != value)
				{
					_tension = value;
					InvalidateSurfacePath();
				}
			}
		}
		
		float _bias = 0;
		/**
			Roughly specifies a "direction" of the tangent vector.
			
			Range -1..1
		*/
		public float Bias
		{
			get { return _bias; }
			set
			{
				if (_bias != value)
				{
					_bias = value;
					InvalidateSurfacePath();
				}
			}
		}
		
		float _continuity = 0;
		/**
			Specifies the "sharpness" of the tangent vector.
			
			Range -1..1
		*/
		public float Continuity
		{
			get { return _continuity; }
			set
			{
				if (_continuity != value)
				{
					_continuity = value;
					InvalidateSurfacePath();
				}
			}
		}		
		
		CurveStyle _style = CurveStyle.Smooth;
		/**
			Specifies whether the line is a continuous curve or comprised of straight-line segments.
			
			`Smooth`  (the default) will calculate point tangents according the values of `Tension`, `Bias` and `Continuity`. These define the parameters for a  Kochanek–Bartels spline calculation on the points.
			
			Note that a `Linear` style should not define the control/tangent values for a `CurvePoint`. This is currently unsupported but might be supported in a later release.
		*/
		public CurveStyle Style
		{
			get { return _style; }
			set 
			{
				if (_style == value)
					return;
					
				_style = value;
				InvalidateSurfacePath();
			}
		}
		
		CurveClose _close = CurveClose.None;
		/**
			How the path, defined by the CurvePoint's, is closed.
			
			The region of the closed path will be painted with the `Fills`. What is painted on an unclosed path is undefined.
			
			One of either `Close` or `Extrude` should be `None`, otherwise it is undefined what is drawn.
		*/
		public CurveClose Close
		{
			get { return _close; }
			set
			{
				if (_close == value)
					return;
					
				_close = value;
				InvalidateSurfacePath();
			}
		}
		
		CurveExtrude _extrude = CurveExtrude.None;
		/**
			Extends the shape to the side of the `Curve` element. This region will be filled with the `Shape.Fill` brush.
			
			This assumes the start and end points are at the edges of the curve. `Extrude` continues from these points to draw an area that encloses the desired region.
		*/
		public CurveExtrude Extrude
		{
			get { return _extrude; }
			set
			{
				if (_extrude == value)
					return;
					
				_extrude = value;
				InvalidateSurfacePath();
			}
		}
		
		float _extrudeTo = 0;
		public float ExtrudeTo
		{
			get { return _extrudeTo; }
			set
			{
				if (_extrudeTo == value)
					return;
					
				_extrudeTo = value;
				InvalidateSurfacePath();
			}
		}
		
		LineSegments _segments = new LineSegments();
		protected override void InvalidateSurfacePath()
		{
			base.InvalidateSurfacePath();
			_segments.Clear();
			InvalidateRenderBounds();
		}
	
		float2 ExtrudePoint(float2 pt)
		{	
			switch (Extrude)
			{
				case CurveExtrude.Bottom:
					return float2(pt.X,1);
				case CurveExtrude.Top:
					return float2(pt.X,0);
				case CurveExtrude.Left:
					return float2(0,pt.Y);
				case CurveExtrude.Right:
					return float2(1,pt.Y);
				case CurveExtrude.Horizontal:
					return float2(ExtrudeTo,pt.Y);
				case CurveExtrude.Vertical:
					return float2(pt.X,ExtrudeTo);
			}
			
			return pt;
		}
		
		//assumes 'a' is within range (-points.Count, 2*pointsCount), as is the case at it's only invocation site
		int WrapPointsIndex(int a)
		{
			switch (Close)
			{
				case CurveClose.None: 
					break;
					
				case CurveClose.Overlap:
					if (a < 0)
						a += _points.Count - 1;
					else if (a >= _points.Count)
						a -= _points.Count - 1;
					break;
					
				case CurveClose.Auto:
					if (a < 0)
						a += _points.Count;
					else if (a >= _points.Count)
						a -= _points.Count;
					break;
			}
			
			return Math.Clamp( a, 0, _points.Count-1 );
		}
		
		internal IList<LineSegment> TestLineSegments { get { return GetSegments(); } }
		
		internal override IList<LineSegment> GetSegments()
		{
			//if cached return that, or if not enough to draw return the empty path
			if (_segments.Count >0 || _points.Count < 2)
				return _segments.Segments;
				
			var rs = ActualSize;
 			var line = _segments;
 			var end = Close == CurveClose.Auto ? _points.Count + 1 : _points.Count;
 			for (int i=0; i < end; ++i)
 			{
				if (i==0)
				{
					line.MoveTo(_points[i].At * rs);
					continue;
				}
				
				if (Style == CurveStyle.Straight)
				{
					line.LineTo( _points[WrapPointsIndex(i)].At * rs );
					continue;
				}
				
				var prev = _points[WrapPointsIndex(i-2)];
				var cur = _points[WrapPointsIndex(i-1)];
				var next = _points[WrapPointsIndex(i)];
				var next2 = _points[WrapPointsIndex(i+1)];

				float4 ta, tb;
				Curves.KochanekBartelTangent( float4(prev.At,0,0), float4(cur.At,0,0), 
					float4(next.At,0,0), float4(next2.At,0,0),
					_tension, _bias, _continuity, out ta, out tb); 				
				
				if (cur.HasTangentOut)
					ta = float4(cur.TangentOut,0,0);
				if (next.HasTangentIn)
					tb = float4(next.TangentIn,0,0);
					
				Curves.CubicHermiteToBezier( float4(cur.At,0,0), float4(next.At,0,0), ref ta, ref tb );
				
				if (cur.HasControlOut)
					ta = float4(cur.ControlOut,0,0);
				if (next.HasControlIn)
					tb = float4(next.ControlIn,0,0);
				line.BezierCurveTo( next.At.XY * rs, ta.XY * rs, tb.XY * rs );
			}
			
			if (Extrude != CurveExtrude.None)
			{
				line.LineTo( ExtrudePoint(_points[_points.Count-1].At) * rs );
				line.LineTo( ExtrudePoint(_points[0].At) * rs);
				line.ClosePath();
			}
			else if (Close != CurveClose.None)
			{
				line.ClosePath();
			}
			
			return _segments.Segments;
		}
		
		override protected Rect CalcShapeExtents()
		{
			return LineMetrics.GetBounds( GetSegments() );
		}
	}
}
