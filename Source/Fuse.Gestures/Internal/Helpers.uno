using Uno;
using Uno.Collections;

namespace Fuse.Gestures
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

			if (angle1 <= angle2)
			{
				return x >= angle1 && x <= angle2;
			}
			else
			{
				return x >= angle2 || x <= angle2;
			}
		}

	}
	
	//TODO: The DegreeSpan use in this for _horziontal/VerticalGesture in various places seems
	//complex/wrong. The ranges seem like the opposite/exclusion zones. It's very confusing.
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

			if (length < _lengthThreshold)
				return false;

			var angle = Math.RadiansToDegrees(Math.Atan2(vector.X, vector.Y));

			for (int i = 0; i < _spans.Length; i++)
			{
				if (_spans[i].IsWithinBounds(angle))
					return true;
			}
			return false;
		}
	}

}

