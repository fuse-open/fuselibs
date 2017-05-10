using Uno;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public class PerspectiveFrustum : IFrustum
	{
		public float Distance { get; set; }
		
		//TODO: PerspectiveOrigin
		
		public bool TryGetProjectionTransform( ICommonViewport viewport, out float4x4 result )
		{
			return FrustumMatrix.TryPerspectiveProjection( viewport.Size, zNearBase,
				zFarBase+Distance, Distance, out result );
		}

		public float4x4 GetViewTransform( ICommonViewport viewport )
		{
			return FrustumMatrix.PerspectiveView( viewport.Size, Distance, float2(0.5f,0.5f) );
		}
		
		public bool TryGetProjectionTransformInverse(ICommonViewport viewport, out float4x4 result)
		{
			return FrustumMatrix.TryPerspectiveProjectionInverse( viewport.Size,
				zNearBase, zFarBase+Distance, Distance, out result );
		}

		public float4x4 GetViewTransformInverse(ICommonViewport viewport)
		{
			return FrustumMatrix.PerspectiveViewInverse( viewport.Size, Distance,float2(0.5f,0.5f) );
		}
		
		public float3 GetWorldPosition( ICommonViewport viewport )
		{
			return float3(viewport.Size/2,-Distance);
		}

		const float zNearBase = 10;
		const float zFarBase = 5000;
		public float2 GetDepthRange( ICommonViewport viewport )
		{
			return float2(zNearBase, zFarBase+Distance);
		}
	}
}