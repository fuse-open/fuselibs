using Uno;
using Uno.Collections;
using Uno.Graphics;

namespace Fuse.Nodes
{
	/*
		A DrawRect represents a rectangle drawn onto the screen in world-space coords as follows:

		D  C
		+--+
		| /|
		|/ |
		+--+
		A  B

		We use world-space coords in order to easily be able to plot the drawn rects back on the screen,
		regardless of whether or not the original draws they represent were targeting a framebuffer, the
		backbuffer, etc. This may miss any viewport-related transforms that were applied to the rectangle,
		but it seems that at least for the most part the stuff we do with fuselibs won't behave very
		unpredictably.

		It's probably sufficient to store just top/left and width/height for the draw rects, but in order
		to mimic the vertex transformation pipeline as accurately as possible and allow for world space
		transformations that result in a non-rectangular result, we store each of the 4 vertices of the
		rectangle. In the future it will probably make sense to compare the DrawRects for a given frame
		to determine which ones overlap to measure actual overdraw; this should be possible with this
		configuration, even though it won't be as convenient as comparing simple rectangles necessarily.

		We also store the scissor rect that was used to draw the original rectangle so we can clip the
		draw rect accordingly for more precise info.
	*/
	internal struct DrawRect
	{
		public float4 A;
		public float4 B;
		public float4 C;
		public float4 D;

		public Recti Scissor;

		public DrawRect(float4 a, float4 b, float4 c, float4 d, Recti scissor)
		{
			A = a;
			B = b;
			C = c;
			D = d;

			Scissor = scissor;
		}

		public DrawRect(float4[] verts, Recti scissor)
		{
			A = verts[0];
			B = verts[1];
			C = verts[2];
			D = verts[3];

			Scissor = scissor;
		}
	}

	internal class DrawRectVisualizer
	{
		static readonly DrawRectVisualizer _instance = new DrawRectVisualizer();

		readonly List<DrawRect> _drawRects = new List<DrawRect>();

		public static IEnumerable<DrawRect> DrawRects { get { return _instance._drawRects; } }

		public static void StartFrame()
		{
			_instance._drawRects.Clear();
		}

		public static void EndFrameAndVisualize(DrawContext dc)
		{
			_instance.EndFrameAndVisualizeImpl(dc);
		}

		public static void Append(DrawRect r)
		{
			_instance._drawRects.Add(r);
		}

		void EndFrameAndVisualizeImpl(DrawContext dc)
		{
			// Darken original rendering by drawing a semi-transparent rect on top of it
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

				BlendSrcAlpha: BlendOperand.Zero;
				BlendDstAlpha: BlendOperand.DstAlpha;
			};

			// Draw rects
			foreach(var r in _drawRects)
			{
				dc.PushScissor(r.Scissor);

				draw
				{
					float4[] Vertices: new[]
					{
						r.A, r.B, r.C,
						r.C, r.D, r.A
					};
					float2[] EdgeCoords: new[]
					{
						float2(0, 0),
						float2(1, 0),
						float2(1, 1),
						float2(1, 1),
						float2(0, 1),
						float2(0, 0)
					};

					VertexCount: 6;

					float4 p: vertex_attrib(Vertices);

					ClipPosition: Vector.Transform(p, dc.Viewport.ViewProjectionTransform);

					float2 edgeCoord: vertex_attrib(EdgeCoords);

					PixelColor: float4(edgeCoord, 0, 0.2f);

					CullFace : PolygonFace.None;
					DepthTestEnabled: false;

					BlendEnabled: true;
					BlendSrcRgb: BlendOperand.SrcAlpha;
					BlendDstRgb: BlendOperand.One;

					BlendSrcAlpha: BlendOperand.SrcAlpha;
					BlendDstAlpha: BlendOperand.One;
				};

				dc.PopScissor();
			}

			_drawRects.Clear();
		}
	}
}
