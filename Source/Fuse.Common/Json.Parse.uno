using Uno;
using Uno.Collections;
using Uno.Data.Json;

namespace Fuse
{
	public static partial class Json
	{
		/** Parses the given JSON string into a heirarchy of appropriate Uno objects.

			The returned object can be a single value, or a tree composed of `IObject`, `IArray`, `double`, `string` and `bool` objects.
		*/
		public static object Parse(string json)
		{
			return Convert(JsonReader.Parse(json));
		}

		/** Parses a list of JSON strings into a list of objects, using `Parse(string)`. */
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
						var dict = new Dictionary<string, object>();
						for (int i = 0; i < keys.Length; i++)
							dict.Add(keys[i], Convert(r[keys[i]]));
						return new Object(dict);
					}
				case JsonDataType.Array:
					{
						var values = new object[r.Count];
						for (int i = 0; i < values.Length; i++)
							values[i] = Convert(r[i]);
						return new Array(values);
					}
				case JsonDataType.Number: return r.AsNumber();
				case JsonDataType.String: return (string)r;
				case JsonDataType.Boolean: return (bool)r;
			}
			return null;
		}

		internal class Object : IObject
		{
			readonly Dictionary<string, object> _dict;

			public Object(Dictionary<string, object> dict)
			{
				_dict = dict;
			}

			public string[] Keys
			{
				get { return _dict.Keys.ToArray(); }
			}

			public bool ContainsKey(string key)
			{
				return _dict.ContainsKey(key);
			}

			public object this[string key]
			{
				get
				{
					return _dict[key];
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