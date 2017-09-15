using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	/**
		Provides a binding between an node an expression.
	*/
	sealed class NodeExpressionBinding : IContext, IDisposable
	{
		IExpression _expr;
		IListener _listener;
		IDisposable _sub;
		Node _node;
		
		public NodeExpressionBinding( IExpression expr, Node node, IListener listener ) 
		{
			if (expr == null || node == null || listener == null)
				throw new Exception( "Invalid params" );
				
			_expr = expr;
			_listener = listener;
			_node = node;
			
			UpdateManager.AddDeferredAction( CompleteInit );
		}
		
		void CompleteInit()
		{
			if (_expr == null) //already disposed
				return;
				
			_sub = _expr.Subscribe(this, _listener);
		}
		
		IDisposable IContext.Subscribe(IExpression source, string key, IListener listener)
		{
			return new DataSubscription(source, _node, key, listener);
		}
		
		Node IContext.Node { get { return _node; } }
		
		public virtual IDisposable SubscribeResource(IExpression source, string key, IListener listener)
		{
			throw new Exception("The binding type does not support resource subscriptions");
		}
		
		public void Dispose()
		{
			if (_sub != null)
				_sub.Dispose();
			_expr = null;
			_listener = null;
			_node = null;
		}
	}
}