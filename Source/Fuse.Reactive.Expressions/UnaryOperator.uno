using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Optimized base class for reactive functions/operators that take a single argument/operand. */
	public abstract class UnaryOperator: Expression
	{
		public Expression Operand { get; private set; }
		protected UnaryOperator(Expression operand)
		{
			Operand = operand;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return Subscription.Create(this, context, listener);
		}

		protected virtual bool IsOperandOptional { get { return false; } }
		
		protected virtual object Compute(object operand)
		{
			throw new Exception(GetType().FullName + " does not implement the required methods");
		}

		protected virtual void OnNewOperand(IListener listener, object operand)
		{
			listener.OnNewData(this, Compute(operand));
		}
		
		protected virtual void OnLostOperand(IListener listener)
		{
			listener.OnLostData(this);
		}
		
		protected class Subscription: InnerListener
		{
			UnaryOperator _uo;
			IListener _listener;
			object _value;
			bool _hasValue, _hasData;

			IDisposable _operandSub;
			protected Subscription(UnaryOperator uo, IListener listener)
			{
				_uo = uo;
				_listener = listener;
			}

			public static Subscription Create(UnaryOperator uo, IContext context, IListener listener)
			{
				var sub = new Subscription(uo, listener);
				sub.Init(context);
				return sub;
			}

			/** Must be called by subclasses at the end of constructor, or when fully initialized.
				This avoids race condition if the subscription calls back synchronously. */
			protected void Init(IContext context)
			{
				_operandSub = _uo.Operand.Subscribe(context, this);
				UpdateOperands();
			}

			public override void Dispose()
			{
				base.Dispose();
				if (_operandSub != null) _operandSub.Dispose();
				_operandSub = null;
			}

			protected override void OnNewData(IExpression source, object value)
			{
				if (source == _uo.Operand) 
				{ 
					_hasValue = true; 
					_value = value;
				}
				UpdateOperands();
			}
			
			protected override void OnLostData(IExpression source)
			{
				if (source == _uo.Operand) 
				{ 
					_hasValue = false; 
					_value = null; 
				}
				UpdateOperands();
			}
			
			void UpdateOperands()
			{
				ClearDiagnostic();

				try
				{
					if (_hasValue || _uo.IsOperandOptional)
					{
						_hasData = true;
						_uo.OnNewOperand(_listener, _value);
					}
					else if (_hasData)
					{
						_hasData = false;
						_uo.OnLostOperand(_listener);
					}
				}
				catch (MarshalException me)
				{
					SetDiagnostic(me.Message, _uo);
				}
			}

			protected void PushNewData(object value)
			{
				_listener.OnNewData(_uo, value);
			}
		}
	}

	public sealed class Negate: UnaryOperator
	{
		public Negate([UXParameter("Operand")] Expression operand): base(operand) {}
		protected override object Compute(object operand)
		{
			return Marshal.Multiply(operand, -1);
		}
	}
}

