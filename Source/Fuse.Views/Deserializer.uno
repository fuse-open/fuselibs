using Uno;
using Uno.Collections;
using Uno.Data.Json;
using Fuse;
using Fuse.Reactive;
using Fuse.Controls;

namespace Fuse.Views
{
	static class Deserializer
	{
		public static object Parse(string json)
		{
			return Convert(JsonReader.Parse(json));
		}

		public static object[] Parse(string[] json)
		{
			var res = new object[json.Length];
			for (int i = 0; i < res.Length; i++)
			{
				res[i] = Parse(json[i]);
			}
			return res;
		}

		static object Convert(JsonReader r)
		{
			switch (r.JsonDataType)
			{
				case JsonDataType.Object:
					{
						var keys = r.Keys;
						var values = new object[keys.Length];
						for (int i = 0; i < keys.Length; i++)
						{
							values[i] = Convert(r[keys[i]]);
						}
						return new Object(keys, values);
					}
				case JsonDataType.Array:
					{
						var values = new object[r.Count];
						for (int i = 0; i < values.Length; i++)
						{
							values[i] = Convert(r[i]);
						}
						return new Array(values);
					}
				case JsonDataType.Number: return r.AsNumber();
				case JsonDataType.String: return (string)r;
				case JsonDataType.Boolean: return (bool)r;
			}
			return null;
		}

		class Object : IObject
		{
			readonly string[] _keys;
			readonly object[] _values;

			public Object(string[] keys, object[] values)
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

		class Array: IArray
		{
			readonly object[] _array;

			public Array(params object[] array)
			{
				_array = array;
			}

			public int Length
			{
				get { return _array.Length; }
			}

			public object this[int index]
			{
				get { return _array[index]; }
			}
		}
	}
}