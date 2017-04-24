using Uno;

namespace Fuse
{
	public interface IFrustum
	{
		bool TryGetProjectionTransform( ICommonViewport viewport, out float4x4 result );
		bool TryGetProjectionTransformInverse( ICommonViewport viewport, out float4x4 result );
		float4x4 GetViewTransform( ICommonViewport viewport );
		float4x4 GetViewTransformInverse( ICommonViewport viewport );
		float2 GetDepthRange( ICommonViewport viewport );
		float3 GetWorldPosition( ICommonViewport viewport );
	}
}
