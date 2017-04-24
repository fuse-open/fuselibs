using Uno.UX;

namespace Fuse.Input.UX
{
	public static class AttachedFocusMembers
	{
		[UXAttachedEventAdder("Focus.Gained")]
		/** Called when a @Visual receives input focus. */
		public static void AddFocusGainedHandler(Visual node, FocusGainedHandler handler)
		{
			Focus.Gained.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Focus.Gained")]
		public static void RemoveFocusGainedHandler(Visual node, FocusGainedHandler handler)
		{
			Focus.Gained.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Focus.Lost")]
		/** Called when a @Visual loses input focus. */
		public static void AddFocusLostHandler(Visual node, FocusLostHandler handler)
		{
			Focus.Lost.AddHandler(node, handler);	
		}

		[UXAttachedEventRemover("Focus.Lost")]
		public static void RemoveFocusLostHandler(Visual node, FocusLostHandler handler)
		{
			Focus.Lost.RemoveHandler(node, handler);
		}
	}
}