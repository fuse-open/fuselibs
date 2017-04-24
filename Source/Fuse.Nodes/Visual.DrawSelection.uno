using Uno;
using Uno.Collections;
using Uno.Graphics;

namespace Fuse
{
	class DrawHelpers
	{
		static DrawHelpers _instance;

		internal static DrawHelpers Singelton
		{
			get {
				if (_instance == null)
					_instance = new DrawHelpers();

				return _instance;
			}
		}

		internal void DrawLocalRect(DrawContext dc, Rect rect, float4x4 transform, float lineWidth, float4 color)
		{
			draw
			{
				PrimitiveType: Uno.Graphics.PrimitiveType.LineStrip;

				float2[] Vertices: new[]
				{
					float2(0, 0), float2(0, 1), float2(1, 1), float2(1, 0), float2(0, 0)
				};

				float2 Coord: vertex_attrib(Vertices);
				float2 TexCoord: float2(Coord.X, 1.0f - Coord.Y);
				LineWidth: lineWidth;

				float2 Position: rect.Position;
				float2 Size: rect.Size;

				float4 p: float4(Position + Coord * Size, 0, 1);

				ClipPosition: Vector.Transform(p, transform);

				PixelColor: color;

				DepthTestEnabled: false;
				BlendEnabled: true;
				BlendSrcRgb : BlendOperand.SrcAlpha;
				BlendDstRgb : BlendOperand.OneMinusSrcAlpha;
				BlendSrcAlpha: BlendOperand.One;
				BlendDstAlpha: BlendOperand.OneMinusSrcAlpha;
			};
		}
	}

	public abstract partial class Visual
	{
		void DrawLocalRect(DrawContext dc, Rect rect, float lineWidth, float4 color, float4x4 localToClipTransform)
		{
			DrawHelpers.Singelton.DrawLocalRect(dc, rect, localToClipTransform, lineWidth, color);
		}

		protected void DrawLocalSelectionRect(DrawContext dc, Rect rect)
		{
			var localToClipTransform = dc.GetLocalToClipTransform(this);
			double phase = Time.FrameTime * 4.0;
			float pulse = (float)(0.667 + 0.333 * Math.Sin(phase * Math.PI));
			var color = float4(0.25f, 0.5f, 0.75f, pulse);
			DrawLocalRect(dc, rect, 4, float4(1, 1, 1, 1), localToClipTransform);
			DrawLocalRect(dc, rect, 2, color, localToClipTransform);
		}

		public virtual void DrawSelection(DrawContext dc)
		{
			DrawLocalSelectionRect(dc, LocalRenderBounds.FlatRect);
		}
	}
}
