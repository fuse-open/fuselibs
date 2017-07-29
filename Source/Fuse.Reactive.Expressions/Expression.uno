using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	public abstract class Expression: IExpression
	{
		/** See `IExpression.Subscribe` for docs.	*/
		public abstract IDisposable Subscribe(IContext context, IListener listener);
	}

	public abstract class ConstantExpression: Expression
	{
		public abstract object GetValue(IContext context);

		public sealed override IDisposable Subscribe(IContext context, IListener listener)
		{
			listener.OnNewData(this, GetValue(context));
			return null;
		}
	}

	public sealed class Constant: ConstantExpression
	{
		public object Value { get; private set; }
		[UXConstructor]
		public Constant([UXParameter("Value")] object value) { Value = value; }
		public override object GetValue(IContext context) { return Value; }

		public override string ToString()
		{
			return "'" + Value.ToString() + "'";
		}
	}

	public sealed class Data: Expression
	{
		public string Key { get; private set; }
		[UXConstructor]
		public Data([UXParameter("Key")] string key) { Key = key; }

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return context.Subscribe(this, Key, listener);
		}

		public override string ToString()
		{
			return "{" + Key + "}";
		}
	}
}

