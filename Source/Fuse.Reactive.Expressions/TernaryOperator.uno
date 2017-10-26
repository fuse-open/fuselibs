using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Optimized base class for reactive functions/operators that take a three arguments/operands. */
	public abstract class TernaryOperator: Expression
	{
		public Expression First { get; private set; }
		public Expression Second { get; private set; }
		public Expression Third { get; private set; }

		protected TernaryOperator(Expression first, Expression second, Expression third)
		{
			First = first;
			Second = second;
			Third = third;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return Subscription.Create(this, context, listener);
		}

		protected virtual bool IsFirstOptional { get { return false; } }
		protected virtual bool IsSecondOptional { get { return false; } }
		protected virtual bool IsThirdOptional { get { return false; } }

		protected abstract object Compute(object first, object second, object third);

		class Subscription: InnerListener
		{
			readonly TernaryOperator _to;
			object _first, _second, _third;
			bool _hasFirst, _hasSecond, _hasThird;
			bool _hasData;

			IDisposable _firstSub;
			IDisposable _secondSub;
			IDisposable _thirdSub;

			IListener _listener;
			
			protected Subscription(TernaryOperator to, IListener listener)
			{
				_to = to;
				_listener = listener;
			}

			public static Subscription Create(TernaryOperator to, IContext context, IListener listener)
			{
				var sub = new Subscription(to, listener);
				sub.Init(context);
				return sub;
			}

			/** Must be called by subclasses at the end of constructor, or when fully initialized.
				This avoids race condition if subscriptions call back synchronously. */
			protected void Init(IContext context)
			{
				_firstSub = _to.First.Subscribe(context, this);
				_secondSub = _to.Second.Subscribe(context, this);
				_thirdSub = _to.Third.Subscribe(context, this);
				UpdateOperands(); //in case all optional
			}

			protected override void OnNewData(IExpression source, object value)
			{
				if (source == _to.First) { _hasFirst = true; _first = value; }
				if (source == _to.Second) { _hasSecond = true; _second = value; }
				if (source == _to.Third) { _hasThird = true; _third = value; }
				UpdateOperands();
			}
			
			protected override void OnLostData(IExpression source)
			{
				if (source == _to.First) { _hasFirst = false; _first = null; }
				if (source == _to.Second) { _hasSecond = false; _second = null; }
				if (source == _to.Third) { _hasThird = false; _third = null; }
				UpdateOperands();
			}
			
			void UpdateOperands()
			{
				ClearDiagnostic();
				
				try
				{
					if ((_hasFirst || _to.IsFirstOptional) && (_hasSecond || _to.IsSecondOptional) && 
						(_hasThird || _to.IsThirdOptional))
					{
						_hasData = true;
						_listener.OnNewData(_to, _to.Compute(_first, _second, _third));
					}
					else if (_hasData)
					{
						_hasData = false;
						_listener.OnLostData(_to);
					}
				}
				catch (MarshalException me)
				{
					SetDiagnostic(me.Message, _to);
				}
			}

			public override void Dispose()
			{
				base.Dispose();

				if (_firstSub != null)
				{
					_firstSub.Dispose();
					_firstSub = null;
				}
				if (_secondSub != null)
				{
					_secondSub.Dispose();
					_secondSub = null;
				}
				if (_thirdSub != null)
				{
					_thirdSub.Dispose();
					_thirdSub = null;
				}
				_listener = null;
			}
		}
	}
}

