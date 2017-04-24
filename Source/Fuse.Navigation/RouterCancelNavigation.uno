using Uno;

using Fuse.Triggers.Actions;

namespace Fuse.Navigation
{
	/**
		Cancels a partial navigation on the Router.
	*/
	public class RouterCancelNavigation : TriggerAction
	{
		/** Use this router. If null (the default) then it looks for on in the ancestor nodes */
		public Router Router { get; set; }
		
		protected override void Perform(Node n)
		{
			var useRouter = Router ?? Fuse.Navigation.Router.TryFindRouter(n);
			if (useRouter == null)
			{
				Fuse.Diagnostics.UserError( "Router not set and none could be found", this );
				return;
			}
			
			useRouter.CancelNavigation();
		}
	}
}