using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Text;

namespace Fuse.Reactive
{
	/** Creates an `IObject` from an arbitrary number of NameValuePairs. 
	
		The returned object also implements `IArray` with the original ordering of the NameValuePairs.

		In UX expressions, objects are denoted as lists of NameValuePair: `{name1: value1, name2: value2}`.

		A single `NameValuePair` also implements `IObject` (but doesn't need this `Object` operator).
	*/
	public class Object: SimpleVarArgFunction
	{
		protected override void OnNewArguments(Argument[] args, IListener listener)
		{
			listener.OnNewData(this, new ArrayObject(args));
		}
	}

	class ArrayObject: Array, IObject
	{
		readonly Dictionary<string, object> _dict = new Dictionary<string, object>();

		public ArrayObject(Expression.Argument[] args): base(args)
		{
			for (var i = 0; i < args.Length; i++)
			{
				var nvp = args[i].Value as Fuse.NameValuePair;
				if (nvp != null)
					_dict.Add(nvp.Name, nvp.Value);
			}
		}

		bool IObject.ContainsKey(string key)
		{
			return _dict.ContainsKey(key);
		}

		object IObject.this[string key]
		{
			get { return _dict[key]; }
		}

		string[] IObject.Keys
		{
			get 
			{
				return _dict.Keys.ToArray();
			}
		}
	}
}