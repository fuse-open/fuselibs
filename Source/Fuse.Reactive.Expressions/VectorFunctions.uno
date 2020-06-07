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

		public override string ToString()
		{
			return FormatString("");
		}
	}

	class Array: IArray
	{
		object[] _items;
		public Array(Expression.Argument[] args)
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
	}

	/**
		Returns the `Z` value of a `float3` or `float4` value.
	*/
	[UXFunction("z" )]
	public sealed class VectorZ : UnaryOperator
	{
		[UXConstructor]
		public VectorZ([UXParameter("Operand")] Expression operand) :
			base(operand, "z") {}
		protected override bool TryCompute(object operand, out object result)
		{
			result = null;
			var v = float4(0);
			int size;
			if (!Marshal.TryToZeroFloat4(operand, out v, out size) || size < 3)
				return false;

			result = v.Z;
			return true;
		}
	}

	[UXFunction("w" )]
	/**
		Returns the `W` value of a `float4` value.
	*/
	public sealed class VectorW : UnaryOperator
	{
		[UXConstructor]
		public VectorW([UXParameter("Operand")] Expression operand) :
			base(operand, "w") {}
		protected override bool TryCompute(object operand, out object result)
		{
			result = null;
			var v = float4(0);
			int size;
			if (!Marshal.TryToZeroFloat4(operand, out v, out size) || size < 4)
				return false;

			result = v.W;
			return true;
		}
	}

}