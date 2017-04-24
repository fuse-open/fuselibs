using Uno;

namespace Fuse
{
	/**
		This class will be specialized for speed not accuracy: the effective bounds checked may be larger
		than the strict bounds defined by the inputs.
		
		Instances of this type are immutable.
	*/
	public class VisualBounds
	{
		private VisualBounds() { }

		static VisualBounds _empty = new VisualBounds();
		static public VisualBounds Empty
		{
			get { return _empty; }
		}

		public bool IsEmpty
		{
			get { return this == _empty; }
		}
		
		static VisualBounds _infinite = new VisualBounds();
		static public VisualBounds Infinite
		{
			get { return _infinite; }
		}
		
		public bool IsInfinite 
		{ 
			get { return this == _infinite; } 
		}
		
		static public VisualBounds Point(float3 pt)
		{
			var nb = new VisualBounds();
			nb._box.Minimum = pt;
			nb._box.Maximum = pt;
			return nb;
		}
		
		/**
			Create a VisualBounds of the rect with two corner points.
		*/
		static public VisualBounds Rect(float3 a, float3 b)
		{
			var nb = new VisualBounds();
			nb._box.Minimum = Math.Min(a,b);
			nb._box.Maximum = Math.Max(a,b);
			return nb;
		}
		
		static public VisualBounds Rect(float2 a, float2 b)
		{
			return Rect( float3(a,0), float3(b,0) );
		}
		
		static public VisualBounds Box(Box a)
		{
			var nb = new VisualBounds();
			nb._box = a;
			return nb;
		}
		
		Box _box;
		
		public float3 AxisMin { get { return _box.Minimum; } }
		public float3 AxisMax { get { return _box.Maximum; } }
		public float3 Size { get { return _box.Maximum - _box.Minimum; } }
		
		public Rect FlatRect
		{
			get { return new Rect(AxisMin.XY, Size.XY); }
		}
		
		public bool IsFlat
		{
			get { return IsEmpty || (_box.Minimum.Z == 0 && _box.Maximum.Z == 0); }
		}
		
		public VisualBounds AddPoint(float3 pt)
		{
			return Merge( Point(pt) );
		}
		
		public VisualBounds AddPoint(float2 pt) 
		{ 
			return Merge( Point( float3(pt,0) ) );
		}
		
		public VisualBounds AddRect(float2 mn, float2 mx)
		{
			return Merge( Rect( float3(mn,0), float3(mx,0) ) );
		}
		
		public VisualBounds AddRect(Rect r)
		{
			return AddRect(r.Minimum, r.Maximum);
		}
		
		/**
			Applies a typical layout padding to the XY dimensions.
		*/
		public VisualBounds InflateXY(float padding)
		{
			if (IsInfinite)
				return _infinite;
				
			if (IsEmpty)
				return VisualBounds.Rect( float2(-padding), float2(padding) );
				
			var add = _box;
			add.Minimum -= float3(padding,padding,0);
			add.Maximum += float3(padding,padding,0);
			
			return Box(add);
		}
		
		public VisualBounds Scale(float3 factor)
		{
			if (IsInfinite || IsEmpty)
				return this;
				
			var sc = _box;
			sc.Minimum *= factor;
			sc.Maximum *= factor;
			
			return Box(sc);
		}
		
		public VisualBounds Translate(float3 offset)
		{
			if (IsInfinite || IsEmpty)
				return this;
				
			var add = _box;
			add.Minimum += offset;
			add.Maximum += offset;
			
			return Box(add);
		}
		
		public VisualBounds Transform(float4x4 matrix)
		{
			if (IsInfinite || IsEmpty)
				return this;
				
			var n = BoxTransform(_box, matrix);
			return Box(n);
		}

		//OPT: This version could be optimized since it doesn't care about the Z results.
		public VisualBounds TransformFlatten(float4x4 matrix)
		{
			if (IsInfinite || IsEmpty)
				return this;
				
			var n = BoxTransform(_box, matrix);
			n.Minimum.Z = 0;
			n.Maximum.Z = 0;
			return Box(n);
		}
		
		public VisualBounds Merge( VisualBounds nb, FastMatrix trans = null )
		{
			if (nb.IsEmpty)
				return this;
				
			if (nb.IsInfinite || IsInfinite)
				return _infinite;

			//OPTIMIZE: simplified FastMatrix translation/scaling/etc.
			var add = trans != null ? BoxTransform(nb._box, trans.Matrix) : nb._box;
			if (!IsEmpty)
			{
				add.Minimum = Math.Min(_box.Minimum, add.Minimum);
				add.Maximum = Math.Max(_box.Maximum, add.Maximum);
			}
			
			return Box(add);
		}
		
		/**
			Intersects two VisualBounds. This is called `...XY` since if the remaining XY space is
			empty an empty space will be returned instead (Z can't be considered since it would
			always be empty in a 2D layout).
		*/
		public VisualBounds IntersectXY( VisualBounds nb )
		{
			if (nb.IsEmpty || IsEmpty)
				return _empty;
				
			if (nb.IsInfinite || IsInfinite)
				return _infinite;
				
			var mn = Math.Max(AxisMin, nb.AxisMin);
			var mx = Math.Min(AxisMax, nb.AxisMax);
			if (mn.X >= mx.X || mn.Y >= mx.Y)
				return _empty;
				
			if (mn.Z > mx.Z)
				mx.Z = mn.Z;
				
			return VisualBounds.Rect(mn, mx);
		}
		
		public VisualBounds MergeChild( Visual child, VisualBounds nb )
		{
			return Merge( nb, child.InternLocalTransformInternal );
		}
		
		public bool ContainsPoint( float2 pt )
		{
			if (IsEmpty)
				return false;
			if (IsInfinite)
				return true;
				
			return _box.Minimum.X <= pt.X && _box.Minimum.Y <= pt.Y &&
				_box.Maximum.X >= pt.X && _box.Maximum.Y >= pt.Y &&
				_box.Minimum.Z <=0 && _box.Maximum.Z >= 0;
		}
		
		public bool IntersectsRay( Ray ray )
		{
			if (IsEmpty)
				return false;
			if (IsInfinite)
				return true;
				
			float distance;
			return Collision.RayIntersectsBox( ray, _box, out distance );
		}
		
		internal string Format()
		{
			if (IsEmpty)
				return "empty";
			if (IsInfinite)
				return "infinite";

			return "" + _box.Minimum + " " + _box.Maximum;
		}
		
		//uses the W paramete runlike Box.Transform (which may be a defect there)
		public static Box BoxTransform(Box box, float4x4 transform)
		{
			float3 A = Vector.TransformCoordinate(float3(box.Minimum.X, box.Minimum.Y, box.Minimum.Z), transform);
			float3 B = Vector.TransformCoordinate(float3(box.Maximum.X, box.Minimum.Y, box.Minimum.Z), transform);
			float3 C = Vector.TransformCoordinate(float3(box.Maximum.X, box.Maximum.Y, box.Minimum.Z), transform);
			float3 D = Vector.TransformCoordinate(float3(box.Minimum.X, box.Maximum.Y, box.Minimum.Z), transform);
			float3 E = Vector.TransformCoordinate(float3(box.Minimum.X, box.Minimum.Y, box.Maximum.Z), transform);
			float3 F = Vector.TransformCoordinate(float3(box.Maximum.X, box.Minimum.Y, box.Maximum.Z), transform);
			float3 G = Vector.TransformCoordinate(float3(box.Maximum.X, box.Maximum.Y, box.Maximum.Z), transform);
			float3 H = Vector.TransformCoordinate(float3(box.Minimum.X, box.Maximum.Y, box.Maximum.Z), transform);

			return new Box(
				Math.Min(Math.Min(Math.Min(Math.Min(Math.Min(Math.Min(Math.Min(A, B), C), D), E), F), G), H),
				Math.Max(Math.Max(Math.Max(Math.Max(Math.Max(Math.Max(Math.Max(A, B), C), D), E), F), G), H));
		}
		
	}
}
