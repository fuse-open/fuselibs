using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	public abstract class ExpressionBinding: Binding, IContext, IListener
	{
		public IExpression Key { get; private set; }

		protected ExpressionBinding(IExpression key)
		{
			Key = key;
		}

		IDisposable _expressionSub;

		protected internal bool CanWriteBack { get { return _expressionSub is IWriteable; } }
		protected internal void WriteBack(object value) { ((IWriteable)_expressionSub).TrySetExclusive(value); }

		protected override void OnRooted()
		{
			base.OnRooted();
			_expressionSub = Key.Subscribe(this, this);
		}

		IDisposable IContext.Subscribe(IExpression source, string key, IListener listener)
		{
			return new DataSubscription(source, Parent, key, listener);
		}

		Node IContext.Node { get { return Parent; } }

		public virtual IDisposable SubscribeResource(IExpression source, string key, IListener listener)
		{
			throw new Exception("The binding type does not support resource subscriptions");
		}

		protected override void OnUnrooted()
		{
			if (_expressionSub != null)
			{
				_expressionSub.Dispose();
				_expressionSub = null;
			}
			base.OnUnrooted();
		}

		void IListener.OnNewData(IExpression source, object obj) { NewValue(obj); }

		internal abstract void NewValue(object obj);
	}
}