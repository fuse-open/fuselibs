using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Reactive
{
	/* The use of VarArg is a workaround to 
	https://github.com/fusetools/fuselibs-private/issues/4199 */
	
	/** Common base for functions that work with an item in an instantiator */
	public abstract class InstantiatorFunction : VarArgFunction
	{
		static internal Selector DataIndexName = "index";
		static internal Selector OffsetIndexName = "offsetIndex";
		
		Selector _item;
		
		internal InstantiatorFunction( Selector item )
			: base()
		{
			_item = item;
		}
		
 		public override string ToString()
 		{
 			return FormatString(_item);
 		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			if (Arguments.Count > 1)
			{
				Fuse.Diagnostics.UserError( "too many parameters for " + _item, this );
				return null;
			}
			
			var node = Arguments.Count > 0 ? Arguments[0] : null;
			var ins = new InstantiatorSubscription(this, _item, listener, context, node );
			ins.Init(context);
			return ins;
		}
		
		class InstantiatorSubscription : InnerListener
		{
			//static values
			InstantiatorFunction _expr;
			Selector _item;
			IListener _listener;
			IContext _context;
			IExpression _node;
			
			//the actual object values for the function
			Instantiator _instantiator;
			Node _instance;

			IDisposable _nodeSub;

			public InstantiatorSubscription(InstantiatorFunction expr, Selector item, IListener listener, 
				IContext context, IExpression node ) : 
				base()
			{
				_node = node;
				_expr = expr;
				_item = item;
				_listener = listener;
				_context = context;
			}
			
			public void Init(IContext context)
			{
				if (_node == null)	
					OnNewNode(null);
				else
					_nodeSub = _node.Subscribe(context, this);
			}
			
			protected override void OnNewData(IExpression source, object value)
			{
				if (source == _node)
					OnNewNode(value);
			}
			
			protected override void OnLostData(IExpression source)
			{
				if (source == _node)
					_listener.OnLostData(_expr);
			}
			
			void OnNewNode(object obj)
			{
				if (_instantiator != null)
				{
					_instantiator.UpdatedWindowItems -= OnUpdatedWindowItems;
					_instantiator = null;
					_instance = null;
				}
				
				var searchNode = obj as Node ?? _context.Node;
				if (searchNode == null)
				{
					Fuse.Diagnostics.UserError( "invalid search node for InstantiatorFunction", this );
					_listener.OnLostData(_expr);
					return;
				}
				
				_instantiator = searchNode.FindBehavior<Instantiator>();
				if (_instantiator == null)
				{
					Fuse.Diagnostics.UserError( "Could not find an Instantiator", this );
					_listener.OnLostData(_expr);
					return;
				}
				
				//find our node relative to the instantiator
				var p = _context.Node;
				while (p != null && p.ContextParent != _instantiator)
					p = p.ContextParent;
				if (p == null)
				{
					//given that instantiator wasn't null this shouldn't ever really happen
					Fuse.Diagnostics.InternalError( "Unable to resolve Instantiator node", this );
					_listener.OnLostData(_expr);
					return;
				}
				
				if (_instantiator != null)
				{
					_instance = p;
					_instantiator.UpdatedWindowItems += OnUpdatedWindowItems;
					PushValue();
				}
			}
			
			public override void Dispose()
			{
				base.Dispose();
				_expr = null;
				_listener = null;
				if (_instantiator != null)
					_instantiator.UpdatedWindowItems -= OnUpdatedWindowItems;
				_instantiator = null;
				if (_nodeSub != null)
					_nodeSub.Dispose();
				_nodeSub = null;
				_node = null;
			}
	
			void PushValue()
			{
				int q = -1;
				if (_item == InstantiatorFunction.DataIndexName)
					q =  _instantiator.DataIndexOfChild(_instance);
				else if (_item == InstantiatorFunction.OffsetIndexName)
					q = _instantiator.DataIndexOfChild(_instance) - _instantiator.Offset;

				if (q != -1)
					_listener.OnNewData(_expr, q);
				else
					_listener.OnLostData(_expr);
			}
			
			void OnUpdatedWindowItems()
			{
				PushValue();
			}
		}
	}
	
	[UXFunction("index")]
	public class IndexFunction : InstantiatorFunction
	{
		[UXConstructor]
		public IndexFunction()
			: base( DataIndexName )
		{
		}
	}
	
	[UXFunction("offsetIndex")]
	public class OffsetIndexFunction : InstantiatorFunction
	{
		[UXConstructor]
		public OffsetIndexFunction()
			: base( OffsetIndexName )
		{
		}
	}
}	