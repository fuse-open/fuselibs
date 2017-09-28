using Uno.Collections;

namespace Fuse
{
	/** 
		State management in Preview for reloading/reifying. This has not use other than when running in preview.
	*/
	class PreviewState
	{
		public PreviewStateData Save()
		{
			var psd = new PreviewStateData();
			for (int i=0; i < _savers.Count; ++i)
				_savers[i].Save( psd );
			return psd;
		}
		
		public void SetState(PreviewStateData data)
		{
			if (data != null && data.Consumed)
			{
				Fuse.Diagnostics.InternalError( "Attempting to restore an already consumed state", this );
				_current = null;
				return;
			}
			
			_current = data;
			if (_current != null)
				_current.Consumed = true;
		}
		
		PreviewStateData _current;
		public PreviewStateData Current
		{
			get { return _current; }
		}
		
		List<IPreviewStateSaver> _savers = new List<IPreviewStateSaver>();
		
		public void AddSaver( IPreviewStateSaver saver )
		{
			_savers.Add( saver );
		}
		
		public void RemoveSaver( IPreviewStateSaver saver )
		{
			_savers.Remove( saver );
		}
		
		/** Finds the appropriate PreviewState for a given node. May return null */
		static public PreviewState Find( Node n )
		{
			while (n != null)
			{
				var rv = n as RootViewport; //the only thing that provides a PreviewState
				if (rv != null)
					return rv.PreviewState;
				n = n.Parent;
			}
			return null;
		}
	}
	
	class PreviewStateData
	{
		/** Has this state data already been consumed/restored? */
		public bool Consumed;
		
		class Entry
		{
			public object Data;
			public bool Consumed;
		}
		
		Dictionary<string, Entry> _data = new Dictionary<string, Entry>();
		
		/** Sets the data for a key. Note that a null value will not be considered a value, and will erase an existing value. */
		public void Set( string key, object data )
		{
			_data[key] = new Entry{ Data = data, Consumed = false };
		}
		
		/** Returns true if data has been stored for this key. Note that a null value is not considered to be actual data. */
		public bool Has( string key )
		{
			Entry v;
			if (_data.TryGetValue( key, out v) )
				return v.Data != null;
			return false;
		}
		
		/** Obtains the data just once, returning null on subsequent requests. This allows for rooting to only pick up the state data the first time, not if rerooted without it being saved again. */
		public object Consume( string key )
		{
			Entry v;
			if (_data.TryGetValue( key, out v ) && !v.Consumed)
			{
				v.Consumed = true;
				return v.Data;
			}
			return null;
		}
	}

	interface IPreviewStateSaver
	{
		void Save( PreviewStateData data );
	}
}
