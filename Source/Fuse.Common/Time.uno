

namespace Fuse
{
	/** A global stopwatch timer that has time=0 when the app launched */
	public static class Time
	{
		static double _base;
		static double _delta;
		static double _prev;
		static double _current;
		static bool _init;

		internal static void Init(double start)
		{
			_base = start;
			_current = start;
			_delta = 0;
			_prev = start;
			_init = true;
		}
		
		internal static void Set(double current)
		{
			if (!_init)
			{
				Init(current);
			}
			else
			{
				_delta = current - _prev;
				_current = current;
				_prev = current;
			}
		}

		/** Returns the number of seconds from the app started to the beginning of
			the current frame. */
		public static double FrameTime
		{
			get { return _current - _base; }
		}
		
		/** Returns the number of seconds between the beginning of this frame and the beginning
			of last frame. */
		public static double FrameInterval
		{
			get { return _delta; }
		}
		
		/** The timestamp (in seconds) used as base for this timer */
		public static double FrameTimeBase
		{
			get { return _base; }
		}

		/** Same as @FrameInterval, in single precision. */
		public static float FrameIntervalFloat
		{
			get { return (float)_delta; }
		}
	}
}