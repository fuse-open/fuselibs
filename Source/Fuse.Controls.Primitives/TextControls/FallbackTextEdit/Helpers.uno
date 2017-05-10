
using Uno;
using Uno.UX;

using Fuse.Controls.FallbackTextRenderer;
using Fuse.Controls.Graphics;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Internal;
using Fuse.Triggers;
using Fuse.Controls.Native;

namespace Fuse.Controls.FallbackTextEdit
{
	class DegreeSpan
	{
		readonly float _a;
		readonly float _b;
		public DegreeSpan(float a, float b)
		{
			_a = a;
			_b = b;
		}
		public bool IsWithinBounds(float x)
		{
			var angle1 = _a;
			var angle2 = _b;
			var rAngle = Math.Mod(Math.Mod(angle2 - angle1, 360.0f) + 360.0f, 360.0f);
			if (rAngle >= 180.0f)
			{
				var a = angle1;
				angle1 = angle2;
				angle2 = a;
			}
			if (angle1 <= angle2) return x >= angle1 && x <= angle2;
			else return x >= angle2 || x <= angle2;
		}
	}
	class SwipeGestureHelper
	{
		readonly DegreeSpan[] _spans;
		readonly float _lengthThreshold;
		public SwipeGestureHelper(float lengthThreshold, params DegreeSpan[] spans)
		{
			_spans = spans;
			_lengthThreshold = lengthThreshold;
		}
		public bool IsWithinBounds(float2 vector)
		{
			var length = Vector.Length(vector);
			if (length < _lengthThreshold) return false;
			var angle = Math.RadiansToDegrees(Math.Atan2(vector.X, vector.Y));
			for (int i = 0; i < _spans.Length; i++)
				if (_spans[i].IsWithinBounds(angle)) return true;
			return false;
		}
	}

}