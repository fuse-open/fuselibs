using Uno;
using Uno.Collections;

namespace Fuse
{
	/** Provides callback services on the UI thread based on elapsed time. */
	public sealed class Timer
	{
		Action _callback;
		double _startTime;
		double _interval;
		bool _running;
		bool _once;

		Timer(double interval, Action callback)
		{
			_callback = callback;
			_startTime = Uno.Diagnostics.Clock.GetSeconds();
			_interval = interval;
			_once = true;
		}

		void Start()
		{
			_startTime = Uno.Diagnostics.Clock.GetSeconds();
			UpdateManager.AddAction(Update);
			_running = true;
		}

		void Stop()
		{
			_running = false;
			UpdateManager.RemoveAction(Update);
		}

		void Update()
		{
			var now = Uno.Diagnostics.Clock.GetSeconds();
			var time = now - _startTime;

			if (time > _interval)
			{
				_callback();

				if (_once) Stop();
				else _startTime = now;
			}
		}

		/** Executes a callback on the UI thread after a minimum specified duration.

			Note that the UI thread performs rendering and is only executing callbacks once
			per frame. Since the interval between frames is typically 16 milliseconds, this
			method can not be relied upon for very short durations. For high-performance timing,
			consider spawning a new thread. 
		*/
		public static void Wait(double duration, Action callback)
		{
			var t = new Timer(duration, callback);
			t.Start();
		}
	}
}