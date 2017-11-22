using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

namespace Fuse.Reactive
{
	/* The part that deals with storing/accessing data on the nodes */
	public partial class Instantiator
	{
		Dictionary<Node,WindowItem> _dataMap = new Dictionary<Node,WindowItem>();
		
		internal int DataIndexOfChild(Node child)
		{
			for (int i = 0; i < _windowItems.Count; i++)
			{
				var wi = _windowItems[i];
				var list = wi.Nodes;
				if (list == null)
					continue;
					
				for (int n = 0; n < list.Count; n++)
				{
					if (list[n] == child)
						return i + Offset;
				}
			}
			return -1;
		}

		object GetData(int dataIndex)
		{
			var e = _items as object[];
			if (e != null) return e[dataIndex];

			var a = _items as IArray;
			if (a != null) return a[dataIndex];

			return null;
		}
		
		int GetDataCount()
		{
			var e = _items as object[];
			if (e != null) return e.Length;

			var a = _items as IArray;
			if (a != null) return a.Length;

			return 0;
		}
		
		internal int DataCount { get { return GetDataCount(); } }
		
		object Node.ISubtreeDataProvider.GetData(Node n)
		{
			WindowItem v;
			if (_dataMap.TryGetValue(n, out v))
			{
				//https://github.com/fusetools/fuselibs/issues/3312
				//`Count` does not introduce data items
				if (v.Data is CountItem)
					return null;
					
				return v.CurrentData;
			}

			return null;
		}
		
 		void UpdateData(WindowItem item, object oldData)
 		{
			if (item.DataLink != null)
			{
				item.DataLink.Dispose();
				item.DataLink = null;
			}

			var obs = item.Data as IObservable;
			if (obs != null)
				item.DataLink = new ObservableLink(obs, item);
			
			var nextData = item.CurrentData;
			for (int i=0; i < item.Nodes.Count; ++i)
			{
				var n = item.Nodes[i];
				_dataMap[n] = item;
				n.OverrideContextParent = this;
				if (oldData != null)
					n.BroadcastDataChange(oldData, nextData);
			}
 		}

 		/** Obtain a value by key from the provided value. This does not work if the data is an Observable. */
 		object GetDataKey(object data, string key)
		{
			var so = data as IObject;

			if (so != null && key != null)
			{
				if (so.ContainsKey(key))
					return so[key];
			}

			return null;
		}
		
		/** 
			Obtain the ID of an item based on the data. This uses the Identity properties. 
			@return id if found, null if not found or no matching ids configured
		*/
		object GetDataId(object data)
		{
			switch (Identity)
			{
				case InstanceIdentity.None:
					return null;
					
				case InstanceIdentity.Key:
					return GetDataKey(data, IdentityKey);
					
				case InstanceIdentity.Object:
					return data;
			}
			
			return null;
		}
		
		/* When the data item is an IObservable it will be subscribed to provide the actual data. 
			Since this subscription can resolve later any of the standard data lookup, like Template
			and IdentityKey should not be used in combination with individual Observable items.
 		*/
		class ObservableLink: ValueObserver
		{
			WindowItem _target;

			public ObservableLink(IObservable obs, WindowItem target)
			{
				_target = target;
				Subscribe(obs);
			}

			public override void Dispose()
			{
				base.Dispose();
				_target = null;
				_currentData = null;
			}

			object _currentData;
			public object Data { get { return _currentData; } }

			protected override void PushData(object newData)
			{
				if (_target == null) return;

				var oldData = _currentData;
				_currentData = newData;
				for (int i=0; i < _target.Nodes.Count; ++i)
					_target.Nodes[i].BroadcastDataChange(oldData, newData);
			}
			
			protected override void LostData()
			{
				PushData(null);
			}
		}
	}
}