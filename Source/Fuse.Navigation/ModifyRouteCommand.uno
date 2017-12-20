using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Navigation
{
	abstract public class RouteModificationCommand : VarArgFunction
	{
		internal RouteModificationCommand() { }
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new OuterSubscription(this, context, listener);
		}
		
		class OuterSubscription : InnerListener, IEventHandler
		{
			internal RouteModificationCommand _expr;
			internal IListener _listener;
			internal IContext _context;
			InnerSubscription _innerSub;
			
			public OuterSubscription( RouteModificationCommand expr, IContext context, IListener listener )
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
				_innerSub.Init(_context);
			}

			//TODO: Remove these, perhaps this class doesn't need to be an InnerListener?
			protected override void OnNewData(IExpression expr, object value) { }
			protected override void OnLostData(IExpression expr) { }
		}
		
		class InnerSubscription : Subscription
		{
			OuterSubscription _outSub;
			bool _triggered;
			
			public InnerSubscription(OuterSubscription outSub)
				: base(outSub._expr)
			{
				_outSub = outSub;
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
				if (!_outSub._expr.ProcessArguments(request, args))
					return;
					
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
		
		internal abstract bool ProcessArguments(RouterRequest request, Argument[] args);
		
		protected class ArgumentArrayAdapter : IArray
		{
			readonly Argument[] _args;

			public ArgumentArrayAdapter(Argument[] args)
			{
				_args = args;
			}

			public int Length { get { return _args.Length; } }
			public object this[int index] { get { return _args[index].Value; } }
		}
	}
	
	/**
		Navigates on the router.
		
		The arguments must be name-value pairs.  It shares the same arguments as the JAvaScript `router.modify` function and the `RouterModify` action. In short the options are:
		
			- how : @ModifyRouteHow
			- path : An array of name-value pairs that specify the path components and their parameter. This syntax differs from the JavaScript interface.
			- relative : Routing relative to the provided node. By default the path will be treated as global.
			- transition : @NavigationGotoMode
			- bookmark : Use a bookmark instead of `path`.
			- style : Transition style for animation
			
		The expression provided to `modifyRoute` is evaluated only when needed. It is expected the bindings will resolve quickly (not bound to a remote lookup for example), otherwise the routing operation will be delayed.
	*/
	[UXFunction("modifyRoute")]
	public sealed class ModifyRouteCommand : RouteModificationCommand
	{
		internal override bool ProcessArguments(RouterRequest request, Argument[] args)
		{
			for (int i=0; i < args.Length; ++i)
			{
				var nvp = args[i].Value as NameValuePair;
				if (nvp == null)
				{
					Fuse.Diagnostics.UserError( "arguments to modifyRoute must be name-value-pairs", this );
					return false;
				}
				
				if (!request.AddArgument(nvp.Name,nvp.Value))
					return false;
			}
			
			return true;
		}
	}
	
	/**
		Goto a full path in the router.
		
		The arguments are name-value pairs that specify the path components and their parameter.
		
		@see ModifyRouteCommand
	*/
	[UXFunction("gotoRoute")]
	public sealed class GotoRouteCommand : RouteModificationCommand
	{
		internal override bool ProcessArguments(RouterRequest request, Argument[] args)
		{
			return request.AddHow( ModifyRouteHow.Goto ) &&
				request.AddPath( new ArgumentArrayAdapter(args) );
		}
	}

	/**
		Push a full path on the router.
		
		@see GotoRouteCommand
	*/
	[UXFunction("pushRoute")]
	public sealed class PushRouteCommand : RouteModificationCommand
	{
		internal override bool ProcessArguments(RouterRequest request, Argument[] args)
		{
			return request.AddHow( ModifyRouteHow.Push ) &&
				request.AddPath( new ArgumentArrayAdapter(args) );
		}
	}
	
}
