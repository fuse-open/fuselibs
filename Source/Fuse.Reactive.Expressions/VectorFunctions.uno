using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Text;

namespace Fuse.Reactive
{
	/** Creates an `IArray` from an arbitrary number of arguments.
		An `IArray` can be automatically marshalled to any Uno vector type (e.g. `float4`)
	*/
	public class Vector: SimpleVarArgFunction
	{
		protected override void OnNewArguments(Argument[] args, IListener listener)
		{
			listener.OnNewData(this, new Array(args));
		}
	}

	class Array: IArray
	{
		object[] _items;
		public Array(VarArgFunction.Argument[] args)
		{
			_items = new object[args.Length];
			for (var i = 0; i < args.Length; i++)
				_items[i] = args[i].Value;
		}
		object IArray.this[int index] { get { return _items[index]; } }
		int IArray.Length { get { return _items.Length; } }

		public override string ToString()
		{
			var sb = new StringBuilder();
			sb.Append("(");
			for (var i = 0; i < _items.Length; i++)
			{
				if (i > 0) sb.Append(", ");
				sb.Append(_items[i].ToString());
			}
			sb.Append(")");
			return sb.ToString();
		}

		public override string ToString()
		{
			return FormatString("");
		}
	}
}