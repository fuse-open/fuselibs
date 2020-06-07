using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Base class for UX functions that accept a variable number of arguments.

		Derived classes must override exaclty one of either `OnNewPartialArguments` or `OnNewArguments`.
	*/
	public abstract class VarArgFunction: Expression
	{
		List<Expression> _args = new List<Expression>();
		public IList<Expression> Arguments { get { return _args; } }

		public VarArgFunction() { }

		/** Can be called by `ToString` with a function name to do standard formatting of the arguments */
		protected string FormatString(string funcName)
		{
			var q = funcName + "(";
			for (int i=0; i < Arguments.Count; ++i)
			{
				if (i > 0)
					q += ",";
				q += Arguments[i].ToString();
			}
			q += ")";
			return q;
		}

		protected abstract class Subscription: ExpressionSubscriber
		{
			VarArgFunction _func;
			IContext _context;

			/** @deprecated Use constructor without context and call Init(context) instead 2017-12-15 */
			[Obsolete]
			protected Subscription(VarArgFunction func, IContext context)
				: base( func.Arguments.ToArray(), Flags.AllOptional )
			{
				_func = func;
				_context = context;
			}

			/** Be sure to call "Init" after done initializing */
			protected Subscription(VarArgFunction func)
				: base( func.Arguments.ToArray(), Flags.AllOptional )
			{
				_func = func;
			}

			//TODO: deprecate
			/** @deprecated Use Init(context) instead 2017-12-15 */
			[Obsolete]
			protected void Init()
			{
				base.Init(_context);
			}

			//Not abstract for compatibility reasons, but should be
			internal override void OnClearData()
			{
				ClearData();
			}

			protected virtual void ClearData()
			{
				//default implementation deprecated 2017-12-15
				Fuse.Diagnostics.UserError( "VarArgFunction.Subscription.ClearData() should be implemented", this );
			}

			protected override sealed void OnArguments(Expression.Argument[] args)
			{
				var all = true;
				for (var i = 0; i < args.Length; i++)
				{
					if (!args[i].HasValue)
					{
						all = false;
						break;
					}
				}

				OnNewPartialArguments(args);
				if (all)
					OnNewArguments(args);
			}

			public override void Dispose()
			{
				base.Dispose();
				_func = null;
				_context = null;
			}

			protected virtual void OnNewPartialArguments(Argument[] args) { }
			protected virtual void OnNewArguments(Argument[] args) { }
		}

	}

	/** For VarArg functions that do not need a custom subscription and can work directly with the
		values of the arguments.
	*/
	public abstract class SimpleVarArgFunction : VarArgFunction
	{
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var ss = new SimpleSubscription(this, listener);
			ss.Init(context);
			return ss;
		}

		/** Called when arguments should be checked for a condition that might yield a new value to the listener.

			This function is called immediately upon subscription, and when any of the arguments change.

			Override in subclass to handle partially complete arguments. If the function are not
			interested in the arguments before they are all ready, override `OnNewArguments` instead.

			@param args An array of the arguments to the functoin and their status.
			@param listener The listener which should receive any new data yielded from the function.
		*/
		protected virtual void OnNewPartialArguments(Argument[] args, IListener listener)
		{
			// Do nothing by default
		}

		/** Called when all the arguments are ready and have new values.

			If the function has zero arguments, this function is called immediately upon subscription.

			Override in subclass to handle complete argument lists. If the function is interested in
			partially ready argument lists, override `OnNewPartialArguments` instead.

			@param args An array of the arguments to the functoin and their status. The `HasValue` flag is always true for all arguments in this callback.
			@param listener The listener which should receive any new data yielded from the function.
		*/
		protected virtual void OnNewArguments(Argument[] args, IListener listener)
		{
			// Do nothing by defalt
		}

		sealed class SimpleSubscription: Subscription
		{
			IListener _listener;
			SimpleVarArgFunction _func;

			public SimpleSubscription(SimpleVarArgFunction func, IListener listener)
				: base(func)
			{
				_func = func;
				_listener = listener;
			}

			protected override void OnNewPartialArguments(Argument[] args)
			{
				_func.OnNewPartialArguments(args, _listener);
			}

			protected override void OnNewArguments(Argument[] args)
			{
				_func.OnNewArguments(args, _listener);
			}

			public override void Dispose()
			{
				_listener = null;
				_func = null;
				base.Dispose();
			}
		}

	}
	public class NamedFunctionCall: SimpleVarArgFunction
	{
		public string Name { get; private set; }
		[UXConstructor]
		public NamedFunctionCall([UXParameter("Name")] string name)
		{
			Name = name;
		}
	}
}
