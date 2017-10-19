using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Optimized base class for reactive functions/operators that take a two arguments/operands. 

		Subclasses must override etiher `Compute` for pure/synchronous functions, or `OnNewOperands` to 
		allow more advanced control over when the listener is notified.
	*/
	public abstract class BinaryOperator: Expression
	{
		public Expression Left { get; private set; }
		public Expression Right { get; private set; }
		protected BinaryOperator(Expression left, Expression right)
		{
			Left = left;
			Right = right;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return Subscription.Create(this, context, listener);
		}

		protected virtual bool IsLeftOptional { get { return false; } }
		protected virtual bool IsRightOptional { get { return false; } }

		protected virtual object Compute(object left, object right)
		{
			throw new Exception(GetType().FullName + " does not implement the required methods");
		}

		protected virtual void OnNewOperands(IListener listener, object left, object right)
		{
			listener.OnNewData(this, Compute(left, right));
		}
		
		protected virtual void OnLostOperands(IListener listener)
		{
			listener.OnLostData(this);
		}

		class Subscription: InnerListener
		{
			readonly BinaryOperator _bo;
			object _left, _right;

			IDisposable _leftSub;
			IDisposable _rightSub;

			IListener _listener;
			bool _hasLeft;
			bool _hasRight;

			protected Subscription(BinaryOperator bo, IListener listener)
			{
				_bo = bo;
				_listener = listener;
			}

			public static Subscription Create(BinaryOperator bo, IContext context, IListener listener)
			{
				var res = new Subscription(bo, listener);
				res.Init(context);
				return res;
			}
			
			/** Must be called by subclasses at the end of constructor, or when fully initialized.
				This avoids race condition if subscriptions call back synchronously. */
			protected void Init(IContext context)
			{
				_leftSub = _bo.Left.Subscribe(context, this);
				_rightSub = _bo.Right.Subscribe(context, this);
			}

			protected override void OnNewData(IExpression source, object value)
			{
				if (source == _bo.Left) { _hasLeft = true; _left = value; }
				if (source == _bo.Right) { _hasRight = true; _right = value; }

				if ((_hasLeft || _bo.IsLeftOptional) && (_hasRight || _bo.IsRightOptional))
					OnNewOperands(_left, _right);
			}
			
			protected override void OnLostData(IExpression source)
			{
				_bo.OnLostOperands(_listener);
			}

			protected virtual void OnNewOperands(object left, object right)
			{
				ClearDiagnostic();

				try
				{
					_bo.OnNewOperands(_listener, left, right);
				}
				catch (MarshalException me)
				{
					SetDiagnostic(me.Message, _bo);
				}
			}

			public override void Dispose()
			{
				base.Dispose();

				if (_leftSub != null)
				{
					_leftSub.Dispose();
					_leftSub = null;
				}
				if (_rightSub != null)
				{
					_rightSub.Dispose();
					_rightSub = null;
				}
				_listener = null;
			}
		}
	}
}

