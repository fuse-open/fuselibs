using Uno;
using Uno.Collections;
using Uno.Graphics;

namespace Fuse.Nodes
{
	/*
		A DrawRect represents a rectangle drawn onto the screen in clip-space coords as follows:

		D  C
		+--+
		| /|
		|/ |
		+--+
		A  B

		We use clip-space coords in order to easily take into account any viewport-related transforms
		that were applied to a rectangle as possible. This may mean that the resulting area isn't
		actually rectangular, so we store all 4 vertex positions rather than just top/left and
		width/height. In the future it will probably make sense to compare the DrawRects for a given
		frame to determine which ones overlap to measure actual overdraw; this should be possible
		with this configuration, even though it won't be as convenient as comparing simple rectangles
		necessarily.
	*/
	public struct DrawRect
	{
		public float4 A;
		public float4 B;
		public float4 C;
		public float4 D;

		public DrawRect(float4 a, float4 b, float4 c, float4 d)
		{
			A = a;
			B = b;
			C = c;
			D = d;
		}

		public DrawRect(float4[] verts)
		{
			A = verts[0];
			B = verts[1];
			C = verts[2];
			D = verts[3];
		}
	}

	public class OverdrawHaxxorz
	{
		static readonly OverdrawHaxxorz _instance = new OverdrawHaxxorz();

		readonly List<DrawRect> _drawRects = new List<DrawRect>();

		public static IEnumerable<DrawRect> DrawRects { get { return _instance._drawRects; } }

		public static void StartFrame()
		{
			_instance._drawRects.Clear();
		}

		public static void EndFrameAndRenderDrawRects()
		{
			_instance.EndFrameAndRenderDrawRectsImpl();
		}

		public static void AppendDrawRect(DrawRect r)
		{
			_instance._drawRects.Add(r);
		}

		void EndFrameAndRenderDrawRectsImpl()
		{
			// Fade out app by drawing a semi-transparent rect on top of it
			draw
			{
				float2[] Vertices: new[]
				{
					float2(0, 0), float2(0, 1), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(1, 0)
				};

				float2 Coord: vertex_attrib(Vertices);

				ClipPosition: float4(Coord * 2 - 1, 0, 1);

				PixelColor: float4(0, 0, 0, 0.5f);

				CullFace : PolygonFace.None;
				DepthTestEnabled: false;

				BlendEnabled: true;
				BlendSrcRgb: BlendOperand.SrcAlpha;
				BlendDstRgb: BlendOperand.OneMinusSrcAlpha;

				BlendSrcAlpha: BlendOperand.SrcAlpha;
				BlendDstAlpha: BlendOperand.OneMinusSrcAlpha;
			};

			// Batch draw rects and draw
			var verts = new List<float4>();

			foreach (var r in OverdrawHaxxorz.DrawRects)
			{
				verts.AddRange(new[]
				{
					r.A, r.B, r.C,
					r.C, r.D, r.A
				});
			}

			draw
			{
				ClipPosition: vertex_attrib(verts.ToArray());

				PixelColor: float4(1, 0, 0, 0.2f);

				CullFace : PolygonFace.None;
				DepthTestEnabled: false;

				BlendEnabled: true;
				BlendSrcRgb: BlendOperand.SrcAlpha;
				BlendDstRgb: BlendOperand.One;

				BlendSrcAlpha: BlendOperand.SrcAlpha;
				BlendDstAlpha: BlendOperand.One;
			};

			_drawRects.Clear();
		}
	}
}
