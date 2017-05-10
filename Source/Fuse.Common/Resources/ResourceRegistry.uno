using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Resources;

namespace Fuse.Resources
{
	public static class ResourceRegistry
	{
		static Dictionary<string, List<Action>> _handlers = new Dictionary<string, List<Action>>();

		public static void AddResourceChangedHandler(string key, Action handler)
		{
			if (!_handlers.ContainsKey(key))
			{
				_handlers.Add(key, new List<Action>());
			}

			_handlers[key].Add(handler);
		}

		public static void RemoveResourceChangedHandler(string key, Action handler)
		{
			if (!_handlers.ContainsKey(key)) throw new Exception();
			_handlers[key].Remove(handler);
		}

		public static void NotifyResourceChanged(string key)
		{
			List<Action> list;
			if (_handlers.TryGetValue(key, out list))
			{
				foreach (var h in list) h();
			} 
		}
	}
}