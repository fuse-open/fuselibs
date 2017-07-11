using Uno;
using Uno.Collections;

namespace Fuse
{
	/** Provides callback services on the UI thread based on elapsed time. */
	public sealed class Timer : IDisposable
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
			UpdateManager.RemoveAction(Update);
			_running = false;
		}

		void Update()
		{
			var now = Uno.Diagnostics.Clock.GetSeconds();
			var time = now - _startTime;

			if (time > _interval)
			{
				_callback();
				if (_once) Dispose();
				else _startTime = now;
			}
		}

		public void Dispose()
		{
			if(!_running)
				return;
			Stop();
		}

		/** Executes a callback on the UI thread after a minimum specified duration.

			Note that the UI thread performs rendering and is only executing callbacks once
			per frame. Since the interval between frames is typically 16 milliseconds, this
			method can not be relied upon for very short durations. For high-performance timing,
			consider spawning a new thread. 
		*/
		public static IDisposable Wait(double duration, Action callback)
		{
			var t = new Timer(duration, callback);
			t.Start();
			return t;
		}
	}
}
