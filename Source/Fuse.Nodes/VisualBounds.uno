using Uno;
using Uno.Collections;

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

		public static implicit operator Box(VisualBounds vb)
		{
			return vb._box;
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
			var add = trans != null ? BoxTransform(nb._box, trans) : nb._box;
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
		
		[Obsolete("Please use the other overload (for performance)")]
		public static Box BoxTransform(Box box, float4x4 transform)
		{
			return BoxTransform(box, FastMatrix.FromFloat4x4(transform));
		}

		static float Min8(float a, float b, float c, float d, float e, float f, float g, float h)
		{
			float min = a;
			if (b < min) min = b;
			if (c < min) min = c;
			if (d < min) min = d;
			if (e < min) min = e;
			if (f < min) min = f;
			if (g < min) min = g;
			if (h < min) min = h;
			return min;
		}

		static float Max8(float a, float b, float c, float d, float e, float f, float g, float h)
		{
			float max = a;
			if (b > max) max = b;
			if (c > max) max = c;
			if (d > max) max = d;
			if (e > max) max = e;
			if (f > max) max = f;
			if (g > max) max = g;
			if (h > max) max = h;
			return max;
		}

		//uses the W paramete runlike Box.Transform (which may be a defect there)
		public static Box BoxTransform(Box box, FastMatrix matrix)
		{
			if (!matrix.HasNonTranslation)
				return new Box(box.Minimum + matrix.Translation, box.Maximum + matrix.Translation);

			float3 A = matrix.TransformVector(float3(box.Minimum.X, box.Minimum.Y, box.Minimum.Z));
			float3 B = matrix.TransformVector(float3(box.Maximum.X, box.Minimum.Y, box.Minimum.Z));
			float3 C = matrix.TransformVector(float3(box.Maximum.X, box.Maximum.Y, box.Minimum.Z));
			float3 D = matrix.TransformVector(float3(box.Minimum.X, box.Maximum.Y, box.Minimum.Z));
			float3 E = matrix.TransformVector(float3(box.Minimum.X, box.Minimum.Y, box.Maximum.Z));
			float3 F = matrix.TransformVector(float3(box.Maximum.X, box.Minimum.Y, box.Maximum.Z));
			float3 G = matrix.TransformVector(float3(box.Maximum.X, box.Maximum.Y, box.Maximum.Z));
			float3 H = matrix.TransformVector(float3(box.Minimum.X, box.Maximum.Y, box.Maximum.Z));

			float minX = Min8(A.X, B.X, C.X, D.X, E.X, F.X, G.X, H.X);
			float minY = Min8(A.Y, B.Y, C.Y, D.Y, E.Y, F.Y, G.Y, H.Y);
			float minZ = Min8(A.Z, B.Z, C.Z, D.Z, E.Z, F.Z, G.Z, H.Z);

			float maxX = Max8(A.X, B.X, C.X, D.X, E.X, F.X, G.X, H.X);
			float maxY = Max8(A.Y, B.Y, C.Y, D.Y, E.Y, F.Y, G.Y, H.Y);
			float maxZ = Max8(A.Z, B.Z, C.Z, D.Z, E.Z, F.Z, G.Z, H.Z);

			return new Box(float3(minX, minY, minZ), float3(maxX, maxY, maxZ));
		}

		internal static VisualBounds Merge(IEnumerable<Visual> visuals)
		{
			bool hasAnyBounds = false;
			Box box = new Box(float3(0), float3(0));
			foreach (var elm in visuals)
			{
				var lrb = elm.LocalRenderBounds;
				if (lrb == VisualBounds.Empty) continue;
				if (lrb == VisualBounds.Infinite) return VisualBounds.Infinite;
				var b = VisualBounds.BoxTransform((Box)lrb, elm.InternLocalTransformInternal);
				if (!hasAnyBounds)
				{
					box = b;
					hasAnyBounds = true;
				}
				else
				{
					if (b.Minimum.X < box.Minimum.X) box.Minimum.X = b.Minimum.X;
					if (b.Minimum.Y < box.Minimum.Y) box.Minimum.Y = b.Minimum.Y;
					if (b.Minimum.Z < box.Minimum.Z) box.Minimum.Z = b.Minimum.Z;
					if (b.Maximum.X > box.Maximum.X) box.Maximum.X = b.Maximum.X;
					if (b.Maximum.Y > box.Maximum.Y) box.Maximum.Y = b.Maximum.Y;
					if (b.Maximum.Z > box.Maximum.Z) box.Maximum.Z = b.Maximum.Z;
				}
			}
			
			if (!hasAnyBounds) return VisualBounds.Empty;
			else return VisualBounds.Box(box);
		}
		
	}
}
