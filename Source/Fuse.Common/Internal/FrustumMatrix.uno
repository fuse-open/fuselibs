using Uno;

namespace Fuse.Internal
{
	static class FrustumMatrix
	{
		const float _zeroTolerance = 1e-05f;

		static public bool TryOrthoLH(float width, float height, float near, float far, out float4x4 result)
		{
			var depth = far - near;
			if (Math.Min(Math.Abs(width), Math.Abs(height)) < _zeroTolerance ||
			    Math.Abs(depth) < _zeroTolerance)
			{
				result = float4x4.Identity;
				return false;
			}

			result = float4x4.Identity;
			result.M11 = 2.0f / width;
			result.M22 = 2.0f / height;
			result.M33 = -2.0f / depth;
			result.M43 = (far + near) / depth;

			return true;
		}
		
		public static bool TryOrthoRH(float width, float height, float zNear, float zFar, out float4x4 result)
		{
			if (TryOrthoLH(width, height, zNear, zFar, out result))
			{
				result.M33 *= -1.0f;
				return true;
			}

			return false;
		}

		public static float4x4 OrthoLHInverse(float width, float height, float near, float far)
		{
			float halfWidth = width * 0.5f;
			float halfHeight = height * 0.5f;

			//of this OrthoLH
			float4x4 result = float4x4.Identity;
			result.M11 = halfWidth;
			result.M22 = halfHeight;
			result.M33 = -(far - near)/2;
			result.M43 = (near+far)/2;

			return result;
		}

		public static float4x4 OrthoRHInverse(float width, float height, float zNear, float zFar)
		{
			float4x4 result = OrthoLHInverse(width, height, zNear, zFar);
			result.M33 *= -1.0f;
			result.M43 *= -1.0f;
			return result;
		}
		
		public static float4x4 PerspectiveView( float2 viewSize, float distance, float2 relOrigin )
		{
			var t = Matrix.Translation(-relOrigin.X*viewSize.X, -relOrigin.Y*viewSize.Y, distance);
			var s = Matrix.Scaling(1,-1,1);
			return Matrix.Mul(t,s);
		}

		public static float4x4 PerspectiveViewInverse( float2 viewSize, float distance, float2 relOrigin )
		{
			var s = Matrix.Scaling(1,-1,1);
			var t = Matrix.Translation(relOrigin.X*viewSize.X, relOrigin.Y*viewSize.Y, -distance);
			return Matrix.Mul(s,t);
		}
		
		public static bool TryPerspectiveProjection( float2 viewSize, float znear, float zfar, float distance, out float4x4 result )
		{
			var zdiff = znear - zfar;
			if (Math.Min(Math.Abs(viewSize.X), Math.Abs(viewSize.Y)) < _zeroTolerance ||
			    Math.Abs(zdiff) < _zeroTolerance)
			{
				result = float4x4.Identity;
				return false;
			}

			result = default(float4x4);
			result.M11 = 2 * distance / viewSize.X;
			result.M22 = 2 * distance / viewSize.Y;
			result.M33 = -(znear + zfar) / zdiff;
			result.M34 = 1;
			result.M43 = 2 * (zfar * znear) / zdiff;
			return true;
		}
		
		public static bool TryPerspectiveProjectionInverse( float2 viewSize, float znear, float zfar, float distance, out float4x4 result )
		{
			float zdiv = 2*zfar*znear;
			if (Math.Abs(distance) < _zeroTolerance ||
			    Math.Abs(zdiv)  < _zeroTolerance)
			{
				result = float4x4.Identity;
				return false;
			}

			result = default(float4x4);
			result.M11 = viewSize.X / (2 * distance);
			result.M22 = viewSize.Y / (2 * distance);
			result.M34 = (znear - zfar) / zdiv;
			result.M43 = 1;
			result.M44 = (znear + zfar) / zdiv;
			return true;
		}
	}
}
