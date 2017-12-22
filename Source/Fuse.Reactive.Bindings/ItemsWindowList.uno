using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Reactive.Internal;

namespace Fuse.Reactive
{
	/**
		An implementation of WindowList that handles Each style Items: a fixed array or an  IArray and IObservableArray.
	*/
	partial class ItemsWindowList<T> : WindowList<T>, IObserver,
		WindowListItem.IDataWatcher where T : WindowListItem, new()
	{
		public interface IListener
		{
			void SetValid();
			void SetFailed(string message);
			
			//All changes in WindowItems will be reflected through these calls
			void AddedWindowItem(int windowIndex, T windowItem);
			void RemovedWindowItem(T windowItem);
			void OnCurrentDataChanged(T windowItem, object oldData);
		}
		
		[WeakReference]
		IListener _listener;
		
		public ItemsWindowList( IListener listener ) 
		{
			_listener = listener;
		}
		
		public InstanceIdentity Identity = InstanceIdentity.None;
		
		string _identityKey = null;
		public string IdentityKey
		{
			get { return _identityKey; }
			set 
			{ 
				_identityKey = value; 
				Identity = InstanceIdentity.Key;
			}
		}
		
		object _items;
		public object GetItems() { return _items; }
		/** @hide */
		public void SetItems( object value )
		{
			_items = value;
			if (!_isRooted) return;
			ItemsChanged();
		}
		/** Call to set the items during the OnRooted override (post base.OnRooted call)
			@hide */
		public void SetItemsDerivedRooting( object value )
		{
			_items = value;
			ItemsChanged();
		}

		void ItemsChanged()
		{
			DisposeItemsSubscription();	

			Repopulate(); 

			var obs = _items as IObservableArray;
			if (obs != null)
				_itemsSubscription = obs.Subscribe(this);
		}
		
		IDisposable _itemsSubscription;
		void DisposeItemsSubscription()
		{
			if (_itemsSubscription != null)
			{
				_itemsSubscription.Dispose();
				_itemsSubscription = null;
			}
		}
		
		object GetData(int dataIndex)
		{
			var e = _items as object[];
			if (e != null) return e[dataIndex];

			var a = _items as IArray;
			if (a != null) return a[dataIndex];

			return null;
		}
		
		bool _isRooted = false;
		public void Rooted()
		{
			_isRooted = true;
			ItemsChanged();
		}
		
		public void Unrooted()
		{
			RemoveAll();
			DisposeItemsSubscription();
			_isRooted = false;
		}
		
		void Repopulate()
		{
			RemoveAll();

			var e = _items as object[];
			if (e != null) 
			{
				for (int i = 0; i < e.Length; i++) InsertedDataAt(i);
			}
			else
			{
				var a = _items as IArray;
				if (a != null) 
				{
					for (int i = 0; i < a.Length; i++) InsertedDataAt(i);
				}
			}
		}

 		/** Obtain a value by key from the provided value. This does not work if the data is an Observable. */
 		internal object GetDataKey(object data, string key)
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

		void WindowListItem.IDataWatcher.OnCurrentDataChanged( WindowListItem item, object oldData )
		{
			if (!_isRooted)
				return;
			var wi = item as T;
			if (wi == null)
			{
				Fuse.Diagnostics.InternalError( "Invalid item in WindowList", this );
				return;
			}
			
			_listener.OnCurrentDataChanged( wi, oldData );
		}
		
		protected override T CreateWindowItem( int dataIndex )
		{
			var data = GetData(dataIndex);
			var wi = WindowListItem.Create<T>( this, GetDataId(data), data );
			return wi;
		}

		protected override void OnErrorMessageChanged(string _errorMessage)
		{
			if (!_isRooted)
				return;
			if (_errorMessage != null)
				_listener.SetFailed(_errorMessage);
			else
				_listener.SetValid();
		}
		
		protected override void OnRemovedWindowItem(T wi) 
		{ 
			if (_isRooted) _listener.RemovedWindowItem(wi);
		}
		
		protected override void OnAddedWindowItem(int windowIndex, T wi)
		{
			if (_isRooted) _listener.AddedWindowItem(windowIndex, wi);
		}
		
		public override int GetDataCount()
		{
			//optimization to avoid needless logic in base class prior to rooting
			if (!_isRooted) return 0;
			
			var e = _items as object[];
			if (e != null) return e.Length;

			var a = _items as IArray;
			if (a != null) return a.Length;

			return 0;
		}
		
		
		bool TryUpdateAt(int dataIndex, object newData)
		{
			if (Identity == InstanceIdentity.None)
				return false;
			
			var windowIndex = DataToWindowIndex(dataIndex);
			if (windowIndex < 0 || windowIndex >= WindowItemCount)
				return false;
				
			var wi = GetWindowItem(windowIndex);
			var newId = GetDataId(newData);
			if (wi.Id == null || !Object.Equals(wi.Id, newId))
				return false;
				
			wi.Data = newData;
			return true;
		}
		
		void PatchTo(IArray values)
		{
			//collect new ids in the window
			var newIds = new List<object>();
			var limit = CalcOffsetLimitCountOf(values.Length);
			for (int i=0; i < limit; ++i)
				newIds.Add( GetDataId(values[i+Offset]) );
				
			var curIds = new List<object>();
			for (int i=0; i < WindowItemCount; ++i)
				curIds.Add( GetWindowItem(i).Id);
			
			var ops = PatchList.Patch( curIds, newIds, PatchAlgorithm.Simple, null );
			for (int i=0; i < ops.Count; ++i)
			{
				var op = ops[i];
				switch (op.Op)
				{
					case PatchOp.Remove:
						RemovedDataAt(op.A + Offset);
						break;
					case PatchOp.Insert:
						InsertWindowItem(DataToWindowIndex(op.A + Offset), op.Data);
						break;
					case PatchOp.Update:
						if (!TryUpdateAt(op.A + Offset, values[op.Data]))
						{
							RemovedDataAt(op.A + Offset);
							InsertWindowItem(DataToWindowIndex(op.A + Offset), op.Data);
						}
						break;
				}
			}
		}
		
		
		void IObserver.OnSet(object newValue)
		{
			RemoveAll();
			TrimAndPad();
		}
		
		void IObserver.OnFailed(string message)
		{
			RemoveAll();
			SetError(message);
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			TrimAndPad();
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			RemovedDataAt(index);
			TrimAndPad();
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			InsertedDataAt(index);
			TrimAndPad();
		}

		void IObserver.OnNewAt(int index, object value)
		{
			//use the shortcut if possible (saves overhead)
			if (!TryUpdateAt(index, value))
			{
				RemovedDataAt(index);
				InsertedDataAt(index);
			}
			TrimAndPad();
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (Identity != InstanceIdentity.None)
				PatchTo(values);
			else
				RemoveAll(); //`TrimAndPad` restores the list
			TrimAndPad();
		}

		void IObserver.OnClear()
		{
			RemoveAll();
		}
	}
}
