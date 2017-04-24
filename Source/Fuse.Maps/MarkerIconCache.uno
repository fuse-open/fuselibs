using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Uno;
namespace Fuse.Maps
{
	internal class MarkerIconCache
	{
		Dictionary<string, MarkerSource> _cache;
		Action _changeHandler;
		
		public MarkerIconCache(Action changeHandler)
		{
			_cache = new Dictionary<string, MarkerSource>();
			_changeHandler = changeHandler;
		}
		
		public string Get(FileSource src)
		{
			if(src==null) return null;
			var key = MakeKey(src);
			if(_cache.ContainsKey(key))
				return _cache[key].Path;
			var markerSource = new MarkerSource(key, src, this);
			_cache[key] = markerSource;
			return markerSource.Path;
		}
		
		internal void OnChanged()
		{
			if(_changeHandler!=null)
				_changeHandler();
		}
		
		internal static string MakeKey(FileSource src)
		{
			return "marker_"+src.Name.Replace('/', '_');
		}
	}
	
	internal class MarkerSource
	{
		readonly FileSource _src;
		readonly MarkerIconCache _cache;
		bool dirty;
		string _path;
		
		public string Path { 
			get {
				if(!dirty) return _path;
				var image = Fuse.ImageTools.ImageTools.ImageFromByteArray(_src.ReadAllBytes());
				image.Rename(Name, true);
				dirty = false;
				return _path = image.Path;
			} 
		}
		
		public string Name {
			get; private set;
		}
		
		public MarkerSource(string name, FileSource input, MarkerIconCache cache)
		{
			dirty = true;
			_cache = cache;
			_src = input;
			_src.DataChanged += OnDataChanged;
			Name = name;
		}
		
		~MarkerSource()
		{
			_src.DataChanged -= OnDataChanged;
		}
		
		void OnDataChanged(object sender, EventArgs args)
		{
			dirty = true;
			_cache.OnChanged();
		}
	}
}
