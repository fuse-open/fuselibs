using Uno;
using Uno.Collections;

namespace Fuse
{
	public partial class Node
	{
		/** When implemented by a `Node`, it indicates that the node provides data for its siblings. 
			@hide
		*/
		//these, and the next interface, are not meant to be public
		//UNO: https://github.com/fusetools/uno/issues/1524
		public interface ISiblingDataProvider
		{
			object Data { get; }
		}

		/** When implemented by a `Node`, it indicates that the node provides data for its children. 
			@hide
			*/
		public interface ISubtreeDataProvider
		{
			object GetData(Node child);
		}

		/** 
			@hide 
			@deprecated
		*/
		public interface IDataEnumerator
		{
			/** Receives the next data item in a data context enumeration.
				Returns `true` if enumeration should continue, `false` if enumeration should be aborted. */
			bool NextData(object data);
		}

		internal class FirstDataFinder: IDataEnumerator
		{
			readonly string _key;
			public string Key { get { return _key; } }
			public bool HasData { get; private set; }
			public object Data { get; private set; }
			public IObject Provider { get; private set; }
			
			public FirstDataFinder(string key) { _key = key; }
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
			void Resolve(IObject provider, object data)
			{
				Provider = provider;
				Data = data;
				HasData = true;
			}
			
			public void Reset()
			{
				HasData = false;
				Data = null;
				Provider = null;
			}
		}
		
		/** @deprecated Was not meant tob e part of the public API 2018-01-09 */
		[Obsolete]
		public object GetFirstData()
		{
			object r = null;
			TryGetFirstData(out r);
			return r;
		}
		
		internal bool TryGetFirstData(out object result)
		{
			var den = new FirstDataFinder( "" );
			EnumerateData(den);
			result = den.Data;
			return den.HasData;
		}

		/** @deprecated Was not meant to be part of the public API and cannot be supported in the future. 2018-01-09 (likely gone soon) */
		[Obsolete]
		public void EnumerateData(IDataEnumerator e)
		{
			EnumerateDataImpl(e);
		}
		
		/* New functionality should not be built assuming enumeration is possible. It is likely we'll move towards a system that doesn't require such walking of the tree, where walking could be expensive. This form is kept now only as the least effort migration path. */
		void EnumerateDataImpl(IDataEnumerator e)
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
		
		internal protected void BroadcastDataChange(object oldData, object newData)
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
			if (newData != null)
				OnDataChanged("", newData);
 
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
			if (oldData != null && newData == null)
				OnDataChanged("", null);
		}

		static bool Contains(string[] strs, string s)
		{
			for (int i = 0; i < strs.Length; i++)
				if (strs[i] == s) return true;

			return false;
		}

		/** @deprecated The public API using this interface has been deprecated 2018-01-09 */
		public interface IDataListener
		{
			void OnDataChanged();
		}

		static Dictionary<string, List<IDataListener>> _dataListeners 
			= new Dictionary<string, List<IDataListener>>();

		bool CheckDataKey( string key )
		{
			if (key == null)
			{
				Fuse.Diagnostics.InternalError( "null provided as DataContext key" );
				return false;
			}
			return true;
		}
		
		public void OnDataChanged(string key, object newValue)
		{
			if (!CheckDataKey(key)) return;
				
			List<IDataListener> listeners;
			if (_dataListeners.TryGetValue(key, out listeners))
			{
				for (int i = 0; i < listeners.Count; i++)
					listeners[i].OnDataChanged();
			}
		}
		
		/** @deprecated Was not meant to be public. 2018-01-09 */
		public void AddDataListener(string key, IDataListener listener)
		{
			if (!CheckDataKey(key)) return;
				
			List<IDataListener> listeners;
			if (!_dataListeners.TryGetValue(key, out listeners))
			{
				listeners = new List<IDataListener>();
				_dataListeners.Add(key, listeners);
			}
			listeners.Add(listener);
		}

		/** @deprecated Was not meant to be public. 2018-01-09 */
		public void RemoveDataListener(string key, IDataListener listener)
		{
			if (!CheckDataKey(key)) return;
				
			_dataListeners[key].Remove(listener);
		}

		/**
			Creates a subscription to context data on a node. The return value will be populated with the current values.
			
			Subscriptions should no tbe created before this node is rooted, and will behave unpredictably if they are.
			
			You must call `Dispose` on the object when done with it, at the latest during unrooting.
		*/
		internal NodeDataSubscription SubscribeData(string key, IDataListener listener)
		{
			if (!IsRootingStarted)
			{
				Fuse.Diagnostics.InternalError( "SubscribeData called prior to rooting", this );
				//potential errors in our old code make this unsafe to throw, in a future version we can
			}
				
			var dw = new NodeDataSubscription(this, key, listener);
			return dw;
		}

		/**
			A subscription to context data.
			
			You must call `Dispose` when done listening.
		*/
		internal sealed class NodeDataSubscription : IDataListener, IDisposable
		{
			FirstDataFinder _dataFinder;
			
			/** `true` if there is data, `false` otherwise */
			public bool HasData { get { return _dataFinder.HasData; } }
			/** The data which has been found. This will be `null` if `HasData == false`. It may be `null` even if `HasData == true`, indicating it found a null */
			public object Data { get { return _dataFinder.Data; } }
			/** The providing object for the data */
			public IObject Provider { get { return _dataFinder.Provider; } }
			
			Node _origin;
			IDataListener _listener;
			
			internal NodeDataSubscription(Node origin, string key, IDataListener listener)
			{
				_dataFinder = new FirstDataFinder(key);
				_origin = origin;
				_origin.EnumerateDataImpl(_dataFinder);
				_listener = listener;
				
				if (_listener != null)	
					_origin.AddDataListener( _dataFinder.Key, this );
			}
			
			void IDataListener.OnDataChanged()
			{
				if (_origin == null)
					return;
					
				_dataFinder.Reset();
				_origin.EnumerateDataImpl(_dataFinder);
				if (_listener != null)
					_listener.OnDataChanged();
			}
			
			public void Dispose()
			{
				if (_listener != null)	
					_origin.RemoveDataListener( _dataFinder.Key, this );
					
				_dataFinder = null;
				_origin = null;
				_listener = null;
			}
		}
	}
}
