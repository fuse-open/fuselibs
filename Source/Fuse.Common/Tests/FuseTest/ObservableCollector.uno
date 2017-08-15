using Uno.Collections;
using Uno.Testing;

using Fuse;
using Fuse.Reactive;

namespace FuseTest
{
	/**
		Collects data from an Observable to check behavior of that Observable.
		
		Consider `JoinValues` as the easiset test entry point to check the current contents.
	*/
	public class ObservableCollector : Behavior, IObserver
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			OnItemsChanged();
		}
		
		protected override void OnUnrooted()
		{
			CleanSubscription();
		}
		
		bool _listening;
		IObservableArray _items;
		Uno.IDisposable _subscription;

		public enum LogType
		{
			Add,
			InsertAt,
			RemoveAt,
		}
		
		public class LogItem
		{
			public LogType Type;
			public object Value;
			public int Index;
			
			public LogItem( LogType type, object value = null, int index = -1 ) 
			{
				Type = type;
				Value = value;
				Index = index;
			}
		}
		
		public List<LogItem> Log = new List<LogItem>();
		
		public object Items
		{
			get { return _items;}
			set
			{
				_items = value as IObservableArray;
				OnItemsChanged();
			}
		}
		
		public int Count
		{
			get { return _values.Count; }
		}
		
		public object this[int index]
		{	
			get { return _values[index]; }
		}
		
		void OnItemsChanged()
		{	
			if (!IsRootingStarted) 
				return;
			CleanSubscription();
			if (_items == null)
				return;
			OnNewAll(_items);
			_subscription = (Uno.IDisposable)_items.Subscribe(this);
		}
		
		void CleanSubscription()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
		}
		
		List<object> _values = new List<object>();
		
		void IObserver.OnClear()
		{
			this.Failed = false;
			_values.Clear();
			
			Assert.AreEqual(0, _items.Length);
		}

		void IObserver.OnNewAll(IArray values)
		{
			OnNewAll(values);
		}

		void OnNewAll(IArray values)
		{
			this.Failed = false;
			_values.Clear();
			for (int i=0; i < values.Length; ++i)
			{
				_values.Add( values[i] );
				Assert.AreEqual(_values[i], _items[i]);
			}
				
			Assert.AreEqual(_values.Count, _items.Length);
		}
		
		void IObserver.OnNewAt(int index, object newValue)
		{
			this.Failed = false;
			if (index <0 || index >= _values.Count)
			{
				Fuse.Diagnostics.InternalError( "removing invalid observable item", this );
				return;
			}
			_values[index] = newValue;
			
			Assert.AreEqual(_values.Count, _items.Length);
			Assert.AreEqual(_values[index], _items[index]);
		}
		
		void IObserver.OnSet(object newValue)
		{
			this.Failed = false;
			_values.Clear();
			_values.Add( newValue );
			
			Assert.AreEqual(1, _items.Length);
			Assert.AreEqual(newValue, _items[0]);
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			this.Failed = false;
			_values.Add( addedValue );
			
			Assert.AreEqual( _values.Count, _items.Length);
			Assert.AreEqual( _values[_values.Count-1], _items[_values.Count-1] );
			Log.Add( new LogItem( LogType.Add, addedValue ) );
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			this.Failed = false;
			if (index <0 || index >= _values.Count)
			{
				Fuse.Diagnostics.InternalError( "removing invalid observable item", this );
				return;
			}
			
			_values.RemoveAt(index);
			Assert.AreEqual( _values.Count, _items.Length );
			Log.Add( new LogItem( LogType.RemoveAt, null, index ) );
		}
		
		void IObserver.OnInsertAt(int index, object value)
		{
			this.Failed = false;
			if (index <0 || index > _values.Count)
			{
				Fuse.Diagnostics.InternalError( "removing invalid observable item", this );
				return;
			}
			
			_values.Insert(index, value);
			Assert.AreEqual( _values.Count, _items.Length );
			Assert.AreEqual( value, _items[index] );
			Log.Add( new LogItem( LogType.InsertAt, value, index ) );
		}

		public bool AllowFailed;
		public bool Failed;
		
		void IObserver.OnFailed(string message)
		{
			if (!AllowFailed)
				Fuse.Diagnostics.InternalError( message, this );
				
			_values.Clear();
			Assert.AreEqual(0, _items.Length);
			this.Failed = true;
		}
		
		public string JoinValues()
		{
			string q = "";
			for (int i=0; i < _values.Count; ++i)
			{
				if (i>0) q += ",";
				q += _values[i];
			}
			return q;
		}
	}
}
