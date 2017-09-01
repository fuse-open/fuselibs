using Uno;
using Uno.Collections;

namespace Fuse
{
	public partial class Node
	{
		/** When implemented by a `Node`, it indicates that the node provides data for its siblings. */
		public interface ISiblingDataProvider
		{
			object Data { get; }
		}

		/** When implemented by a `Node`, it indicates that the node provides data for its children. */
		public interface ISubtreeDataProvider
		{
			object GetData(Node child);
		}

		public interface IDataEnumerator
		{
			/** Receives the next data item in a data context enumeration.
				Returns `true` if enumeration should continue, `false` if enumeration should be aborted. */
			bool NextData(object data);
		}

		class FirstDataEnumerator: IDataEnumerator
		{
			public object Data { get; private set; }
			public bool NextData(object data) { Data = data; return false; }
		}

		internal abstract class DataFinder: IDataEnumerator
		{
			readonly string _key;
			protected string Key { get { return _key; } }
			protected DataFinder(string key) { _key = key; }
			public bool NextData(object data)
			{
				if (_key == "")
				{
					Resolve(null, data);
					return false;
				}
				else
				{
					var obj = data as IObject;
					if (obj != null)
					{
						if (obj.ContainsKey(_key))
						{
							Resolve(obj, obj[_key]);
							return false;
						}
					}
				}

				return true; // keep looking 
			}
			protected abstract void Resolve(IObject provider, object data);
		}

		public object GetFirstData()
		{
			var den = new FirstDataEnumerator();
			EnumerateData(den);
			return den.Data;
		}

		public void EnumerateData(IDataEnumerator e)
		{
			var n = this;

			while (n != null)
			{
				var np = n.ContextParent;
				if (np != null)
				{
					var subdp = np as ISubtreeDataProvider;
					if (subdp != null) 
					{
						var data = subdp.GetData(n);
						if (data != null && !e.NextData(data)) return;
					}
				}

				var p = np as Visual;
				if (p != null)
				{
					for (var dp = p.LastChild<Node>(); dp != null; dp = dp.PreviousSibling<Node>())
					{
						var sdp = dp as ISiblingDataProvider;
						if (sdp != null)
						{
							var data = sdp.Data;
							if (data != null && !e.NextData(data)) return;
						}
					}
				}

				n = n.ContextParent;
			}
		}

		protected void BroadcastDataChange(object oldData, object newData)
		{
			string[] newKeys = null;
			var newObj = newData as IObject;
			if (newObj != null)
			{
				newKeys = newObj.Keys;
				for (var i = 0; i < newKeys.Length; i++)
				{
					OnDataChanged(newKeys[i], newObj[newKeys[i]]);
				}
			}
			else if (newData != null)
			{
				OnDataChanged("", newData);
			}

			var oldObj = oldData as IObject;
			if (oldObj != null)
			{
				var keys = oldObj.Keys;
				for (var i = 0; i < keys.Length; i++)
				{
					if (newKeys != null && Contains(newKeys, keys[i])) continue;
					OnDataChanged(keys[i], null);
				}
			}
			else if (oldData != null)
			{
				if (newKeys != null)
					OnDataChanged("", null);
			}
		}

		static bool Contains(string[] strs, string s)
		{
			for (int i = 0; i < strs.Length; i++)
				if (strs[i] == s) return true;

			return false;
		}

		public interface IDataListener
		{
			void OnDataChanged();
		}

		static Dictionary<string, List<IDataListener>> _dataListeners 
			= new Dictionary<string, List<IDataListener>>();

		public void OnDataChanged(string key, object newValue)
		{
			List<IDataListener> listeners;
			if (_dataListeners.TryGetValue(key, out listeners))
			{
				for (int i = 0; i < listeners.Count; i++)
					listeners[i].OnDataChanged();
			}
		}
		
		public void AddDataListener(string key, IDataListener listener)
		{
			List<IDataListener> listeners;
			if (!_dataListeners.TryGetValue(key, out listeners))
			{
				listeners = new List<IDataListener>();
				_dataListeners.Add(key, listeners);
			}
			listeners.Add(listener);
		}

		public void RemoveDataListener(string key, IDataListener listener)
		{
			_dataListeners[key].Remove(listener);
		}
	}
}
