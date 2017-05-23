using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Reactive
{
	public abstract class InstantiatorFunction : UnaryOperator
	{
		static internal Selector DataIndexName = "index";
		static internal Selector OffsetIndexName = "offsetIndex";
		
		Selector _item;
		
		internal InstantiatorFunction( Reactive.Expression node, Selector item )
			: base( node)
		{
			_item = item;
		}
		
		public override string ToString()
		{
			return _item + "(" + Operand.ToString() +")";
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new InstantiatorSubscription(this, _item, listener, context );
		}
		
		class InstantiatorSubscription : Subscription
		{
			InstantiatorFunction _expr;
			Instantiator _instantiator;
			Node _instance;
			Selector _item;
			IListener _listener;
			IContext _context; //TODO: in base?
			
			public InstantiatorSubscription(InstantiatorFunction expr, Selector item, IListener listener, IContext context ) : 
				base(expr, listener)
			{
				_expr = expr;
				_item = item;
				_listener = listener;
				_context = context;
				Init(context);
			}
			
			protected override void OnNewOperand(object obj)
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
					return;
				}
				
				_instantiator = searchNode.FindBehavior<Instantiator>();
				if (_instantiator == null)
				{
					Fuse.Diagnostics.UserError( "Could not find an Instantiator", this );
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
		public IndexFunction([UXParameter("Node")]/*[UXDefaultValue("null")]*/ Reactive.Expression node)
			: base( node, DataIndexName )
		{
		}
	}
	
	[UXFunction("offsetIndex")]
	public class OffsetIndexFunction : InstantiatorFunction
	{
		[UXConstructor]
		public OffsetIndexFunction([UXParameter("Node")]/*[UXDefaultValue("null")]*/ Reactive.Expression node)
			: base( node, OffsetIndexName )
		{
		}
	}
}	