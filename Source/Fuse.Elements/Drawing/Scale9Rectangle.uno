using Uno;
using Uno.Graphics;
using Fuse.Nodes;

namespace Fuse.Elements.Internal
{
	class Scale9Rectangle
	{
		static public Scale9Rectangle Impl = new Scale9Rectangle();

		public void Draw(DrawContext dc, Visual element, float2 size,  float2 scaleTextureSize,
			Texture2D tex, float4 color, float4 margin)
		{
			draw
			{
				float3[] xverts: new []
				{
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1),
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1),
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1),
					float3(0,0,0), float3(1,0,0), float3(0,1,0), float3(0,0,1)
				};

				float3[] yverts: new []
				{
					float3(0,0,0), float3(0,0,0), float3(0,0,0), float3(0,0,0),
					float3(1,0,0), float3(1,0,0), float3(1,0,0), float3(1,0,0),
					float3(0,1,0), float3(0,1,0), float3(0,1,0), float3(0,1,0),
					float3(0,0,1), float3(0,0,1), float3(0,0,1), float3(0,0,1)
				};

				ushort[] indices: new ushort[]
				{
					0,4,5,		0,5,1, 		1,5,6,		1,6,2,		2,6,7, 	 	2,7,3,
					4,8,9, 	  	4,9,5,		5,9,10, 	5,10,6,		6,10,11, 	6,11,7,
					8,12,13, 	8,13,9,		9,13,14,	9,14,10,	10,14,15,	10,15,11
				};

				float3 xv: vertex_attrib(xverts, indices);
				float3 yv: vertex_attrib(yverts, indices);

				CullFace: Uno.Graphics.PolygonFace.None;
				DepthTestEnabled: false;

				apply Fuse.Drawing.AlphaCompositing;

				float Ax: margin.X;
				float Bx: size.X - margin.Z;
				float Cx: size.X;
				float Ay: margin.Y;
				float By: size.Y - margin.W;
				float Cy: size.Y;

				float x: xv.X * Ax + xv.Y * Bx + xv.Z * Cx;
				float y: yv.X * Ay + yv.Y * By + yv.Z * Cy;

				float2 LocalPosition: float2(x, y);

				float4 WorldPosition: Vector.Transform(float4(LocalPosition,0,1), element.WorldTransform);

				public float2 TexCoord : float2(
					xv.X * margin.X + xv.Y * (scaleTextureSize.X-margin.Z) + xv.Z * scaleTextureSize.X,
					yv.X * margin.Y + yv.Y * (scaleTextureSize.Y-margin.W) + yv.Z * scaleTextureSize.Y) / scaleTextureSize;

				ClipPosition: Vector.Transform( WorldPosition, dc.Viewport.ViewProjectionTransform );
				public float4 TextureColor: sample( tex, TexCoord, SamplerState.LinearClamp);
				PixelColor: TextureColor * color;
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(float2(0), size, element.WorldTransform, dc);
		}
	}
}
