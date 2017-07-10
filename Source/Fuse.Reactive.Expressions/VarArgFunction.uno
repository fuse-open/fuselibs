using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Base class for UX functions that accept a variable number of arguments.

		Derived classes must override exaclty one of either `OnNewPartialArguments` or `OnNewArguments`.
	*/
	public abstract class VarArgFunction: Expression
	{
		/** Holds information about an argument to a `VarArgFunction`. */
		public class Argument 
		{
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

		List<Expression> _args = new List<Expression>();
		public IList<Expression> Arguments { get { return _args; } }

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new Subscription(this, context, listener);
		}

		/** Called when at least some arguments are ready and have new values. 
			
			Override in subclass to handle partially complete arguments. If the function are not
			interested in the arguments before they are all ready, override `OnNewArguments` instead.

			@param args An array of the arguments to the functoin and their status.
			@param listener The listener which should receive any new data yielded from the function.
		*/
		protected virtual void OnNewPartialArguments(Argument[] args, IListener listener)
		{
			for (var i = 0; i < args.Length; i++)
				if (!args[i].HasValue) return;

			OnNewArguments(args, listener);
		}

		/** Called when all the arguments are ready and have new values.

			Override in subclass to handle complete argument lists. If the function is interested in
			partially ready argument lists, override `OnNewPartialArguments` instead.

			@param args An array of the arguments to the functoin and their status. The `HasValue` flag is always true for all arguments in this callback.
			@param listener The listener which should receive any new data yielded from the function.
		*/
		protected virtual void OnNewArguments(Argument[] args, IListener listener)
		{
			// Do nothing by defalt
		}

		public class Subscription: InnerListener
		{
			IListener _listener;
			VarArgFunction _func;
			Argument[] _arguments;

			public Subscription(VarArgFunction func, IContext context, IListener listener)
			{
				_func = func;
				_listener = listener;

				_arguments = new Argument[func.Arguments.Count];

				for (var i = 0; i < func.Arguments.Count; i++)
					_arguments[i] = new Argument();

				// First create argument objects, *then* subscribe. Otherwise we
				// get callbacks before we're fully initialized.
				for (var i = 0; i < func.Arguments.Count; i++)
					_arguments[i].Subscription = func.Arguments[i].Subscribe(context, this);
			}

			protected override void OnNewData(IExpression source, object value)
			{
				for (var i = 0; i < _func.Arguments.Count; i++)
					if (_func.Arguments[i] == source)
					{
						_arguments[i].Value = value;
						_arguments[i].HasValue = true;
					}

				PushData();
			}

			internal void PushData()
			{
				_func.OnNewPartialArguments(_arguments, _listener);
			}

			public override void Dispose()
			{
				base.Dispose();

				for (var i = 0; i < _arguments.Length; i++)
					_arguments[i].Dispose();
				
				_listener = null;
				_func = null;
				_arguments = null;
			}
		}

	}
}