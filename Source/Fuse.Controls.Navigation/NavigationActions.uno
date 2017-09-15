using Fuse.Controls;

namespace Fuse.Triggers.Actions
{
	/**
		For navigation this indicates the page (Visual) is no longer required and can be reused, or discarded,
		by the container.
		
			<ExitingAnimation>
				<Move X="1" RelativeTo="Size" Duration="0.3"/>
				<ReleasePage AtProgress="1"/>
			</ExitingAnimation>
		
		This is currently only necessary in a `Navigator` and `PageView`. You can safely call it on transitions used potentially also in a `PageControl`.
	*/
	public class ReleasePage : TriggerAction 
	{
		Visual _pendVisual;
		Navigator _pendNavigator;
		protected override void Perform(Node n) 
		{
			_pendVisual = n.FindByType<Visual>();
			_pendNavigator = _pendVisual == null ? null : _pendVisual.Parent as Navigator;
			if (_pendVisual == null || _pendNavigator == null)
			{
				Fuse.Diagnostics.UserError( "Requires a Visual and Navigator parent", this );
				return;
			}
			
			//this must be deferred in case it happens at a critical time like rooting. It's most likely an
			//error on the user's part, but we must account for that
			UpdateManager.AddDeferredAction(DeferredRelease);
		}
		
		void DeferredRelease()
		{
			if (_pendNavigator == null || _pendVisual == null)
				return;
				
			_pendNavigator.ReleasePage(_pendVisual);
			_pendNavigator = null;
			_pendVisual = null;
		}
	}
}