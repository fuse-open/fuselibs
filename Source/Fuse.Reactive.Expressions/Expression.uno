using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	public abstract class Expression: IExpression, ISourceLocation
	{
		/** See `IExpression.Subscribe` for docs.	*/
		public abstract IDisposable Subscribe(IContext context, IListener listener);
		
		/** Holds information about an argument to an Expression 
			@advanced */
		public class Argument 
		{
			internal IExpression Source;
			internal IDisposable Subscription;

			/** The current value of the argument. If `HasValue` is `false`, `null` is returned. */
			public object Value { get; internal set; }

			/** Whether or not this argument has yielded a value yet. 
				This can only return false if `OnNewPartialArguments` was overridden.
			*/
			public bool HasValue { get; internal set; }
			
			internal void Dispose()
			{
				if (Subscription != null)
				{
					Subscription.Dispose();
					Subscription = null;
				}

				Value = null;
				HasValue = false;
			}
		}
		
		[UXLineNumber]
		/** @hide */
		public int SourceLineNumber { get; set; }
		[UXSourceFileName]
		/** @hide */
		public string SourceFileName { get; set; }
		
		ISourceLocation ISourceLocation.SourceNearest { get { return this; } }
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

