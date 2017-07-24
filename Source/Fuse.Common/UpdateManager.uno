using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse
{
	public enum UpdateStage
	{
		//prior to the update loop, handling the raw OS events
		None = -1,
		/** where frame-based actions are triggered by default (UpdateManager.AddAction) */
		Primary,
		/** Includes layout and responding triggers. */
		Layout,
		//tree structure and data should be static at this point
		Draw
	}
	
	/**
		Provides appropriate values for priority of actions within the Layout stage.
	*/
	public static class LayoutPriority
	{
		static public int Layout = 0;
		static public int Placement = 100;
		//everything below this is considered part of a logical rooting group
		static public int EndGroup = 499;
		//should be resolved after other normal activities, but is not cleanup
		static public int Later = 500;
		//should be resolved last, such as cleanup
		static public int Post = 1000;
	}
	
	public interface IUpdateListener
	{
		void Update();
	}
	
	class UpdateListener
	{
		//only one of update/action will be set
		public Action action;
		public IUpdateListener update;
		public bool removed;
		public int deferFrame;
		public int sequence;
		
		public void Invoke()
		{
			if (removed)
				return;
				
			if (action != null)
				action();
				
			if (update != null)
				update.Update();
		}
	}

	struct UpdateAction
	{
		public Action action;
		public IUpdateListener update;

		public void Invoke()
		{
			if (action != null)
				action();
				
			if (update != null)
				update.Update();
		}
	}

	class Stage
	{
		public UpdateStage UpdateStage;
		
		public List<UpdateListener> Listeners = new List<UpdateListener>();
		public List<UpdateListener> Onces = new List<UpdateListener>();
		public List<UpdateListener> OncesPending = new List<UpdateListener>();
		
		public Dictionary<int, Queue<UpdateAction>> PhaseDeferredActions = new Dictionary<int, Queue<UpdateAction>>();

		public int HighestPriority
		{
			get
			{
				int max = -1;
				foreach (var p in PhaseDeferredActions)
					if (p.Value.Count > 0 && p.Key > max) max = p.Key;
				return max;
			}
		}
		
		public bool HasListenersRemoved;

		public Stage(UpdateStage _updateStage)
		{
			UpdateStage = _updateStage;
		}
		
		//insert them in sequenced order
		public void Insert( List<UpdateListener> list, UpdateListener us )
		{
			for (int i=list.Count; i > 0; --i)
			{
				if (list[i-1].sequence <= us.sequence)
				{
					list.Insert(i, us);
					return;
				}
			}
			
			list.Insert(0,us);
		}

		public void AddDeferredAction( Action pu, IUpdateListener ul, int priority = 0 )
		{
			Queue<UpdateAction> list;
			if (!PhaseDeferredActions.TryGetValue(priority, out list))
				PhaseDeferredActions.Add(priority, list = new Queue<UpdateAction>());
			
			list.Enqueue(new UpdateAction{ action = pu, update = ul });
		}
	}

	class UpdateDispatcher: Uno.Threading.IDispatcher
	{
		public void Invoke(Action action)
		{
			UpdateManager.PostAction(action);
		}
	}
	
	public static class UpdateManager
	{
		static List<Stage> _stages = new List<Stage>();
		
		static List<Action> _postActions = new List<Action>();
		static List<Action> _postActionsSwap = new List<Action>();
		
		static UpdateManager()
		{
			for (int i=0; i <= (int)UpdateStage.Draw; ++i)
				_stages.Add( new Stage((UpdateStage)i) );
		}

		public static readonly Uno.Threading.IDispatcher Dispatcher = new UpdateDispatcher();

		
		public static void AddAction(Action pu, UpdateStage stage = UpdateStage.Primary/*,
			int sequence = 0*/) //em: I've disabled sequence for now since we don't need it yet
		{
			var us = new UpdateListener();
			us.action = pu;
			//us.sequence = sequence;
			
			var s = _stages[(int)stage];
			s.Insert( s.Listeners, us );
		}

		public static void AddAction(IUpdateListener pu, UpdateStage stage = UpdateStage.Primary)
		{
			var us = new UpdateListener();
			us.update = pu;
			
			var s = _stages[(int)stage];
			s.Insert( s.Listeners, us );
		}


		static bool RemoveFrom( List<UpdateListener> list, Action action, IUpdateListener update)
		{
			//must defer removal from list since remove will most likely be called during an update
			for( int i=0; i < list.Count; ++i )
			{
				if (list[i].removed)
					continue;
					
				if ( (action != null && object.Equals(action, list[i].action)) ||
					(update != null && object.Equals(update, list[i].update)) )
				{
					list[i].removed = true;
					return true;
				}
			}
			return false;
		}
		
		public static void RemoveAction(Action pu, UpdateStage stage = UpdateStage.Primary)
		{
			var s = _stages[(int)stage];
			if (!RemoveFrom( s.Listeners, pu, null ))	
				throw new Exception("no Action found to remove");
			s.HasListenersRemoved = true;
		}
		
		public static void RemoveAction(IUpdateListener pu, UpdateStage stage = UpdateStage.Primary)
		{
			var s = _stages[(int)stage];
			if (!RemoveFrom( s.Listeners, null, pu ))	
				throw new Exception("no Action found to remove");
			s.HasListenersRemoved = true;
		}
		
		public static void AddOnceAction(Action pu, UpdateStage stage = UpdateStage.Primary)
		{
			var us = new UpdateListener();
			us.action = pu;
			_stages[(int)stage].OncesPending.Add(us);
		}

		public static void RemoveOnceAction(Action pu, UpdateStage stage = UpdateStage.Primary)
		{
			var s = _stages[(int)stage];
			if (RemoveFrom( s.OncesPending, pu, null ))
				return;
			
			if (!RemoveFrom( s.Onces, pu, null ))
				throw new Exception("no OnceAction found to remove");
		}
		
		public static void PerformNextFrame(Action pu, UpdateStage stage = UpdateStage.Primary)
		{
			var us = new UpdateListener();
			us.action = pu;
			us.deferFrame = FrameIndex + 1;
			_stages[(int)stage].OncesPending.Add(us);
		}

		static object _postActionLock = new object();

		/**
			This is the only thread-safe entry point. It adds an action to be executed in the
			Update thread.
		*/
		public static void PostAction(Action pu)
		{
			if defined(!WebGL)
			{
				lock (_postActionLock)
				{
					_postActions.Add(pu);
				}
			}
			else
				_postActions.Add(pu);
		}
		
		static Stage CurrentDeferredActionStage
		{	
			get { return _currentStage != null ? _currentStage : _stages[0]; }
		}
		
		/**
			Add an action to the deferred set of actions. Defaults to the current stage.
			
			Be aware that binding a member function to `Action` involves allocating memory. If you
			already have a suitable object use the `IUpdateListener` version instead.
		*/
		public static void AddDeferredAction(Action pu, UpdateStage stage = UpdateStage.None, int priority=0)
		{
			var use = stage != UpdateStage.None ? _stages[(int)stage] : CurrentDeferredActionStage;
			use.AddDeferredAction(pu, null, priority);
		}
		
		public static void AddDeferredAction(IUpdateListener pu, UpdateStage stage = UpdateStage.None, int priority=0)
		{
			var use = stage != UpdateStage.None ? _stages[(int)stage] : CurrentDeferredActionStage;
			use.AddDeferredAction(null, pu, priority);
		}
		
		public static void AddDeferredAction(Action pu, int priority)
		{
			AddDeferredAction(pu, UpdateStage.None, priority);
		}
		
		public static void AddDeferredAction(IUpdateListener pu, int priority)
		{
			AddDeferredAction(pu, UpdateStage.None, priority);
		}
		
		public static void IncreaseFrameIndex()
		{
			_frameIndex++;
		}

		static Stage _currentStage = null;
		public static void Update()
		{
			ProcessPostActions();
			ProcessStages();
		}
		
		static void ProcessStages()
		{
			extern double t;

			int c = _stages.Count;
			for (int i=0; i < (int)c; ++i)
			{
				if defined(FUSELIBS_PROFILING)
				{
					t = Uno.Diagnostics.Clock.GetSeconds();
					Profiling.BeginRegion(_stages[i].UpdateStage.ToString());
				}

				Update(_stages[i]);

				if defined(FUSELIBS_PROFILING)
					Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
			}
		}
		
		internal static UpdateStage CurrentStage
		{
			get { return _currentStage == null ? UpdateStage.None : _currentStage.UpdateStage; }
		}
		
		internal static bool IsPastStage(UpdateStage stage)
		{
			return (int)stage < (int)CurrentStage;
		}
		
		static void Update(Stage stage)
		{
			_currentStage = stage;
			List<Exception> _exceptions = null;
			
			ProcessOnces( stage, ref _exceptions );
			ProcessListeners( stage, ref _exceptions );
			ProcessDeferredActions( stage, ref _exceptions );
			
			_currentStage = null;
			CheckExceptions(_exceptions);
		}
		
		static void ProcessOnces(Stage stage, ref List<Exception> _exceptions)
		{
			if (stage.OncesPending.Count > 0)
			{
				var t = stage.Onces;
				stage.Onces = stage.OncesPending;
				stage.OncesPending = t;
				stage.OncesPending.Clear();
				
				var c = stage.Onces.Count;
				for (int i=0; i < c; ++i)
				{
					var ul = stage.Onces[i];
					if (ul.deferFrame > FrameIndex)
					{
						stage.OncesPending.Add(ul);
					}
					else
					{
						try
						{
							ul.Invoke();
						}
						catch (Exception e)
						{
							if (_exceptions == null)
								_exceptions = new List<Exception>();
							_exceptions.Add(e);
						}
					}
				}
			}
		}
		
		static void ProcessListeners(Stage stage, ref List<Exception> _exceptions)
		{
			//iterate by index so new ones can be added and even activated the same frame
			for (int i=0; i < stage.Listeners.Count; ++i)
			{
				var ul = stage.Listeners[i];
				try
				{
					ul.Invoke();
				}
				catch (Exception e)
				{
					if (_exceptions == null)
						_exceptions = new List<Exception>();
					_exceptions.Add(e);
				}
			}
			
			if (stage.HasListenersRemoved)
			{
				for (int i=stage.Listeners.Count-1; i>=0; --i)
				{
					if (stage.Listeners[i].removed)
						stage.Listeners.RemoveAt(i);
				}
			}
		}

		static void ProcessDeferredActions(Stage stage, ref List<Exception> _exceptions)
		{
			for (var priority = stage.HighestPriority; priority != -1; priority = stage.HighestPriority)
			{
				var queue = stage.PhaseDeferredActions[priority];
				var a = queue.Dequeue();

				try
				{
					a.Invoke();
				}
				catch (Exception e)
				{
					if (_exceptions == null)
						_exceptions = new List<Exception>();
					_exceptions.Add(e);
				}
			}
		}
		
		/** A test interface that just clears the pending deferred actions */
		static internal void TestProcessCurrentDeferredActions()
		{
			List<Exception> _exceptions = null;
			ProcessDeferredActions(CurrentDeferredActionStage, ref _exceptions);
			CheckExceptions(_exceptions);
		}
		
		static int maxDeferred =0;

		static void ProcessPostActions()
		{
			extern double t;
			if defined(FUSELIBS_PROFILING)
			{
				t = Uno.Diagnostics.Clock.GetSeconds();
				Profiling.BeginRegion("ProcessPostActions");
			}

			ProcessPostActionsImpl();

			if defined(FUSELIBS_PROFILING)
				Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
		}
		
		static void ProcessPostActionsImpl()
		{
			List<Exception> _exceptions = null;
			
			//loop to ensure any posted actions during processing are also handled
			while(true)
			{
				// the null here is just to convince the compier; this will be
				// overwritten inside the lock-statement below anyway
				List<Action> a = null;
				lock (_postActionLock)
				{
					a = _postActions;
					_postActions = _postActionsSwap;
					_postActionsSwap = a;
				}

				if (a.Count == 0)
					break;
					
				for (int i=0; i < a.Count; ++i )
				{
					try
					{
						a[i]();
					}
					catch (Exception e)
					{
						if (_exceptions == null)
							_exceptions = new List<Exception>();
						_exceptions.Add(e);
					}
				}
				a.Clear();
			}

			_currentStage = null;
			CheckExceptions(_exceptions);
		}
		
		static void CheckExceptions(List<Exception> exs)
		{
			if (exs != null)
			{
				if (exs.Count == 1)
					throw new WrapException(exs[0]);
				else
					throw new AggregateException(exs.ToArray());
			}
		}
		
		static int _frameIndex = 1; //start at 1 so 0 can be used as not set
		public static int FrameIndex
		{
			get { return _frameIndex; }
		}

		static internal void ForceLayoutUpdateNow()
		{
			Update(_stages[(int)UpdateStage.Layout]);
		}
	}
}
