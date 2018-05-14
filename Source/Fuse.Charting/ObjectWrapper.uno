using Uno;

using Fuse.Reactive;

namespace Fuse.Charting
{
	class ObjectWrapper<T> : IObject where T : class
	{
		string _name;
		T _data;

		public T Data { get { return _data; } }

		public ObjectWrapper( string name, T data )
		{
			_name = name;
			_data = data;
		}
		
		public bool ContainsKey( string key )
		{
			return key == _name && _data != null;
		}
		
		public object this[string key]
		{
			get
			{
				if (key == _name)
					return _data;
				return null;
			}
		}
		
		public string[] Keys
		{
			get
			{
				return new[]{ _name };
			}
		}
	}
}
