using Uno;
using Uno.Graphics;

namespace Fuse.Common
{
	class Blitter
	{
		internal static Blitter Singleton = new Blitter();

		public void Blit(texture2D texture, Rect rect, float4x4 localToClipTransform, float opacity = 1.0f, bool flipY = false, PolygonFace cullFace = PolygonFace.None)
		{
			float3x3 textureTransform = float3x3.Identity;
			if (flipY)
			{
				textureTransform.M22 = -1;
				textureTransform.M32 =  1;
			}

			Blit(texture, SamplerState.LinearClamp, true,
			     new Rect(float2(0, 0), float2(1, 1)), textureTransform,
			     rect, localToClipTransform,
			     float4(1, 1, 1, opacity));
		}

		public void Blit(Texture2D texture, SamplerState samplerState, bool preMultiplied,
		                 Rect textureRect, float3x3 textureTransform,
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

			var positionTranslation = Matrix.Translation(localRect.Minimum.X, localRect.Minimum.Y, 0);
			var positionScaling = Matrix.Scaling(localRect.Size.X, localRect.Size.Y, 1);
			var positionMatrix = Matrix.Mul(Matrix.Mul(positionScaling, positionTranslation), localToClipTransform);

			var textureTranslation = float3x3.Identity;
			textureTranslation.M31 = textureRect.Minimum.X;
			textureTranslation.M32 = textureRect.Minimum.Y;
			var textureScaling = float3x3.Identity;
			textureScaling.M11 = textureRect.Size.X;
			textureScaling.M22 = textureRect.Size.Y;
			var textureMatrix = Matrix.Mul(Matrix.Mul(textureScaling, textureTranslation), textureTransform);

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
				ClipPosition: Vector.Transform(v, positionMatrix);
				float2 TexCoord: Vector.Transform(float3(v, 1.0f), textureMatrix).XY;
				PixelColor: sample(texture, TexCoord, samplerState) * color;
			};
		}

		public void Fill(Rect localRect, float4x4 localToClipTransform, float4 color)
		{
			color = float4(color.XYZ * color.W, color.W);

			var positionTranslation = Matrix.Translation(localRect.Minimum.X, localRect.Minimum.Y, 0);
			var positionScaling = Matrix.Scaling(localRect.Size.X, localRect.Size.Y, 1);
			var positionMatrix = Matrix.Mul(Matrix.Mul(positionScaling, positionTranslation), localToClipTransform);

			draw
			{
				BlendEnabled: true;
				BlendSrcRgb: BlendOperand.One;
				BlendDstRgb: BlendOperand.OneMinusSrcAlpha;
				BlendSrcAlpha: BlendOperand.OneMinusDstAlpha;
				BlendDstAlpha: BlendOperand.One;

				CullFace : PolygonFace.None;
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
				ClipPosition: Vector.Transform(v, positionMatrix);
				PixelColor: color;
			};
		}
	}
}
