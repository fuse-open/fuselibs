using Uno;

namespace Fuse.Reactive
{
	/**
		Subscribes to many argument expressions used in higher level functions. This collects common
		behaviour and means to simplify higher-level code.
		
		NOTE: The use of InnerListener is questionable but unavoidable at this time.
		https://github.com/fuse-open/fuselibs/issues/785
		
		@hide
	*/
	public abstract class ExpressionSubscriber : InnerListener
	{
		[Flags]
		public enum Flags
		{
			None = 0,
			Optional0 = 1 << 0,
			Optional1 = 1 << 1,
			Optional2 = 1 << 2,
			Optional3 = 1 << 3,
			
			AllOptional = 1 << 10,
		}
		
		object _source;
		Flags _flags;
		Expression.Argument[] _args;

		internal ExpressionSubscriber( Expression[] args, Flags flags, object source = null )
		{
			_flags = flags;
			_source = source ?? this;
			
			_args = new Expression.Argument[args.Length];
			for (int i=0; i < args.Length; ++i)
			{
				if (args[i] == null)
					throw new Exception( "May not contain null: " + nameof(args) );
				_args[i] = new Expression.Argument{ Source = args[i] };
			}
		}
		
		/** Must be called by instantiators of subscription after construction.
			This avoids race condition if subscriptions call back synchronously. */
		public void Init(IContext context)
		{
			for (int i=0; i < _args.Length; ++i)
				_args[i].Subscription = _args[i].Source.Subscribe(context, this);
			UpdateOperands(); //in case all optional
		}
		
		protected sealed override void OnNewData(IExpression source, object value)
		{
			for (int i=0; i < _args.Length; ++i)
			{
				if (_args[i].Source == source)
				{
					_args[i].Value = value;
					_args[i].HasValue = true;
				}
			}
			UpdateOperands();
		}
	
		protected sealed override void OnLostData(IExpression source)
		{
			for (int i=0; i < _args.Length; ++i)
			{
				if (_args[i].Source == source)
				{
					_args[i].Value = null;
					_args[i].HasValue = false;
				}
			}
			
			UpdateOperands();
		}
		
		bool IsOptional(int index)
		{
			if (_flags.HasFlag( Flags.AllOptional ) )
				return true;
			if (index == 0)
				return _flags.HasFlag( Flags.Optional0 );
			if (index == 1)
				return _flags.HasFlag( Flags.Optional1 );
			if (index == 2)
				return _flags.HasFlag( Flags.Optional2 );
			if (index == 3)
				return _flags.HasFlag( Flags.Optional3 );
			return false;
		}
		
		void UpdateOperands()
		{
			ClearDiagnostic();
			
			try
			{
				bool okay = true;
				for (int i=0; i < _args.Length; ++i)
				{
					if (!_args[i].HasValue && !IsOptional(i))
					{
						okay = false;
						break;
					}
				}
				
				if (okay)
					OnArguments(_args);
				else
					OnClearData();
			}
			catch (MarshalException me)
			{
				OnClearData();
				SetDiagnostic(me.Message, _source);
			}
		}
		
		public override void Dispose()
		{
			for (int i=0; i < _args.Length; ++i)
				_args[i].Dispose();
			_source = null;
			base.Dispose();
		}
		
		/**
			Will only be called if all non-optional arguments have been provided.
			
			It is the implementers responsibility to call `SetData` or `ClearData` as appropriate.  Note that this class will however call `ClearData` on its own if not all optional arguments are provided, or there is an error.
		*/
		protected abstract void OnArguments(Expression.Argument[] args);
		
		internal abstract void OnClearData();
	}

	/**
		A base class for common expression subscriptions. This handles the basic bookkeeping. Derived classes should implement `OnArguments` (coming from the base class). The members `ClearData` and `SetData` should be called to set the output state.
		
		Using this directly is unsual, consider `ComputeExpression` instead.
		
		Derived classes should implement `OnArguments`
		
		@advanced
	*/
	public abstract class ExpressionListener : ExpressionSubscriber
	{
		IListener _listener;
		bool _hasData;
		object _curData;
		Expression _source;
		
		//exposed for deprecated code paths
		internal IListener Listener { get { return _listener; } }

		protected ExpressionListener( Expression source, IListener listener, Expression[] args, Flags flags = Flags.None) :
			base( args, flags, source )
		{
			if (listener == null)
				throw new Exception( "May not be null: "+  nameof(listener) );
			if (source == null)
				throw new Exception( "May not be null: " + nameof(source) );
				
			_listener = listener;
			_source = source;
		}
		
		public override void Dispose()
		{
			_listener = null;
			_hasData = false;
			_curData = null;
			base.Dispose();
		}
		
		/** The output will be cleared, set to a lost data state.
			This is meant to be sealed, but is not in order to support DeprecatedVirtualUnary.
		*/
		internal override /*sealed*/ void OnClearData()
		{
			ClearData();
		}
		
		protected void ClearData()
		{
			if (_hasData && _listener != null)
			{
				_hasData = false;
				_curData = null;
				_listener.OnLostData(_source);
			}
			
			OnDataCleared();
		}
		
		protected virtual void OnDataCleared() { }
		
		/** The output is set to the given value. */
		protected void SetData(object value)
		{
			if (!_hasData || value != _curData)
			{
				_hasData = true;
				_curData = value;
				_listener.OnNewData(_source, value);
			}
		}
	}
	
	/**
		Base class for UX expression functions that take arguments and compute a value from them.
		
		This is the preferred base for most functions unless they have special needs to track whether/when arguments are set and/or lost.
		
		Only a conctructor and the `Compute` method need to be defined.
	*/
	public abstract class ComputeExpression : Expression
	{
		[Flags]
		public enum Flags
		{
			None = 0,
			Optional0 = 1 << 0,
			Optional1 = 1 << 1,
			Optional2 = 1 << 2,
			Optional3 = 1 << 3,
		
			/** All arguments to the expression are optional. `Compute` will be called when HasValue is false for individual, or all, values */
			AllOptional = 1 << 4,
			
			/** A warning should not be emitted when `Compute` returns false, indicating this is an expected condition, or the derived class will emit its own diagnostics */
			OmitComputeWarning = 1 << 5,
			
			/** @deprecated 2017-12-14 This is strictly for compatibility with deprecated constructors */
			DeprecatedVirtualFlags = 1 << 10,
			DeprecatedVirtualUnary = 1 << 11,
		}
		
		Expression[] _args;
		protected Expression GetArgument(int i)
		{
			return _args[i];
		}
		
		Flags _flags;
		String _name;
		protected ComputeExpression( Expression[] args, Flags flags = Flags.None, string name = null )
		{
			_flags = flags;
			_args = args;
			_name = name;
			
			if (_flags.HasFlag( Flags.DeprecatedVirtualFlags) )
			{
				//DEPRECATED: 2017-12-14
				Fuse.Diagnostics.Deprecated( "This constructor and use of the Is*Optional virtuals is deprecated. Pass the optionals as flags to the constructor, or specifiy Flags.None to avoid the message", this );
			}
			if (_flags.HasFlag( Flags.DeprecatedVirtualUnary) )
			{
				if (!(this is UnaryOperator) || args.Length != 1)
					throw new Exception( "DeprecatedVirtualUnary supported only on UnaryOperator with 1 argument" );
					
				//DEPRECATED: 2017-12-14
				Fuse.Diagnostics.Deprecated( "Overiding the UnaryOperator.OnNewOperand/OnLostData is deprecated. Implement `Compute` and call the other constructor, or pass Flags.None, or implement an `Expression` and `ExpressionListener` if you need the behavior (rare).", this );
			}
		}

		//may be null if undefined
		protected string Name 
		{
			get { return _name; }
		}
		string EffectiveName
		{
			get { return _name ?? this.GetType().FullName; } // `.Name` would be better, but it doesn't appear to be defined
		}
		
		public override string ToString()
		{
			string r = Name + "(";
			for (int i=0; i < _args.Length; ++i)
			{
				if (i > 0)
					r += ", ";
				r += _args[i];
			}
			r += ")";
			return r;
		}
		
		ExpressionSubscriber.Flags EffectiveFlags
		{
			get 
			{
				var flags =_flags.HasFlag(Flags.DeprecatedVirtualFlags) ? GetFlags() : _flags;

				return ExpressionListener.Flags.None |	
					(flags.HasFlag(Flags.Optional0) ? ExpressionListener.Flags.Optional0 : ExpressionListener.Flags.None) |
					(flags.HasFlag(Flags.Optional1) ? ExpressionListener.Flags.Optional1 : ExpressionListener.Flags.None) |
					(flags.HasFlag(Flags.Optional2) ? ExpressionListener.Flags.Optional2 : ExpressionListener.Flags.None) |
					(flags.HasFlag(Flags.Optional3) ? ExpressionListener.Flags.Optional3 : ExpressionListener.Flags.None) |
					(flags.HasFlag(Flags.AllOptional) ? ExpressionListener.Flags.AllOptional :
					ExpressionListener.Flags.None);
			}
		}
		
		internal virtual Flags GetFlags() { return _flags; }
		
		/**
			Should calculate the resulting value from the provided arguments.
			
			The length of `args` is guaranteed to be same length as the constructor `args` argument.
		*/
		protected abstract bool TryCompute(Expression.Argument[] args, out object result);
		
		public sealed override IDisposable Subscribe(IContext context, IListener listener)
		{
			var sub = new Subscription(this,  listener);
			sub.Init(context);
			return sub;
		}

		class Subscription : ExpressionListener
		{
			ComputeExpression _expr;
			
			public Subscription( ComputeExpression expr, IListener listener )
				: base( expr, listener, expr._args, expr.EffectiveFlags )
			{
				_expr = expr;
			}

			protected override void OnArguments(Expression.Argument[] args)
			{
				if (_expr._flags.HasFlag( ComputeExpression.Flags.DeprecatedVirtualUnary) )
				{
					((UnaryOperator)_expr).InternalOnNewOperand( Listener, args[0].Value );
					return;
				}
				
				object result;
				if (_expr.TryCompute(args, out result))
				{
					SetData( result );
				}
				else
				{
					if (!_expr._flags.HasFlag( ComputeExpression.Flags.OmitComputeWarning ) )
					{
						string msg = "Failed to compute value for (";
						for (int i=0; i < args.Length; ++i)
						{
							if (i > 0)
								msg += ",";
							if (args[i].HasValue)	
								msg += args[i].Value;
							else
								msg += "undefined";
						}
						Fuse.Diagnostics.UserWarning( msg, _expr );
					}
					OnClearData();
				}
			}
			
			internal override void OnClearData()
			{
				if (_expr._flags.HasFlag( ComputeExpression.Flags.DeprecatedVirtualUnary) )
					((UnaryOperator)_expr).InternalOnLostOperand( Listener );
				else
					base.OnClearData();
			}
		}
	}
	
}
