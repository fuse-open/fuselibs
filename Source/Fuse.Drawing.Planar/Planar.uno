using Uno;
using Uno.Graphics;

namespace Fuse.Drawing.Planar
{
	public block Base
	{
		public Fuse.DrawContext DrawContext: undefined;
		public Fuse.Visual Visual: Node;
		public Fuse.Visual Node: null; // deprecated - for backwards compatibility

		public float2 Position: float2(0);
		public float2 Size: float2(1);
		public float2 Origin: float2(0);
		public float Rotation: 0;

		public float2 VertexPosition2: undefined;
		public float3 VertexPosition: float3(VertexPosition2,0), undefined;

		float4x4 LocalTransform: Matrix.Mul(
			Matrix.Translation( -Origin.X, -Origin.Y, 0 ),
			Matrix.Scaling( Size.X, Size.Y, 1 ),
			Matrix.RotationZ( Rotation ),
			Matrix.Translation( Position.X, Position.Y, 0 )
			);

		float4x4 WorldTransform: Visual != null ?
			Matrix.Mul(LocalTransform,Visual.WorldTransform) : LocalTransform;
		float4 WorldPos: Vector.Transform( VertexPosition, WorldTransform );

		ClipPosition: Vector.Transform( WorldPos, DrawContext.Viewport.ViewProjectionTransform );

		apply AlphaCompositing;
		CullFace: DrawContext.CullFace;
		DepthTestEnabled: false;
	}

	public block Rectangle
	{
		apply Base;

		float2[] Vertices: new []
			{
				float2(0, 0), float2(0, 1), float2(1, 1),
				float2(0, 0), float2(1, 1), float2(1, 0)
			}
		;
		float2 VertexData: vertex_attrib(Vertices);
		public bool Invert: false;
		public float2 TexCoord: Invert ? float2( VertexData.X, 1 - VertexData.Y ): VertexData;
		VertexPosition2: VertexData;
		VertexCount: 6;
	}

	public block Image
	{
		apply Rectangle;

		public Texture2D Texture: undefined;
		public float4 TextureColor:
			req(SamplerState as Uno.Graphics.SamplerState) sample(Texture, TexCoord, SamplerState),
			sample(Texture, TexCoord, SamplerState.LinearClamp);
		PixelColor: TextureColor;
	}
}
