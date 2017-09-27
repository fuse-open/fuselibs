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
		//UNO: https://github.com/fusetools/uno/issues/1292  This is meant to be `protected internal`
		/** Holds information about an argument to a `VarArgFunction`. 
			@hide */
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
		
		protected abstract class Subscription: InnerListener
		{
			VarArgFunction _func;
			Argument[] _arguments;
			IContext _context;

			/** Be sure to call "Init" after done initializing */
			protected Subscription(VarArgFunction func, IContext context)
			{
				_func = func;
				_arguments = new Argument[func.Arguments.Count];
				_context = context;

				for (var i = 0; i < func.Arguments.Count; i++)
					_arguments[i] = new Argument();
			}
			
			protected void Init()
			{
				// First create argument objects, *then* subscribe. Otherwise we
				// get callbacks before we're fully initialized.
				for (var i = 0; i < _func.Arguments.Count; i++)
					_arguments[i].Subscription = _func.Arguments[i].Subscribe(_context, this);
					
				// To cover the case where the function has zero arguments, and also when
				// having no arugments ready is a valid case
				PushData();
			}

			protected override void OnNewData(IExpression source, object value)
			{
				for (var i = 0; i < _func.Arguments.Count; i++)
				{
					if (_func.Arguments[i] == source)
					{
						_arguments[i].Value = value;
						_arguments[i].HasValue = true;
					}
				}

				PushData();
			}

			void PushData()
			{
				var all = true;
				for (var i = 0; i < _arguments.Length; i++)
				{
					if (!_arguments[i].HasValue) 
					{
						all = false;
						break;
					}
				}
									
				OnNewPartialArguments(_arguments);
				if (all)
					OnNewArguments(_arguments);
			}

			public override void Dispose()
			{
				base.Dispose();

				for (var i = 0; i < _arguments.Length; i++)
					_arguments[i].Dispose();
				
				_func = null;
				_arguments = null;
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
			return new SimpleSubscription(this, context, listener);
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

			public SimpleSubscription(SimpleVarArgFunction func, IContext context, IListener listener)
				: base(func, context)
			{
				_func = func;
				_listener = listener;
				Init();
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
}
