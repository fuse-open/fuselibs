using Uno.Collections;

using Fuse.Reactive;

namespace Fuse.Charting
{
	/**
		Filters items in an Observable.
	*/
	abstract class FilterObservable : ObservableData, IObserver
	{
		IObservableArray _source;
		public IObservableArray Source
		{
			get { return _source; }
			set
			{
				CleanSubscription();
				_source = value;

				if (HasSubscription)
					OnSubscription();
			}
		}
		
		Uno.IDisposable _subscription;
		void CleanSubscription()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
		}
		
		public void Update()
		{
			SyncItems();
		}
		
		override protected int GetLength()
		{
			return _outputItems.Count;
		}
		
		override protected object GetItem(int index)
		{
			return _outputItems[index].Value;
		}
		
		class SourceItem
		{
			public int Index; //-1 is not in list
			public object Value;
			public bool Accept;
			
			public bool Desired
			{
				get { return Index != -1 && Accept; }
			}
		}
		
		List<SourceItem> _sourceItems = new List<SourceItem>();
		List<SourceItem> _outputItems = new List<SourceItem>();
		
		override protected void OnSubscription() 
		{ 
			if (_subscription != null || Source == null)
				return;
				
			_subscription =  Source.Subscribe(this);
			SyncItems();
		}
			
		override protected void OnUnsubscription() 
		{
			CleanSubscription();
		}
		
		bool _syncDefer;
		void SyncItems()
		{
			if (_syncDefer)
				return;
				
			UpdateManager.AddDeferredAction( SyncDeferAction );
			_syncDefer = true;
		}
		
		void SyncDeferAction()
		{
			_syncDefer = false;
			
			for (int i=0; i < _sourceItems.Count; ++i)
			{	
				var si = _sourceItems[i];
				si.Accept = Accept( si.Value, i, _sourceItems.Count );
			}

			//remove all undesired items
			for (int i=_outputItems.Count-1; i >=0; --i)
			{
				var oi = _outputItems[i];
				if (!oi.Desired)
				{
					_outputItems.RemoveAt(i);
					TriggerRemoveAt(i);
				}
			}
			
			//add missing ones
			int outAt = 0;
			for (int i=0; i < _sourceItems.Count; ++i )
			{
				if (!_sourceItems[i].Desired)
					continue;
					
				while (outAt < _outputItems.Count && _outputItems[outAt].Index < i)
					outAt++;
					
				if (outAt < _outputItems.Count && _outputItems[outAt].Index == i)
					continue;
					
				_outputItems.Insert(outAt, _sourceItems[i]);
				TriggerInsertAt(outAt, _sourceItems[i].Value);
				outAt++;
			}
		}
		
		protected abstract bool Accept( object value, int index, int count );
		
		void ClearSource()
		{
			for (int i=0; i < _sourceItems.Count; ++i)
				_sourceItems[i].Index = -1;
			_sourceItems.Clear();
		}
		
		void IObserver.OnClear()
		{
			ClearSource();
			SyncItems();
		}
		
		void IObserver.OnNewAll(IArray values)
		{
			ClearSource();
			for (int i=0; i < values.Length; ++i)
				_sourceItems.Add( new SourceItem{ Index = i, Value = values[i] } );
			SyncItems();
		}
		
		void IObserver.OnNewAt(int index, object newValue)
		{	
			_sourceItems[index].Index = -1;
			_sourceItems.RemoveAt(index);
			_sourceItems.Insert(index, new SourceItem { Index = index, Value = newValue } );
			SyncItems();
		}
		
		void IObserver.OnSet(object newValue)
		{
			ClearSource();
			_sourceItems.Add( new SourceItem{ Index = 0, Value = newValue } );
			SyncItems();
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			_sourceItems.Add( new SourceItem { Index = _sourceItems.Count, Value = addedValue } );
			SyncItems();
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			for (int i=index+1; i < _sourceItems.Count; ++i)
				_sourceItems[i].Index = i - 1;
			_sourceItems[index].Index = -1;
			_sourceItems.RemoveAt(index);
			SyncItems();
		}
		
		void IObserver.OnInsertAt(int index, object value)
		{
			for (int i=index; i < _sourceItems.Count; ++i)
				_sourceItems[i].Index = i + 1;
			_sourceItems.Insert(index, new SourceItem { Index = index, Value = value } );
			SyncItems();
		}
		
		void IObserver.OnFailed(string message)
		{
			ClearSource();
			SyncItems();
			TriggerFail(message);
		}
	}

}