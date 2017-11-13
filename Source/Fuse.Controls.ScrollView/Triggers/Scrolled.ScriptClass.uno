using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Triggers
{
	public partial class Scrolled
	{
		static Scrolled()
		{
			ScriptClass.Register(typeof(Scrolled),
				new ScriptMethod<Scrolled>("check", check));
		}
		
		/**
			Checks if the scrollView is currently scrolled to within the target region and then pulses the trigger.
			
			This can be used as part of a self-loading/infinite ScrollView, for example when new content is loaded when the user scrolls to the end. `check()` forces the trigger to fire if it's still in the trigger zone after that new content is added.
			
			@scriptmethod check()
		*/
		static void check(Scrolled s)
		{
			//defer to after main layout to allow added/removed items to have an influence
			UpdateManager.AddDeferredAction(s.Check, UpdateStage.Layout, LayoutPriority.Post);
		}
	}
}
