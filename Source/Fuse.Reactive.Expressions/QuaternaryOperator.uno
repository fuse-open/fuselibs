using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Optimized base class for reactive functions/operators that take a four arguments/operands. */
	public abstract class QuaternaryOperator: Expression
	{
		public Expression First { get; private set; }
		public Expression Second { get; private set; }
		public Expression Third { get; private set; }
		public Expression Fourth { get; private set; }

		protected QuaternaryOperator(Expression first, Expression second, Expression third, Expression fourth)
		{
			First = first;
			Second = second;
			Third = third;
			Fourth = fourth;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return Subscription.Create(this, context, listener);
		}

		protected virtual bool IsFirstOptional { get { return false; } }
		protected virtual bool IsSecondOptional { get { return false; } }
		protected virtual bool IsThirdOptional { get { return false; } }
		protected virtual bool IsFourthOptional { get { return false; } }

		protected abstract object Compute(object first, object second, object third, object fourth);

		class Subscription: InnerListener
		{
			readonly QuaternaryOperator _qo;
			object _first, _second, _third, _fourth;
			bool _hasFirst, _hasSecond, _hasThird, _hasFourth;

			IDisposable _firstSub;
			IDisposable _secondSub;
			IDisposable _thirdSub;
			IDisposable _fourthSub;

			IListener _listener;
			
			protected Subscription(QuaternaryOperator qo, IListener listener)
			{
				_qo = qo;
				_listener = listener;
			}

			public static Subscription Create(QuaternaryOperator qo, IContext context, IListener listener)
			{
				var res = new Subscription(qo, listener);
				res.Init(context);
				return res;
			}

			/** Must be called by subclasses at the end of constructor, or when fully initialized.
				This avoids race condition if subscriptions call back synchronously. */
			protected void Init(IContext context)
			{
				_firstSub = _qo.First.Subscribe(context, this);
				_secondSub = _qo.Second.Subscribe(context, this);
				_thirdSub = _qo.Third.Subscribe(context, this);
				_fourthSub = _qo.Fourth.Subscribe(context, this);
			}

			protected override void OnNewData(IExpression source, object value)
			{
				if (source == _qo.First) { _hasFirst = true; _first = value; }
				if (source == _qo.Second) { _hasSecond = true; _second = value; }
				if (source == _qo.Third) { _hasThird = true; _third = value; }
				if (source == _qo.Fourth) { _hasFourth = true; _fourth = value; }

				if ((_hasFirst || _qo.IsFirstOptional) && (_hasSecond || _qo.IsSecondOptional) && (_hasThird || _qo.IsThirdOptional) && (_hasFourth || _qo.IsFourthOptional))
					OnNewOperands(_first, _second, _third, _fourth);
			}

			protected virtual void OnNewOperands(object first, object second, object third, object fourth)
			{
				ClearDiagnostic();

				try
				{
					_listener.OnNewData(_qo, _qo.Compute(first, second, third, fourth));
				}
				catch (MarshalException me)
				{
					SetDiagnostic(me.Message, _qo);
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
				if (_fourthSub != null)
				{
					_fourthSub.Dispose();
					_fourthSub = null;
				}
				_listener = null;
			}
		}
	}
}

