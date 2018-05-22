using Uno;
using Uno.Collections;

namespace Fuse
{
	/** Represents a name-value pair, as denoted by `name: value` in UX expressions.
		
		Implements `IObject`, which means the `NameValuePair` can be viewed as an object
		with a single property.

		Implements `IArray`, which means the `NameValuePair` can be viewed as an array
		with a single element.

		An `IArray` containing some `NameValuePairs` can be converted to an `IObject`
		implementation containing all those properties using the `ObjectFromArray` method.
	*/
	public sealed class NameValuePair : IObject
	{
		public string Name { get; private set; }
		public object Value { get; private set; }
		public NameValuePair(string name, object value)
		{
			Name = name;
			Value = value;
		}

		public override string ToString()
		{
			return "(" + Name + ": " + Value + ")";
		}

		string[] IObject.Keys { get { return new [] { Name }; } }
		bool IObject.ContainsKey(string key) { return Name == key; } 
		object IObject.this[string key] 
		{
			get
			{
				if (key != Name) throw new ArgumentException("Object (NameValuePair) does not contain the given key");
				return Value;
			}
		}

		/** Creates an IObject implementation from an `IArray` of `NameValuePair`.
			If the items are not `NameValuePair` instances, or there is a duplicate, they will be 
			added with an indexed key value (unspecified) -- this is to pass through information
			to later error detection rather than silently discarding it.
			
			TODO: we probably don't need this function after  this issue is done:
			https://github.com/fuse-open/fuselibs/issues/233
		*/
		public static IObject ObjectFromArray(IArray list)
		{
			var dict = new Dictionary<string, object>();
			for (var i = 0; i < list.Length; i++)
			{
				var nvp = list[i] as NameValuePair;
				if (nvp != null && !dict.ContainsKey(nvp.Name))
					dict.Add(nvp.Name, nvp.Value);
				else
					dict.Add("" + i, list[i]);
			}
			return new Json.Object(dict);
		}
	}
}