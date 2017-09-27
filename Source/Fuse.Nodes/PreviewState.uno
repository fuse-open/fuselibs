using Uno.Collections;

namespace Fuse
{
	/** 
		State management in Preview for reloading/reifying. This has not use other than when running in preview.
		
		TODO: Reduce as much as possible if not defined(DESIGNMODE)
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
			_current = data;
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
		Dictionary<string, object> _data = new Dictionary<string, object>();
		
		public void Set( string key, object data )
		{
			_data[key] = data;
		}
		
		public object Get( string key )
		{
			object v;
			if (_data.TryGetValue( key, out v) )
				return v;
			return null;
		}
	}
	

	interface IPreviewStateSaver
	{
		void Save( PreviewStateData data );
	}
	
	interface IStateSource
	{
		
	}
}
