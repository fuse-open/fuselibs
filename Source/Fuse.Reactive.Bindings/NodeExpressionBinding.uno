using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	/**
		Provides a binding between an node an expression.
	*/
	public sealed class NodeExpressionBinding : IContext, IDisposable
	{
		IExpression _expr;
		IListener _listener;
		IDisposable _sub;
		Node _node;
		NameTable _nameTable;
		
		public NodeExpressionBinding( IExpression expr, Node node, IListener listener,
			NameTable nameTable ) 
		{
			if (expr == null || node == null || listener == null || nameTable == null)
				throw new Exception( "Invalid params" );
				
			_expr = expr;
			_listener = listener;
			_node = node;
			_nameTable = nameTable;
			
			UpdateManager.AddDeferredAction( CompleteInit );
		}
		
		void CompleteInit()
		{
			if (_expr == null) //already disposed
				return;
				
			_sub = _expr.Subscribe(this, _listener);
		}
		
		static NameTable _emptyNameTable = new NameTable(null, new string[]{} );
		public NameTable NameTable { get { return _nameTable ?? _emptyNameTable; } }
		
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