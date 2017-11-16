using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	[UXFunction("hasValue")]
	/** 
		Test is a value is available, returning `true` or `false`. This can be used to check if a value is available yet in the data context.
		
		If the value exists but is null then `true` will still be returned.
		
		@advanced
	*/
	public sealed class HasValue: Expression
	{
		public Expression Operand { get; private set; }
		
		[UXConstructor]
		public HasValue([UXParameter("Operand")] Expression operand)
		{
			Operand = operand;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return Subscription.Create(this, context, listener);
		}

		class Subscription: InnerListener
		{
			readonly HasValue _hv;
			IDisposable _opSub;
			IListener _listener;
			bool _hasValue;

			protected Subscription(HasValue hv, IListener listener)
			{
				_hv = hv;
				_listener = listener;
			}

			public static Subscription Create(HasValue hv, IContext context, IListener listener)
			{
				var res = new Subscription(hv, listener);
				res.Init(context);
				return res;
			}
			
			protected void Init(IContext context)
			{
				_opSub = _hv.Operand.Subscribe(context, this);
				if (!_hasValue)
					_listener.OnNewData( _hv, false );
			}

			protected override void OnNewData(IExpression source, object value)
			{
				UpdateData(true);
			}
			
			protected override void OnLostData(IExpression source)
			{
				UpdateData(false);
			}
			
			void UpdateData(bool has)
			{
				if (_hasValue == has)
					return;
					
				_listener.OnNewData( _hv, has );
				_hasValue = has;
			}

			public override void Dispose()
			{
				base.Dispose();

				if (_opSub != null)
				{
					_opSub.Dispose();
					_opSub = null;
				}
				_listener = null;
			}
		}
	}
	
	[UXFunction("isNull")]
	/** Returns true if the value exists and is non-null, false otherwise.
	
		This is the same condition used in the NullCoalesce operator:
		
			expr ?? res
			
		Is the same as:
		
			isNull(expr) ? res : expr
	*/
	public sealed class IsNull : UnaryOperator
	{
		[UXConstructor]
		public IsNull([UXParameter("Operand")] Expression operand): base(operand) {}
		protected override object Compute(object operand)
		{
			return operand == null;
		}

		public override string ToString()
		{
			return "isNull(" + Operand +  ")";
		}
		
		protected override bool IsOperandOptional { get { return true; } }
	}
}
