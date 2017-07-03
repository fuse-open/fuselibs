using Uno;
using Uno.Collections;

namespace Fuse.Nodes
{
	public static class OverdrawHaxxorz
	{
		static readonly List<Rect> _drawRects = new List<Rect>();
		public static IEnumerable<Rect> DrawRects { get { return _drawRects; } }

		public static void StartFrame()
		{
			_drawRects.Clear();
		}

		public static void EndFrame()
		{
			_drawRects.Clear();
		}

		public static void AppendDrawRect(Rect r)
		{
			_drawRects.Add(r);
		}
	}
}
