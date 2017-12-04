using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/* This class is part of a set of classes: UnaryOperator, BinaryOperator, TernaryOperator, QuaternaryOperator.
		If you modify one you'll likely need to modify all four. */
		
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
			Fuse.Diagnostics.Deprecated( " No `Compute`, or a deprecated form, overriden. Migrate your code to override the one with `bool` return. ", this );
			result = Compute(left, right);
			return true;
		}
		
		/** @deprecated Override the other `Compute` function. 2017-11-29 */
		protected virtual object Compute(object left, object right) { return null; }

		/* TODO: This shouldn't exist, it should follow the same pattern as Ternary/QuaternaryOperator. It's still internal now due to `DelayFunction` incorrectly deriving from a `BinaryOperator` 
		https://github.com/fusetools/fuselibs-public/issues/829 */
		internal virtual bool OnNewOperands(IListener listener, object left, object right)
		{
			object result;
			if (Compute(left, right, out result))
			{
				listener.OnNewData(this, result);
				return true;
			}
			else
				return false;
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
			
			void ClearData()
			{
				if (_hasData)
				{
					_hasData = false;
					_listener.OnLostData(_bo);
				}
			}
			
			void UpdateOperands()
			{
				ClearDiagnostic();
				
				try
				{
					if ((_hasLeft || _bo.IsLeftOptional) && (_hasRight || _bo.IsRightOptional))
					{
						//see OnNewOperands for why this structure is weird compared to Ternary/QuaternaryOperator
						if (_bo.OnNewOperands(_listener, _left, _right))
						{
							_hasData = true;
						}
						else
						{
							Fuse.Diagnostics.UserWarning( "Failed to compute value for (" +
								_left + ", " + _right, _bo );
							ClearData();
						}
					}
					else if (_hasData)
					{
						ClearData();
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

