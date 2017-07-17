using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Navigation
{
	/**
		Finds a router from the current location.
		
		This can be used to get access to a router in JavaScript. This assume that a @Router has been
		declared somewhere higher in the UX tree (it need not be in the same file).
		
			<Page>
				<JavaScript dep:router="findRouter()">
					exports.go = function() {
						router.goto( "anotherPageName" )
					}
				</JavaScript>

				<Button Alignment="Center" Clicked="{go}"/>
			</Page>
	*/
	[UXFunction("findRouter")]
	public sealed class FindRouter : Fuse.Reactive.Expression
	{
		[UXConstructor]
		public FindRouter()
		{
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new Subscription(this, context.Node, listener);
		}
		
		class Subscription : IDisposable
		{
			FindRouter _expr;
			IListener _listener;
			
			public Subscription(FindRouter expr, Node origin, IListener listener)
			{
				_expr = expr;
				_listener = listener;
				
				var router = Router.TryFindRouter(origin);
				if (router == null)
					Fuse.Diagnostics.UserError( "unable to find a router", this );
				else
					listener.OnNewData(_expr, router);
			}

			
			public void Dispose()
			{
				_expr = null;
				_listener = null;
			}
		}
	}
}
