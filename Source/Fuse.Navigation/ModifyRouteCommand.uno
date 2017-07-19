using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Navigation
{
	[UXFunction("modifyRoute")]
	public class ModifyRouteCommand : VarArgFunction
	{
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new OuterSubscription(this, context, listener);
		}
		
		class OuterSubscription : InnerListener, IEventHandler
		{
			internal ModifyRouteCommand _expr;
			internal IListener _listener;
			internal IContext _context;
			InnerSubscription _innerSub;
			
			public OuterSubscription( ModifyRouteCommand expr, IContext context, IListener listener )
			{
				_expr = expr;
				_context = context;
				_listener = listener;
				_listener.OnNewData(_expr, this );
			}
			
			public override void Dispose()
			{
				base.Dispose();
				_expr = null;
				_listener = null;
				_context = null;
				DisposeInner();
			}
			
			internal void DisposeInner(bool fromInner = false)
			{
				if (_innerSub != null)
				{
					if (!fromInner)
						_innerSub.Dispose();
						
					_innerSub = null;
				}
			}
			
			void IEventHandler.Dispatch(IEventRecord e)
			{
				//only one at a time. There's no reason we should have to queue, the time between 
				//dispatch and evaluation is expected to be 0-2 frames at most.
				if (_innerSub != null)
					return;
					
				_innerSub = new InnerSubscription(this);
			}
			
			protected override void OnNewData(IExpression expr, object value)
			{
				//TODO: can we remove this? This subscription does not get data, inner does
			}
		}
		
		class InnerSubscription : Subscription
		{
			OuterSubscription _outSub;
			bool _triggered;
			
			public InnerSubscription(OuterSubscription outSub)
				: base(outSub._expr, outSub._context) 
			{
				_outSub = outSub;
				Init();
			}
			
			protected override void OnNewArguments(Argument[] args)
			{
				if (_outSub == null || _triggered)
					return;
				_triggered = true;
					
				HandleRequest(args);
				
				//we might be in the Ctor.Init function still (yucky), Dispose in Ctor is apparently not good.
				UpdateManager.AddDeferredAction( Dispose );
			}
			
			void HandleRequest(Argument[] args)
			{
				var request = new RouterRequest();
				for (int i=0; i < args.Length; ++i)
				{
					var nvp = args[i].Value as NameValuePair;
					if (nvp == null)
					{
						Fuse.Diagnostics.UserError( "arguments to modifyRoute must be name-value-pairs", this );
						return;
					}
					
					if (!request.AddArgument(nvp.Name,nvp.Value))
						return;
				}
				
				var router = Router.TryFindRouter(_outSub._context.Node);
				if (router == null)
				{
					Fuse.Diagnostics.UserError( "could not find router", this );
					return;
				}
				
				request.MakeRequest(router);
			}
			
			public override void Dispose()
			{
				if (_outSub != null)
				{
					_outSub.DisposeInner(true);
					_outSub = null;
				}
				base.Dispose();
			}
		}
	}
}