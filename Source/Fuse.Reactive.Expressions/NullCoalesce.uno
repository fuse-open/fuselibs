using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	public sealed class NullCoalesce: Expression
	{
		public Expression Left { get; private set; }
		public Expression Right { get; private set; }
		[UXConstructor]
		public NullCoalesce([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
		{
			Left = left;
			Right = right;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return Subscription.Create(this, context, listener);
		}

		class Subscription: InnerListener
		{
			readonly NullCoalesce _bo;
			object _left, _right;

			IDisposable _leftSub;
			IDisposable _rightSub;

			IListener _listener;
			bool _hasLeft;
			bool _hasRight;

			protected Subscription(NullCoalesce bo, IListener listener)
			{
				_bo = bo;
				_listener = listener;
			}

			public static Subscription Create(NullCoalesce bo, IContext context, IListener listener)
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
				UpdateValue();
			}
			
			void UpdateValue()
			{
				if (_hasLeft && _left != null)
					_listener.OnNewData( _bo, _left );
				else if (_hasRight)
					_listener.OnNewData( _bo, _right );
				else 
					_listener.OnLostData( _bo );
			}
			
			protected override void OnLostData(IExpression source)
			{
				if (source == _bo.Left) { _hasLeft = false; }
				if (source == _bo.Right) { _hasRight = false; }
				UpdateValue();
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

