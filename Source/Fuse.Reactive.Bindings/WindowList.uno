using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

namespace Fuse.Reactive
{
	/** A base class for items used in the WindowList */
	abstract class WindowListItem : ValueObserver
	{
		/* Need an abstraction since the owner is a generic type. The relationship between watching and WindowListItem is kept hidden so that users of WindowList don't need to know how the listening is done, and to avoid needing a high-level object (like `Instantiator`) being stored by the users. */
		public interface IDataWatcher
		{
			void OnCurrentDataChanged( WindowListItem item, object oldData );
		}
		IDataWatcher _owner;
		
		object _curData;
		object _data;
		//the raw data associated with the item
		public object Data
		{
			get { return _data; }
			set
			{
				var oldData = CurrentData;
				Unsubscribe();
				
				_data = value;
				_curData = _data;
				var obs = _data as IObservable;
				if (obs != null)
				{
					SubscribeNoPush(obs);
					_curData = Value;
				}

				if (_owner != null)
					_owner.OnCurrentDataChanged( this, oldData );
			}
		}
		
		protected override void PushData(object newValue)
		{
			var oldData = CurrentData;
			_curData = newValue;
			if (_owner != null)
				_owner.OnCurrentDataChanged( this, oldData );
		}
		protected override void LostData() 
		{ 
			PushData(null); 
		}
		
		//logical identifier used for matching, null if none
		public object Id { get; private set; }
		
		protected WindowListItem() { }
		
		static public T Create<T>( IDataWatcher owner, object id, object data ) where T : WindowListItem, new()
		{
			var lwi = new T();
			lwi.Data = data; //set before owner so it doesn't generate callback now
			lwi.Id = id;
			lwi._owner = owner;
			return lwi;
		}
		
		public object CurrentData
		{
			get
			{
				return _curData;
			}
		}
		
		public override void Dispose()
		{
			_curData = null;
			_data = null;
			_owner = null;
			Id = null;
			base.Dispose();
		}
	}
	
	/**
		Maintains a window over an input list.
		
		This is not meant to be a stand-alone class, but was created to help in separating out concerns in the derived classes.
		
		This is abstract as it doesn't know directly about the source list or the type of the stored items (or windowed items).
	*/
	abstract class WindowList<T> where T : class
	{
		int _offset = 0;
		internal int Offset
		{
			get { return _offset; }
			set
			{
				if (_offset == value)
					return;
					
				if (value < 0)
				{
					Fuse.Diagnostics.UserError( "Offset cannot be less than 0", this );
					value = 0;
				}
				
				//slide the window in both directions as necessary
				var dataCount = GetDataCount();
				while (_offset < value)
				{
					if (_offset < dataCount)
						RemovedDataAt(_offset);
						
					_offset++;
					var end = _offset + Limit - 1;
					if (HasLimit && end < dataCount)
						InsertedDataAt(end);
				}
				
				while (_offset > value)
				{
					var end = _offset + Limit - 1;
					if (HasLimit && end < dataCount)
						RemovedDataAt(_offset + Limit - 1);
						
					_offset--;
					if (_offset < dataCount)
						InsertedDataAt(_offset);
				}
			}
		}
		
		int _limit = 0;
		bool _hasLimit;
		internal int Limit
		{
			get { return _limit; }
			set
			{
				if (_hasLimit && _limit == value)
					return;
					
				if (value < 0)
				{
					Fuse.Diagnostics.UserError( "Limit cannot be less than 0", this );
					value = 0;
				}
				
				_hasLimit = true;
				_limit = value;
				TrimAndPad();
			}
		}
		
		internal bool HasLimit { get { return _hasLimit; } }
		
		protected int CalcOffsetLimitCountOf( int length )
		{
			var q = Math.Max( 0, length - Offset );
			return HasLimit ? Math.Min( Limit, q ) : q;
		}
		
		/* The list of items which are within the range of (Offset, Limit) */
		ObjectList<T> _windowItems = new ObjectList<T>();
		
		public int WindowItemCount { get { return _windowItems.Count; } }
		public T GetWindowItem( int i ) { return _windowItems[i]; }
		
		public int GetWindowItemIndex( T item )
		{
			for (int i=0; i < _windowItems.Count; ++i)
			{
				if (item == _windowItems[i])
					return i;
			}
			return -1;
		}
		
		string _errorMessage;
		/* Error tracking is provided at this level to simplify the clearing */
		protected string ErrorMessage
		{
			get { return _errorMessage; }
			private set
			{
				if (_errorMessage == value)
					return;
				_errorMessage = value;
				OnErrorMessageChanged(_errorMessage);
			}
		}
		void ClearError() { ErrorMessage = null; }
		protected void SetError(string msg) { ErrorMessage = msg ?? "error"; }
		
		protected void RemovedDataAt(int dataIndex)
		{
			var windowIndex = DataToWindowIndex(dataIndex);
			if ( windowIndex >= 0 && windowIndex < WindowItemCount)
			{
				OnRemovedWindowItem(GetWindowItem(windowIndex));
				_windowItems.RemoveAt(windowIndex);
			}
			ClearError();
		}
		
		/** Removes all items from _windowItems */
		protected void RemoveAll()
		{
			for (int i=0; i < WindowItemCount; ++i)
			{
				var wi = GetWindowItem(i);
				OnRemovedWindowItem(wi);
			}
			_windowItems.Clear();

			ClearError();
		}
		
		protected int DataToWindowIndex(int dataIndex)
		{
			return dataIndex - Offset;
		}
		
		// Used to test that Instance internals behaves correctly
		// in light of https://github.com/fuse-open/fuselibs/issues/227
		extern (UNO_TEST) internal static int InsertCount;
		
		/** Indicates a new data item has been inserted at `dataIndex`. This should be called sequentially from the lowest items as new items as added -- the resulting window items must be built in that order. */
		protected void InsertedDataAt(int dataIndex)
		{
			if defined (UNO_TEST) InsertCount++; 

			if (dataIndex < Offset ||
				(HasLimit && (dataIndex - Offset) >= Limit))
				return;
				
			var windowIndex = DataToWindowIndex(dataIndex);
			if ( windowIndex > _windowItems.Count || windowIndex < 0)
			{
				Fuse.Diagnostics.InternalError( "Item insertion order invalid", this);
				return;	
			}

			InsertWindowItem( windowIndex, dataIndex );
		}
		
		protected void InsertWindowItem( int windowIndex, int dataIndex )
		{
			var wi = CreateWindowItem( dataIndex );
			_windowItems.Insert( windowIndex, wi );
			OnAddedWindowItem( windowIndex, wi );
		}

		/**
			Checks the length of data against the Offset+Limit. If it is too short the list of window items will be increased, if too long it will be reduced.
		*/
		protected void TrimAndPad()
		{
			//trim excess
			if (HasLimit)
			{
				for (int i=WindowItemCount - Limit; i > 0; --i)
					RemovedDataAt(Offset + WindowItemCount - 1);
			}
				
			//add new
			var dataCount = GetDataCount();
			var add = HasLimit ?
				Math.Min(Limit - WindowItemCount, dataCount - (Offset + WindowItemCount)) : 
				(dataCount - (Offset + WindowItemCount));
			for (int i=0; i < add; ++i)
				InsertedDataAt(Offset + WindowItemCount);
				
			//in a good state again (in case nothing changed above)
			ClearError();
		}
		
		protected abstract T CreateWindowItem( int dataIndex );
		public abstract int GetDataCount();
		protected abstract void OnRemovedWindowItem(T wi);
		protected abstract void OnAddedWindowItem(int windowIndex, T wi);
		protected abstract void OnErrorMessageChanged(string _errorMessage);
	}
}
