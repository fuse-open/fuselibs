using Uno;

namespace Fuse.Internal
{
	static class VectorUtil
	{
		/**
			Vector projection of `a` on `b`
		*/
		public static float2 Projection(float2 a, float2 b)
		{
			return Vector.Dot(a,b) / Vector.Dot(b,b) * b;
		}
		
		/**
			Scalar projection of `a` on `b`
		*/
		public static float ScalarProjection(float2 a, float2 b )
		{
			return Vector.Dot(a,b)/Vector.Length(b);
		}
		
		/**
			Vector rejection of `a` on `b`
		*/
		public static float2 Rejection(float2 a, float2 b)
		{
			var a1 = Projection(a,b);
			return a - a1;
		}
		
		public static float NormRejection(float2 a, float2 b)
		{
			return Vector.Length( Rejection(a,b) );
		}
		
		/**
			Angle between two vectors. 
			@return in range 0...pi
		*/
		public static float Angle(float2 a, float2 b)
		{
			return Math.Acos( Vector.Dot(a,b) / (Vector.Length(a) * Vector.Length(b)) );
		}
		
		/**
			Distance between a line (defined by two points [line.XY, line.ZW]) and a point `p`
		*/
		public static float DistanceLine(float4 line, float2 p)
		{
			return Vector.Length( Rejection( p - line.XY, line.ZW - line.XY ) );
		}
	}
}
