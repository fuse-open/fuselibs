using Uno;
using Uno.Collections;
using Uno.Data.Json;
using Fuse;
using Fuse.Reactive;
using Fuse.Controls;

namespace Fuse.Views
{

	delegate void Callback(Dictionary<string,string> args);

	class DataContext
	{
		ObjectDataContext _jsonContext = new ObjectDataContext();
		ObjectDataContext _callbackContext = new ObjectDataContext();

		Visual _target;

		public DataContext(Visual target)
		{
			_target = target;
			_target.Children.Add(_jsonContext);
			_target.Children.Add(_callbackContext);
		}

		public void SetDataJson(string json)
		{
			var data = Deserializer.Parse(json) as IObject;
			_jsonContext.Data = data;
		}

		Dictionary<string,ObjectDataContext> _stringData = new Dictionary<string,ObjectDataContext>();

		public void SetDataString(string key, string value)
		{
			ObjectDataContext stringContext;
			if (!_stringData.TryGetValue(key, out stringContext))
			{
				stringContext = new ObjectDataContext();
				_target.Children.Add(stringContext);
				_stringData.Add(key, stringContext);
			}
			stringContext.Data = new ImmutableObject(new [] { key }, new [] { (object)value });
		}

		Dictionary<string,object> _callbacks = new Dictionary<string,object>();

		public void SetCallback(string key, IEventHandler eventHandler)
		{
			if (!_callbacks.ContainsKey(key))
				_callbacks.Add(key, eventHandler);

			var keys = _callbacks.Keys.ToArray();
			var values = _callbacks.Values.ToArray();
			var obj = new ImmutableObject(keys, values);
			_callbackContext.Data = obj;
		}
	}

	class ObjectDataContext : Node, Node.ISiblingDataProvider
	{
		IObject _data;
		public IObject Data
		{
			get { return _data; }
			set
			{
				var oldData = _data;
				_data = value;
				if (Parent != null)
					Parent.BroadcastDataChange(oldData, _data);
			}
		}

		ContextDataResult ISiblingDataProvider.TryGetDataProvider( DataType type, out object provider )
		{	
			provider = type == DataType.Key ? Data : null;
			return ContextDataResult.Continue;
		}
	}

	class ImmutableObject : IObject
	{
		readonly string[] _keys;
		readonly object[] _values;

		public ImmutableObject(string[] keys, object[] values)
		{
			if (keys.Length != values.Length)
				throw new Exception();
			_keys = keys;
			_values = values;
		}

		public string[] Keys
		{
			get { return _keys; }
		}

		public bool ContainsKey(string key)
		{
			for (int i = 0; i < _keys.Length; i++)
			{
				if (_keys[i] == key)
					return true;
			}
			return false;
		}

		public object this[string key]
		{
			get
			{
				for (int i = 0; i < _keys.Length; i++)
				{
					if (_keys[i] == key)
						return _values[i];
				}
				return null;
			}
		}
	}
}