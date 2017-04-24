using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	/** Interface of objects that listens to changes in names, as recorded by the @NameRegistry. */
	public interface INameListener
	{
		void OnNameChanged(Node obj, Selector name);
	}

	/** Holds a global registry of the names of currently rooted objects within the @App. */
	public static class NameRegistry
	{
		static Dictionary<Selector, List<Node>> _nameToObj = new Dictionary<Selector, List<Node>>();

		static Dictionary<Node, Selector> _names = new Dictionary<Node, Selector>();

		public static void SetName(Node obj, Selector name)
		{
			Selector oldName = default(Selector);

			if (_names.ContainsKey(obj))
			{
				oldName = _names[obj];
				if (name == oldName) return;

				_nameToObj[oldName].Remove(obj);
				if (_nameToObj[oldName].Count == 0)
					_nameToObj.Remove(oldName);
			}

			if (name != oldName)
			{
				if (name.IsNull)
				{
					_names.Remove(obj);
				}
				else
				{
					_names[obj] = name;

					if (!_nameToObj.ContainsKey(name))
						_nameToObj[name] = new List<Node>();

					_nameToObj[name].Add(obj);
				}

				if (!oldName.IsNull) NotifyNameChanged(obj, oldName);
				if (!name.IsNull) NotifyNameChanged(obj, name);
			}
		}

		internal static List<Node> GetObjectsWithName(Selector name)
		{
			List<Node> res = null;
			_nameToObj.TryGetValue(name, out res);
			return res;
		}

		public static Selector GetName(Node obj)
		{
			if (!_names.ContainsKey(obj)) return default(Selector);
			return _names[obj];
		}

		public static void ClearName(Node obj)
		{
			SetName(obj, default(Selector));
		}

		static Dictionary<Selector, List<INameListener>> _listeners = new Dictionary<Selector, List<INameListener>>();

		public static void AddListener(Selector name, INameListener listener)
		{
			if (!_listeners.ContainsKey(name))
			{
				_listeners.Add(name, new List<INameListener>());
			}
			if (!_listeners[name].Contains(listener))
				_listeners[name].Add(listener);
		}

		public static void RemoveListener(Selector name, INameListener listener)
		{
			List<INameListener> list;
			if (!_listeners.TryGetValue(name, out list))
				return;
				
			list.Remove(listener);
		}
		
		[Obsolete]
		/** @deprecated Use RemoveListern(name, listener) 2017-04-24 */
		public static void RemoveListener(INameListener listener)
		{
			foreach (var list in _listeners.Values)
			{
				if (list.Contains(listener))
				{
					list.Remove(listener);
					break;
				}
			}
		}

		static void NotifyNameChanged(Node obj, Selector name)
		{
			if (_listeners.ContainsKey(name))
				foreach (var listener in _listeners[name].ToArray())
				{
					listener.OnNameChanged(obj, name);
				}
		}
	}
}
