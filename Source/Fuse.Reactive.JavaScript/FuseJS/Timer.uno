using Uno;
using Uno.UX;
using Fuse.Scripting;
using Uno.Threading;
using Uno.IO;
using Uno.Collections;

namespace Fuse.Reactive.FuseJS
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Timer
		
		The Timer API lets you schedule functions to be executed after a given time.
		
			var Timer = require("FuseJS/Timer");

			Timer.create(function() {
				console.log("This will run once, after 3 seconds");
			}, 3000, false);
			
			Timer.create(function() {
				console.log("This will run every 10 seconds until forever");
			}, 10000, true);
	*/
	public class TimerModule : NativeModule
	{

		public double MinTimeout
		{
			get
			{
				if (_tm != null)
					return _tm.GetMinTimeout();
				return double.MaxValue;
			}
		}

		readonly TimerManager _tm;
		
		static TimerModule _instance;

		public TimerModule()
		{
			if(_instance != null) return;

			Uno.UX.Resource.SetGlobalKey(_instance = this, "FuseJS/Timer");
			
			_tm = new TimerManager();
			AddMember(new NativeFunction("create", (NativeCallback)Create));
			AddMember(new NativeFunction("delete", (NativeCallback)Delete));

			Reset += OnReset;
		}

		void OnReset(object sender, EventArgs args)
		{
			if(_tm != null)
				_tm.DeleteAllTimers();
		}

		/**
			@scriptmethod create(func, time, repeat)
			@param func (function) The function to be called
			@param time (number) The number of milliseconds to wait before calling the function.
			@param repeat (boolean) If `true`, the timer will repeat until it is deleted, otherwise it will only run once.
			@return (number) The ID of the timer, which can be used later to delete it.
			
			Schedules `func` to be called after `time` milliseconds.

				var Timer = require("FuseJS/Timer");
				Timer.create(function() {
					console.log("This will run once, after 3 seconds");
				}, 3000, false);
				
				Timer.create(function() {
					console.log("This will run every 10 seconds until forever");
				}, 10000, true);
		*/
		object Create(Fuse.Scripting.Context context, object[] args)
		{
			if (args.Length < 3)
				throw new Error("create(): requires at least three arguments");

			if (!(args[0] is Scripting.Function))
				throw new Error("create(): first argument must be a function");

			var func = args[0] as Scripting.Function;
			var ms = Scripting.Value.ToNumber(args[1]);
			var repeat = (bool)args[2];

			var innerArgs = new object[args.Length-3];
			for (int i = 0; i < innerArgs.Length; i++)
				innerArgs[i] = args[3+i];
						
			return _tm.AddTimer(ms, new CallbackClosure(context, func, innerArgs).Callback, repeat);
		}
		
		
		/**
			@scriptmethod delete(timerId)
			@param timerId (number) The ID of the timer to delete, as returned by `Timer.create()`.
			
			Deletes/unschedules a running timer.
			
			```
			var Timer = require("FuseJS/Timer");
			
			var callCount = 0;
			
			var timerId = Timer.create(function() {
				console.log("This will happen 3 times.");
				
				callCount++;
				if(callCount >= 3) {
					Timer.delete(timerId);
				}
			}, 2000, true);
			```
		*/
		object Delete(Fuse.Scripting.Context context, object[] args)
		{
			if (args.Length < 1)
				throw new Error("delete(): requires one argument");

			try
			{
				var handle = Marshal.ToInt(args[0]);
				_tm.DeleteTimer(handle);
			}
			catch (MarshalException me)
			{
				Fuse.Diagnostics.UserWarning("Timer.delete(): The parameter is not a valid timer handle", this);
			}

			return null;
		}
		
		internal bool UpdateModule()
		{
			// NOTE: Don't use UpdateManager for this, for things to run smoothly, this needs to be a JS only thread thing.
			return _tm != null ? _tm.Tick() : false;
		}
		
		class CallbackClosure
		{
			Scripting.Function _func;
			object[] _args;
			Context _context;

			public CallbackClosure(Context context, Scripting.Function func, object[] args)
			{
				if(func == null) throw new Uno.ArgumentNullException("func");
				if(args == null) throw new Uno.ArgumentNullException("args");

				_context = context;
				_func = func;
				_args = args;
			}

			public void Callback()
			{
				_func.Call(_args);
			}
		}
	}

	class TimerManager
	{

		public double GetMinTimeout()
		{
			var min = double.MaxValue;
			var now = Timer.GetMilliseconds();
			for (var i = 0; i < _timers.Count; i++)
			{
				var timer = _timers[i];
				if (timer._isRunning)
				{
					var elapsed = now - timer._startTime;
					min = Math.Min(elapsed, min);
				}
			}
			return min;
		}

		readonly List<Timer> _timers = new List<Timer>();

		public int AddTimer(double ms, Action callback, bool repeat = false)
		{
			var t = new Timer(ms, callback, repeat);
			t.OnStop = RemoveTimer;
			_timers.Add(t);
			return t.ID;
		}

		public void DeleteAllTimers()
		{
			for (var i = _timers.Count - 1; i >= 0; i--)
			{
				_timers[i].Stop();
			}
		}

		public bool DeleteTimer(int id)
		{
			var timer = GetTimer(id);
			if(timer != null)
			{
				timer.Stop();
				return true;
			}
			return false;
		}

		void RemoveTimer(int id)
		{
			for (var i = 0; i < _timers.Count; i++)
			{
				if (_timers[i].ID == id)
					_timers.RemoveAt(i);
			}
		}

		Timer GetTimer(int id)
		{
			for (var i = 0; i < _timers.Count; i++)
			{
				var timer = _timers[i];
				if (timer.ID == id) return timer;
			}
			return null;
		}

		public bool Tick()
		{
			var activity = false;
			for (var i = 0; i < _timers.Count; i++)
			{
				activity = _timers[i].Update() || activity;
			}
			return activity;
		}

		class Timer
		{

			static int _id;

			readonly double _timeout;
			readonly Action _callback;
			readonly bool _repeat;
			
			public bool _isRunning;
			public double _startTime;			
			
			public readonly int ID;
			public Action<int> OnStop;
			
			public Timer(double ms, Action callback, bool repeat)
			{
				ID = _id++;
				_timeout = ms;
				_callback = callback;
				_repeat = repeat;
				Start();
			}

			void Start()
			{
				_startTime = GetMilliseconds();
				_isRunning = true;
			}

			public void Stop()
			{
				_isRunning = false;
				if(OnStop != null)
					OnStop(ID);
			}

			internal bool Update()
			{
				if(!_isRunning) return false;

				var activity = false;
				var now = GetMilliseconds();
				var elapsed = now - _startTime;
				// <= primarily for the case when _timeout == 0 and the timer granuality gives us 0 elapsed time
				// it's unlikely, but theoretically possible
				if (_timeout <= elapsed)
				{
					activity = true;
					try
					{
						if(_callback != null)
							_callback();
					}
					finally
					{
						if(_repeat)
							_startTime = now;
						else
							Stop();
					}
				}
				
				return activity;
			}

			public static double GetMilliseconds()
			{
				return Uno.Diagnostics.Clock.GetTicks()  / 10000;
			}
		}
	}
}
