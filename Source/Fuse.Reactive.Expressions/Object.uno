using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Text;

namespace Fuse.Reactive
{
	/** Creates an `IObject` from an arbitrary number of NameValuePairs.

		In UX expressions, objects are denoted as lists of NameValuePair: `{name1: value1, name2: value2}`.

		A single `NameValuePair` also implements `IObject` (but doesn't need this `Object` operator).
	*/
	public class Object: SimpleVarArgFunction
	{
		protected override void OnNewArguments(Argument[] args, IListener listener)
		{
			var dict = new Dictionary<string, object>();
			for (var i = 0; i < args.Length; i++)
			{
				var nvp = args[i].Value as Fuse.NameValuePair;
				if (nvp != null)
					dict.Add(nvp.Name, nvp.Value);
			}
			listener.OnNewData(this, new Json.Object(dict));
		}
	}
}