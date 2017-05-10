using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.UX;
using Fuse.Drawing.Primitives;

namespace Fuse.Effects
{
	partial class EffectHelpers
	{
		static EffectHelpers _instance;
		public static EffectHelpers Instance
		{
			get { return _instance ?? (_instance = new EffectHelpers()); }
		}

		public framebuffer Blur(texture2D original, DrawContext dc, float sigma)
		{
			int maxSamples = 3;
			texture2D src = original;
			framebuffer fb = null;
			float2 sigmas = float2(sigma);
			while (3 * sigmas.X > maxSamples && 3 * sigmas.Y > maxSamples)
			{
				int2 newSize = int2(Math.Max(src.Size.X / 2, 1), Math.Max(src.Size.Y / 2, 1));
				framebuffer newFb = ResampleGaussian5tap(dc, src, newSize);

				if (fb != null)
					FramebufferPool.Release(fb);

				sigmas = Math.Sqrt(sigmas * sigmas - 1); // gauss(gauss(image, y), x) = gauss(image, sqrt(x * x + y * y))
				sigmas *= float2(newSize.X, newSize.Y) / src.Size;
				fb = newFb;
				src = newFb.ColorBuffer;
				maxSamples *= 2;
			}

			int2 samples = (int2)Math.Max(Math.Ceil(3 * sigmas), 1);

			var tmp = BlurHorizontal(dc, src.Size, src, sigmas.X, samples.X);
			if (fb != null)
				FramebufferPool.Release(fb);

			var blur = BlurVertical(dc, tmp.ColorBuffer.Size, tmp.ColorBuffer, sigmas.Y, samples.Y);
			FramebufferPool.Release(tmp);

			return blur;
		}

		framebuffer ResampleBilinear(DrawContext dc, texture2D tex, int2 size)
		{
			var fb = FramebufferPool.Lock(size, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);
			draw Quad
			{
				DepthTestEnabled: false;
				float2 tc: VertexPosition.XY * 0.5f + 0.5f;
				PixelColor: sample(tex, tc, Uno.Graphics.SamplerState.LinearClamp);
			};
			dc.PopRenderTarget();

			return fb;
		}

		framebuffer ResampleGaussian5tap(DrawContext dc, texture2D tex, int2 size)
		{
			var fb = FramebufferPool.Lock(size, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);

			var diagonalOffsets = float2(0.3842896354828526f, 1.2048616327242379f);
			var texSize = tex.Size;
			var centerWeight = 0.16210282163712664f;
			var diagonalWeight = 0.2085034734347498f;

			draw Quad
			{
				DepthTestEnabled: false;
				float2 tc: VertexPosition.XY * 0.5f + 0.5f;
				float4 offsets: float4(-diagonalOffsets, diagonalOffsets);

				float2 tc1: tc + offsets.XY / texSize;
				float2 tc2: tc + offsets.WX / texSize;
				float2 tc3: tc + offsets.ZW / texSize;
				float2 tc4: tc + offsets.YZ / texSize;

				PixelColor: sample(tex, tc,  Uno.Graphics.SamplerState.LinearClamp) * centerWeight +
				            sample(tex, tc1, Uno.Graphics.SamplerState.LinearClamp) * diagonalWeight +
				            sample(tex, tc2, Uno.Graphics.SamplerState.LinearClamp) * diagonalWeight +
				            sample(tex, tc3, Uno.Graphics.SamplerState.LinearClamp) * diagonalWeight +
				            sample(tex, tc4, Uno.Graphics.SamplerState.LinearClamp) * diagonalWeight;
			};

			dc.PopRenderTarget();

			return fb;
		}

		framebuffer ResampleGaussian9tap(DrawContext dc, texture2D tex, int2 size)
		{
			var fb = FramebufferPool.Lock(size, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);

			var texSize = tex.Size;
			var centerWeight = 0.16210282163712664f;
			var cornerWeight = 0.12025979556818871f;
			var crossWeight = 0.089216921055942f;
			var offset = 1.1824335f;

			draw Quad
			{
				DepthTestEnabled: false;
				float2 tc: VertexPosition.XY * 0.5f + 0.5f;
				float3 crossOffsets: float3(float2(offset) / texSize, 0);
				float4 cornerOffsets: float4( float2(offset) / texSize,
				                             -float2(offset) / texSize);
				float2 tc1: tc + crossOffsets.XZ;
				float2 tc2: tc - crossOffsets.XZ;
				float2 tc3: tc + crossOffsets.ZY;
				float2 tc4: tc - crossOffsets.ZY;

				float2 tc5: tc + cornerOffsets.XY;
				float2 tc6: tc + cornerOffsets.ZY;
				float2 tc7: tc + cornerOffsets.XW;
				float2 tc8: tc + cornerOffsets.ZW;

				PixelColor: sample(tex, tc,  Uno.Graphics.SamplerState.LinearClamp) * centerWeight +
				            sample(tex, tc1, Uno.Graphics.SamplerState.LinearClamp) * crossWeight +
				            sample(tex, tc2, Uno.Graphics.SamplerState.LinearClamp) * crossWeight +
				            sample(tex, tc3, Uno.Graphics.SamplerState.LinearClamp) * crossWeight +
				            sample(tex, tc4, Uno.Graphics.SamplerState.LinearClamp) * crossWeight +
				            sample(tex, tc5, Uno.Graphics.SamplerState.LinearClamp) * cornerWeight +
				            sample(tex, tc6, Uno.Graphics.SamplerState.LinearClamp) * cornerWeight +
				            sample(tex, tc7, Uno.Graphics.SamplerState.LinearClamp) * cornerWeight +
				            sample(tex, tc8, Uno.Graphics.SamplerState.LinearClamp) * cornerWeight;
			};

			dc.PopRenderTarget();

			return fb;
		}

		framebuffer ResampleGaussian(DrawContext dc, texture2D tex, int2 size, float sigma, int samples)
		{
			var tmp = BlurHorizontal(dc, int2(size.X, tex.Size.Y), tex, sigma, samples);
			var fb = BlurVertical(dc, size, tmp.ColorBuffer, sigma, samples);
			FramebufferPool.Release(tmp);
			return fb;
		}

		framebuffer BlurHorizontal(DrawContext dc, int2 size, texture2D tex, float sigma, int samples)
		{
			var fb = FramebufferPool.Lock(size, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);
			GaussianBlurSeparable(tex, float2(1, 0), sigma, samples);
			dc.PopRenderTarget();

			return fb;
		}

		framebuffer BlurVertical(DrawContext dc, int2 size, texture2D tex, float sigma, int samples)
		{
			var fb = FramebufferPool.Lock(size, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);
			GaussianBlurSeparable(tex, float2(0, 1), sigma, samples);
			dc.PopRenderTarget();

			return fb;
		}

		void GaussianBlurSeparable(texture2D tex, float2 dir, float sigma, int samples)
		{
			float sigmaSquared = sigma * sigma;
			float scale = 1.0f / (float)Math.Sqrt(2.0f * Math.PI * sigmaSquared);

			float[] weights = new float[1 + samples];
			float2[] offsets = new float2[samples];
			float total = weights[0] = scale;

			for (int i = 0; i < samples; ++i)
			{
				int offset1 = i * 2 + 1;
				int offset2 = i * 2 + 2;

				float weight1 = scale * Math.Exp(-offset1 * offset1 / (2.0f * sigmaSquared));
				float weight2 = scale * Math.Exp(-offset2 * offset2 / (2.0f * sigmaSquared));

				float weight = weight1 + weight2;
				float offset = (offset1 * weight1 + offset2 * weight2) / weight;
				weights[i + 1] = weight;
				offsets[i] = dir * float2(offset / tex.Size.X, offset / tex.Size.Y);
				total += 2 * weight;
			}

			for (int i = 0; i < samples + 1; ++i)
				weights[i] = weights[i] / total;

			draw Quad
			{
				DepthTestEnabled: false;

				float2 tc: VertexPosition.XY * 0.5f + 0.5f;

				PixelColor:
				{
					float4 sum = sample(tex, tc, Uno.Graphics.SamplerState.LinearClamp) * weights[0];
					for (int i = 0; i < samples; ++i)
					{
						sum += sample(tex, tc + offsets[i], Uno.Graphics.SamplerState.LinearClamp) * weights[1 + i];
						sum += sample(tex, tc - offsets[i], Uno.Graphics.SamplerState.LinearClamp) * weights[1 + i];
					}
					return sum;
				};
			};
		}

	}
}
