using Uno;
using Uno.Collections;

namespace Uno.Collections
{
	class ConcurrentCollection<T> : ICollection<T>
	{
		List<T> _back = new List<T>();
		
		struct ModItem
		{
			public T Item;
			public bool Add;
		}
		
		List<ModItem> _mod;
		List<ModItem> Mod
		{
			get
			{
				if (_mod == null)
					_mod = new List<ModItem>();
				return _mod;
			}
		}
		
		bool _defer;
	
		public void DeferChanges()
		{
			_defer = true;
		}
		
		public void EndDefer()
		{
			_defer = false;
			
			if (_mod != null)
			{
				for (int i=0; i < _mod.Count; ++i)
				{
					var a = _mod[i];
					if (a.Add)
						_back.Add(a.Item);
					else
						_back.Remove(a.Item);
				}
				
				_mod.Clear();
			}
		}
		
        public void Clear()
        {
			_back.Clear();
			if (_mod != null)
				_mod.Clear();
        }
        
        public void Add(T item)
        {
			if (_defer)
			{
				//prefer to erase pending remove first
				for (int i=0; i < Mod.Count; ++i)
				{
					if (object.Equals(Mod[i].Item, item) && !Mod[i].Add)
					{
						Mod.RemoveAt(i);
						return;
					}
				}
				
				Mod.Add( new ModItem{ Item = item, Add = true } );
			}
			else
				_back.Add(item);
        }
        
        public bool Remove(T item)
        {
			if (_defer)
			{
				//prefer to erase pending add first
				for (int i=0; i < Mod.Count; ++i)
				{
					if (object.Equals(Mod[i].Item, item) && Mod[i].Add)
					{
						Mod.RemoveAt(i);
						return true;
					}
				}
					
				if (_back.Contains(item))
				{
					Mod.Add( new ModItem{ Item = item, Add = false } );
					return true;
				}
				
				return false;
			}
			
			return _back.Remove(item);
        }
        
        public bool Contains(T item)
        {
			if (_mod != null)
			{
				for (int i=0; i < _mod.Count; ++i)
				{
					var m = _mod[i];
					if (!object.Equals(m.Item,item))
						continue;
						
					return m.Add;
				}
			}
			
			return _back.Contains(item);
        }
        
        public int Count 
        { 
			get 
			{ 
				var c = _back.Count;
				
				if (_mod != null)
				{
					for (int i=0; i < _mod.Count; ++i)
					{
						if (_mod[i].Add)
							c++;
						else
							c--;
					}
				}
				
				return c; 
			}
		}
		
		public T this [int index]
		{
			get
			{
				return _back[index];
			}
		}
		
		public IEnumerator<T> GetEnumerator()
		{
			return _back.GetEnumerator();
		}
		
		class DeferLockImpl : IDisposable
		{
			ConcurrentCollection<T> _collection;
			public DeferLockImpl(ConcurrentCollection<T> c)
			{
				_collection = c;
			}
			
			public void Dispose()
			{
				_collection.EndDefer();
			}
		}

		DeferLockImpl _lockImpl;
		//allows simple deferring with a `using` statement
		public IDisposable DeferLock()
		{
			if (_lockImpl == null)
				_lockImpl = new DeferLockImpl(this);
			DeferChanges();
			return _lockImpl;
		}
	}
}