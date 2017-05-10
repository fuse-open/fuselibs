using Uno;
using Uno.Collections;
using Uno.Diagnostics;

namespace Fuse.Resources
{
	static class DisposalManager
	{
		static List<IMemoryResource> _items = new List<IMemoryResource>();

		static internal int TestMemoryResourceCount { get { return _items.Count; } }

		/**
			Adds an item to the disposal list.
			
			When the item should be disposed it's `SoftDispose` function should be called. During cleanup it's possible that this function is called even after the obejct has been cleaned up (if something else cleans it during it's own cleanup). For that reason `SoftDispose` must be safe to call multiple times.
		*/
		static public void Add( IMemoryResource item ) 
		{
			_items.Add( item );
			VerifyAttach();
		}
		
		/**
			Removes an item from the disposal list.
			
			This is safe to call during a call to `SoftDispose` from the `DisposalManager`.
		*/
		static public void Remove( IMemoryResource item )
		{
			if (_items.Remove( item ))
				VerifyAttach();
		}
		
		static bool _actionAdded;
		
		static void VerifyAttach()
		{
			bool on = _items.Count > 0;
			
			if( on == _actionAdded )
				return;
				
			if( on )
				UpdateManager.AddAction( Update );
			else
				UpdateManager.RemoveAction( Update );
				
			_actionAdded = on;
		}
		
		static int _disposeAt;
		
		static void Update()
		{
			//a fixed amount per update to avoid wasteful scanning
			for (int i=0; i < 2; ++i)
			{
				if (_items.Count == 0)
					return;
				
				_disposeAt++;
				if (_disposeAt >= _items.Count)
					_disposeAt = 0;
				
				var item = _items[_disposeAt];
				if( !item.MemoryPolicy.ShouldSoftDispose(DisposalRequest.Regular,item) )
					continue;
						
				_items.RemoveAt(_disposeAt);
				item.SoftDispose();
			}
		}
		
		static public void Clean(DisposalRequest dr)
		{
			for( int i = _items.Count - 1; i >= 0; --i )
			{
				//a rare situation where one SoftDispose removes multiple items
				if (i >= _items.Count)
					continue;
					
				var item = _items[i];
				if (!item.MemoryPolicy.ShouldSoftDispose(dr,item))
					continue;
					
				_items.RemoveAt(i);
				item.SoftDispose();
			}
			
			if (dr == DisposalRequest.Background || dr == DisposalRequest.LowMemory)
			{
				for (int i = 0; i < _softDisposables.Count; ++i)
					_softDisposables[i].SoftDispose();
			}
		}
		
		static List<ISoftDisposable> _softDisposables = new List<ISoftDisposable>();
		//NOTE (from mortoray): I'm not sure about these. I'd prefer items implement IMemoryResource
		//and use the normal disposal. That takes care of any conditions, like on background, or lowmemory
		static public void Add( ISoftDisposable item ) 
		{
			_softDisposables.Add( item );
		}
		
		static public void Remove( ISoftDisposable item )
		{
			_softDisposables.Remove( item );
		}
	}
}
