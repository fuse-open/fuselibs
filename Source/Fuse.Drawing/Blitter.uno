using Uno;
using Uno.Graphics;

namespace Fuse.Drawing
{
	class Blitter
	{
		internal static Blitter Singleton = new Blitter();

		public void Blit(texture2D texture, Rect rect, float4x4 localToClipTransform, float opacity = 1.0f, bool flipY = false, PolygonFace cullFace = PolygonFace.None)
		{
			float4x4 textureTransform = float4x4.Identity;
			if (flipY)
			{
				textureTransform.M22 = -1;
				textureTransform.M42 =  1;
			}

			Blit(texture, SamplerState.LinearClamp, true,
			     new Rect(float2(0, 0), float2(1, 1)), textureTransform,
			     rect, localToClipTransform,
			     float4(1, 1, 1, opacity));
		}

		public void Blit(Texture2D texture, SamplerState samplerState, bool preMultiplied,
		                 Rect textureRect, float4x4 textureTransform,
		                 Rect localRect, float4x4 localToClipTransform,
		                 float4 color, PolygonFace cullFace = PolygonFace.None)
		{
			BlendOperand srcRGB, dstRGB;
			BlendOperand srcA, dstA;

			if (preMultiplied)
			{
				srcRGB = BlendOperand.One;
				dstRGB = BlendOperand.OneMinusSrcAlpha;

				srcA = BlendOperand.OneMinusDstAlpha;
				dstA = BlendOperand.One;
				color = float4(color.XYZ * color.W, color.W);
			}
			else
			{
				srcRGB = BlendOperand.SrcAlpha;
				dstRGB = BlendOperand.OneMinusSrcAlpha;

				srcA = BlendOperand.One;
				dstA = BlendOperand.OneMinusSrcAlpha;
			}

			// TODO: bake localRect + localToClipTransform
			// TODO: bake textureRect + textureTransform
			draw
			{
				BlendEnabled: true;
				BlendSrcRgb: srcRGB;
				BlendDstRgb: dstRGB;
				BlendSrcAlpha: srcA;
				BlendDstAlpha: dstA;

				CullFace : cullFace;
				DepthTestEnabled: false;
				float2[] verts: readonly new float2[] {

					float2(0,0),
					float2(1,0),
					float2(1,1),
					float2(0,0),
					float2(1,1),
					float2(0,1)
				};

				float2 v: vertex_attrib(verts);
				float2 LocalVertex: localRect.Minimum + v * localRect.Size;
				ClipPosition: Vector.Transform(LocalVertex, localToClipTransform);
				float2 TexCoord: textureRect.Minimum + v * textureRect.Size;
				TexCoord: Vector.TransformCoordinate(prev, textureTransform);
				PixelColor: sample(texture, TexCoord, samplerState) * color;
			};
		}
	}
}
