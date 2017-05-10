using Uno;
using Uno.UX;

namespace Fuse.Triggers
{
	/*
		Derived classes using WhileTrigger must exclusively use the set functions here
		to change activation status, otherwise it will not support `Invert` correctly.
	*/
	public abstract class WhileTrigger : Trigger
	{
		/** Inverts the trigger so it will be active when it would normally be inactive, and vice versa.
		*/
		public bool Invert { get; set; }

		protected void SetActive(bool on)
		{
			if (on != Invert)
				Activate();
			else
				Deactivate();
		}
		
		/** Call in situations where the bypassing is forced. This should be rare since during rooting the normal bypass mechanism of the trigger will apply. */
		protected void BypassSetActive(bool on)
		{
			if (on != Invert)
				BypassActivate();
			else
				BypassDeactivate();
		}
	}
}
