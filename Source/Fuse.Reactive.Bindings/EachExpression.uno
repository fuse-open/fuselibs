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
			var instantiator = context.Node.FindBehavior<Instantiator>();
			if (instantiator == null)
			{
				Fuse.Diagnostics.UserError( "Could not an Each", this );
				return null;
			}
			
			//find our node relative to the instantiator
			var p = context.Node;
			while (p != null && p.ContextParent != instantiator)
				p = p.ContextParent;
			if (p == null)
			{
				//given that instantiator wasn't null this shouldn't ever really happen
				Fuse.Diagnostics.InternalError( "Unable to resolve Each node", this );
				return null;
			}
			
			return new InstantiatorSubscription(this, instantiator, p, _item, listener, context );
		}
		
		class InstantiatorSubscription : Subscription
		{
			InstantiatorFunction _expr;
			Instantiator _instantiator;
			Node _instance;
			Selector _item;
			IListener _listener;
			
			public InstantiatorSubscription(InstantiatorFunction expr, Instantiator instantiator, 
				Node instance, Selector item, IListener listener, IContext context ) : 
				base(expr, listener)
			{
				_expr = expr;
				_instantiator = instantiator;
				_item = item;
				_instance = instance;
				_listener = listener;
				Init(context);
			}
			
			protected override void OnNewOperand(object obj)
			{
				PushValue();
			}
			
			public override void Dispose()
			{
				base.Dispose();
				_expr = null;
				_listener = null;
				_instantiator = null;
			}
			
			void PushValue()
			{
				_listener.OnNewData(_expr, GetValue());
			}
			
			object GetValue()
			{
				if (_item == InstantiatorFunction.DataIndexName)
					return _instantiator.DataIndexOfChild(_instance);
					
				if (_item == InstantiatorFunction.OffsetIndexName)
					return _instantiator.DataIndexOfChild(_instance) - _instantiator.Offset;
				
				return null;
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