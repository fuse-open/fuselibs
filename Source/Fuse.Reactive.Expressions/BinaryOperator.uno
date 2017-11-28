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

		protected virtual bool Compute(object left, object right, out object result)
		{
			throw new Exception(GetType().FullName + " does not implement the required methods");
		}

		protected virtual void OnNewOperands(IListener listener, object left, object right)
		{
			object result;
			if (Compute(left, right, out result))
				listener.OnNewData(this, result);
			else
				listener.OnLostData(this);
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
			bool _hasData;

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
				UpdateOperands();
			}

			protected override void OnNewData(IExpression source, object value)
			{
				if (source == _bo.Left) { _hasLeft = true; _left = value; }
				if (source == _bo.Right) { _hasRight = true; _right = value; }
				UpdateOperands();
			}
			
			protected override void OnLostData(IExpression source)
			{
				if (source == _bo.Left) { _hasLeft = false; _left = null; }
				if (source == _bo.Right) { _hasRight = false; _right = null; }
				UpdateOperands();
			}
			
			void UpdateOperands()
			{
				ClearDiagnostic();
				
				try
				{
					if ((_hasLeft || _bo.IsLeftOptional) && (_hasRight || _bo.IsRightOptional))
					{
						_hasData = true;
						_bo.OnNewOperands(_listener, _left, _right);
					}
					else if (_hasData)
					{
						_hasData = false;
						_bo.OnLostOperands(_listener);
					}
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

