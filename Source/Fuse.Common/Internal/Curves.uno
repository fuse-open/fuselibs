using Uno;

namespace Fuse.Internal
{
	static class Curves
	{
		//https://en.wikipedia.org/wiki/Kochanek%E2%80%93Bartels_spline
		/**
			This produces an output suitable for CubicHermitePoint
		*/
		public static void KochanekBartelTangent( float4 pa, float4 pb, float4 pc, float4 pd, 
			float tension, float bias, float continuity,
			out float4 tangentIn, out float4 tangentOut )
		{
			var t = tension;
			var b = bias;
			var c = continuity;
			tangentIn = (1-t)*(1+b)*(1+c)/2 * (pb - pa) 
				+ (1-t)*(1-b)*(1-c)/2 * (pc - pb);
			tangentOut = (1-t)*(1+b)*(1-c)/2 * (pc - pb)
				+ (1-t)*(1-b)*(1+c)/2 * (pd - pc);
		}
		
		/**
			Interpolates along a curve between two poitns given the two control values.
			
			The meaning of the control values depends on the curve type.
		*/
		public delegate float4 PointInterpolater(float4 p0, float4 p1, float4 m0, float4 m1, float t );
		
		public static float4 CubicHermitePoint( float4 p0, float4 p1, float4 m0, float4 m1, float t )
		{
			var t2 = t * t;
			var t3 = t2 * t;
			return
				(2*t3 - 3*t2 + 1) * p0 +
				(t3 - 2*t2 + t) * m0 +
				(-2*t3 + 3*t2) * p1 +
				(t3 - t2) * m1;
		}
		
		public static float4 LinearPoint(float4 p0, float4 p1, float4 m0, float4 m1, float t )
		{
			return p0 +
				t * (p1 - p0);
		}
		
		//https://stackoverflow.com/questions/16270825/how-to-get-the-slope-of-the-endpoints-in-a-hermite-spline
		public static void CubicHermiteToBezier(float4 p0, float4 p1, ref float4 t1, ref float4 t2)
		{
			t1 = p0 + t1/3;
			t2 = p1 - t2/3;
		}
		
		public static float2 CalcBezierAt( float2 p0, float2 p1, float2 p2, float2 p3, float t)
		{
			var t2 = t * t;
			var t3 = t2 * t;
			return (1- 3*t + 3*t2 - t3) * p0 +
				(3*t - 6*t2 + 3*t3) * p1 +
				(3*t2 - 3*t3) * p2 +
				(t3) * p3;
		}
	}
}
