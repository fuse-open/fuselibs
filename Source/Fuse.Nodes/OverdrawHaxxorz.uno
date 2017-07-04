using Uno;
using Uno.Collections;

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

	public static class OverdrawHaxxorz
	{
		static readonly List<DrawRect> _drawRects = new List<DrawRect>();
		public static IEnumerable<DrawRect> DrawRects { get { return _drawRects; } }

		public static void StartFrame()
		{
			_drawRects.Clear();
		}

		public static void EndFrame()
		{
			_drawRects.Clear();
		}

		public static void AppendDrawRect(DrawRect r)
		{
			_drawRects.Add(r);
		}
	}
}
