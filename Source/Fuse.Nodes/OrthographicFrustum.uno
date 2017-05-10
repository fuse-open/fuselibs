using Uno;

using Fuse.Internal;

namespace Fuse
{
	public class OrthographicFrustum : IFrustum
	{
		bool _hasOrigin;
		float2 _origin;
		public float2 Origin
		{
			get { return _origin; }
			set
			{
				_origin = value;
				_hasOrigin = true;
			}
		}
		
		bool _hasSize;
		float2 _size;
		public float2 Size
		{
			get 
			{ 
				return _size; 
			}
			set
			{
				_size = value;
				_hasSize = true;
			}
		}

		float4x4 _localFromWorld = float4x4.Identity;
		bool _hasLocalFromWorld;
		public float4x4 LocalFromWorld
		{
			get { return _localFromWorld; }
			set
			{
				_localFromWorld = value;
				_hasLocalFromWorld = true;
			}
		}
			
		public bool TryGetProjectionTransform(ICommonViewport viewport, out float4x4 result)
		{
			var viewSize = _hasSize ? Size : viewport.Size;
			return FrustumMatrix.TryOrthoRH(viewSize.X, viewSize.Y, 1, 1000, out result);
		}
		
		public float4x4 GetViewTransform(ICommonViewport viewport)
		{
			var origin = _hasOrigin ? Origin : float2(0);
			var viewSize = _hasSize ? Size : viewport.Size;

			var t = Matrix.Translation(-viewSize.X/2 - origin.X, -viewSize.Y/2 - origin.Y, -2);
			var s = Matrix.Scaling(1,-1,1);
			var ts = Matrix.Mul(t,s);

			if (_hasLocalFromWorld)
				ts = Matrix.Mul(LocalFromWorld, ts);
			return ts;
		}
		
		public bool TryGetProjectionTransformInverse(ICommonViewport viewport, out float4x4 result)
		{
			var viewSize = _hasSize ? Size : viewport.Size;
			result = FrustumMatrix.OrthoRHInverse(viewSize.X, viewSize.Y, 1, 1000 );
			return true;
		}

		public float4x4 GetViewTransformInverse(ICommonViewport viewport)
		{
			var origin = _hasOrigin ? Origin : float2(0);
			var viewSize = _hasSize ? Size : viewport.Size;

			var s = Matrix.Scaling(1,-1,1);
			var t = Matrix.Translation( viewSize.X/2 + origin.X, viewSize.Y/2 + origin.Y, 2 );
			var ts = Matrix.Mul(s,t);

			if (_hasLocalFromWorld)
				ts = Matrix.Mul(ts, Matrix.Invert(LocalFromWorld));
			return ts;
		}
		
		public float3 GetWorldPosition( ICommonViewport viewport )
		{	
			return float3( (_hasSize ? Size : viewport.Size)/2, 2);
		}
		
		public float2 GetDepthRange( ICommonViewport viewport )
		{
			return float2(1, 1000);
		}
	}
}
