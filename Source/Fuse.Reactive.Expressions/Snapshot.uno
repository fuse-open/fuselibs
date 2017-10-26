using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	[UXUnaryOperator("Snapshot")]
	/** Returns the first value to propagate from the source expression, and then stops listening. */
	public class Snapshot: Expression
	{
		public Expression Source { get; private set; }

		[UXConstructor]
		public Snapshot([UXParameter("Source")] Expression source)
		{
			Source = source;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new Subscription(this, context, listener);
		}

		class Subscription: IDisposable, IListener
		{
			Snapshot _snap;
			IListener _listener;
			IDisposable _sub;

			public Subscription(Snapshot snap, IContext context, IListener listener)
			{
				_snap = snap;
				_listener = listener;
				_sub = _snap.Source.Subscribe(context, this);
			}

			public void Dispose()
			{
				_listener = null;
				if (_sub != null)
				{
					_sub.Dispose();
					_sub = null;
				}
			}

			void IListener.OnNewData(IExpression source, object value)
			{
				if (_listener != null)
					_listener.OnNewData(_snap, value);
					
				Dispose();
			}
			
			void IListener.OnLostData(IExpression source)
			{
				//keeps old value
			}
		}
	}
}