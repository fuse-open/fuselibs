using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Triggers
{
	[Flags]
	public enum BusyTaskActivity
	{
		None = 0,
		/** A resources is being loaded, either locally or remotely. Resolution could take several seconds. */
		Loading = 1<<0,
		/** There is a deferred processing, such as Defer, that is expected to resolve in a few frames. */
		Deferring = 1<<1,
		/** An extended processing, such as calculation, is happening on the node, resolution could take several seconds, or longer */
		Processing = 1<<2,
		/** Setup of the node and its children that should resolve in a couple of frames. */
		Preparing = 1<<3,
		
		/** There is a failure condition. Resolution may or may not be automatic */
		Failed = 1<<4,
		
		/** Busy activities that should resolve within a few frames */
		Short = Deferring | Preparing,
		/** Busy activities tat may take several seconds, or longer,  to resolve */
		Long = Loading | Processing,
		
		/** Typical busy activities, excluding `Failed` */
		Common = Loading | Deferring | Processing | Preparing,
		
		/** A complete list of all possible BusyTaskActivity's */
		Any = Common | Failed,
	}

	public enum BusyTaskMatch
	{
		/** Matches Parent and it's descendents */
		Descendents,
		/** Matches only the descendent nodes */
		OnlyDescendents,
		/** Matches just the one parent node */
		Parent,
	}
	
	public interface IBusyHandler
	{
		BusyTaskActivity BusyActivityHandled { get; }
	}

	public class BusyTask
	{
		Node _node;

		static List<BusyTask> _tasks = new List<BusyTask>();

		internal enum Type
		{
			RootingPersistent,
			UnrootingDone,
		}
		
		Type _type;
		BusyTaskActivity _activity = BusyTaskActivity.None;
		string _message;
		
		internal BusyTask(Node n, Type type = Type.RootingPersistent, 
			BusyTaskActivity act = BusyTaskActivity.Processing,
			string message = "")
		{
			_type = type;
			_node = n;
			_activity = act;
			_message = message;
			_tasks.Add(this);
			
			_node.Unrooted += OnUnrooted;
			_node.RootingCompleted += OnRooted;
			
			if (_node.IsRootingStarted)
				OnBusyChanged(n);
		}
		
		internal void SetNodeActivity(Node n, BusyTaskActivity act, string message)
		{
			_node = n;
			_activity = act;
			_message = message;
			if (_node.IsRootingStarted)
				OnBusyChanged(_node);
		}

		internal void Done()
		{
			if (_tasks.Contains(this))
			{
				_node.Unrooted -= OnUnrooted;
				_node.RootingCompleted -= OnRooted;
				
				_tasks.Remove(this);
				OnBusyChanged(_node);
			}
		}

		public static bool IsBusy(Node n, BusyTaskMatch match = BusyTaskMatch.Descendents )
		{
			return GetBusyActivity(n) != BusyTaskActivity.None;
		}
		
		public static BusyTaskActivity GetBusyActivity(Node n, BusyTaskMatch match = BusyTaskMatch.Descendents)
		{
			var act = BusyTaskActivity.None;
			
			for (int i = 0; i < _tasks.Count; i++)
			{
				var task = _tasks[i];
				var tnode = task._node;
				if (!tnode.IsRootingStarted)
					continue;
					
				while (tnode != null)
				{
					if (match == BusyTaskMatch.OnlyDescendents)
					{
						if (tnode.ContextParent == n)
						{
							act |= task._activity;
							break;
						}
					}
					else if (tnode == n)
					{
						act |= task._activity;
						break;
					}
		
					if (match == BusyTaskMatch.Parent)
						break;
						
					if (IsBusyHandled(tnode, task._activity)) break;
					tnode = tnode.ContextParent;
				}
			}
			return act;
		}

		static bool IsBusyHandled(Node n, BusyTaskActivity activity)
		{
			var v = n as Visual;
			if (v == null) return false;

			for (var x = v.FirstChild<Node>(); x != null; x = x.NextSibling<Node>())
			{
				var handler = x as IBusyHandler;
				var vact = handler == null ? BusyTaskActivity.None : handler.BusyActivityHandled;
				activity &= ~vact;
			}

			return activity == BusyTaskActivity.None;
		}

		static Dictionary<Node, List<Action>> _listeners 
			= new Dictionary<Node, List<Action>>();

		internal static void AddListener(Node n, Action handler)
		{
			if (!_listeners.ContainsKey(n))
				_listeners.Add(n, new List<Action>());
			
			_listeners[n].Add(handler);
		}

		internal static void RemoveListener(Node n, Action handler)
		{
			_listeners[n].Remove(handler);

			if (_listeners[n].Count == 0)
				_listeners.Remove(n);
		}

		static void OnBusyChanged(Node n)
		{
			if (n.IsUnrooted)
				return;
				
			while (n != null)
			{
				if (_listeners.ContainsKey(n))
				{
					var listeners = _listeners[n];
					for (int i = 0; i < listeners.Count; i++)
						listeners[i]();
				}
				n = n.Parent;
			}
		}

		void OnUnrooted()
		{
			if (_type == Type.UnrootingDone)
				Done();
			OnBusyChanged(_node);
		}
		
		void OnRooted()
		{
			OnBusyChanged(_node);
		}

		public static void SetBusy(Node n, ref BusyTask bt, BusyTaskActivity act, string message = "")
		{
			if (act != BusyTaskActivity.None)
			{
				if (bt == null) 
					bt = new BusyTask(n, Type.RootingPersistent, act, message);
				else
					bt.SetNodeActivity(n, act, message);
			}
			else
			{
				if (bt != null)
				{
					bt.Done();
					bt = null;
				}
			}
		}

		static BusyTask()
		{
			ScriptClass.Register(typeof(BusyTask), 
				new ScriptMethod<BusyTask>("done", done));
		}

		/**
			@scriptmethod done
			
			Completes a [BusyTask](/docs/fuse/triggers/busytaskmodule).
		*/
		static void done(BusyTask bt)
		{
			bt.Done();
		}
	}
}
