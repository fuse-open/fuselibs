using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	//TODO: this is hacky. clean it up, hide it, make simple interface to just evaluate an expression once
	public sealed class NodeExpressionBinding : IContext, IDisposable
	{
		IExpression _expr;
		IListener _listener;
		IDisposable _sub;
		Node _node;
		
		public NodeExpressionBinding( IExpression expr, Node node, IListener listener ) 
		{
			_expr = expr;
			_listener = listener;
			_node = node;
		}
		
		public void Init()
		{
			_sub = _expr.Subscribe(this, _listener);
		}
		
		static NameTable _emptyNameTable = new NameTable(null, new string[]{} );
		public NameTable NameTable { get { return _emptyNameTable; } }
		
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