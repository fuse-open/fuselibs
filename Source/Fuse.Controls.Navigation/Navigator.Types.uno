using Uno;

using Fuse.Navigation;

namespace Fuse.Controls
{
	public enum NavigatorGotoState
	{
		/** Does not modify any Visual state on a Goto */
		Unchanged,
		/** Brings the new current visual to the front */
		BringToFront,
	}
	
	class NavigatorSwitchedArgs : VisualEventArgs
	{
		public String OldPath, NewPath;
		public String OldParameter, NewParameter;
		public Visual OldVisual, NewVisual;
		public RoutingOperation Operation;
		public string OperationStyle;
		public NavigationGotoMode Mode;
		
		public NavigatorSwitchedArgs( Visual v ) 
			: base(v)
		{
		}
	}
	
	delegate void NavigationSwitchedHandler(object sender, NavigatorSwitchedArgs args);
	
	/**
		In order of most restrictve (except Default) to least restrictive (which imply the less restrictve ones as well).
	*/
	public enum ReuseType
	{
		/** Use the Navigator setting */
		Default = 0,
		/** the page instances are never reused */
		None,
		/** removed pages may be used */
		Removed,
		/** any inactive pages may be used */
		Inactive,
		/** any page, even the current one in replace mode */
		Replace,
		/** any page can be reused, even the current one */
		Any,
	}

	/**
		Specifies how pages are removed from navigation (the child is actually removed from the UI tree).
	*/
	public enum RemoveType
	{
		/** Use the Navigator setting */
		Default = 0,
		/**  Pages are not removed. This is generally suitable only for a liberal `Reuse` property, such as `Inactive` or `Any` */
		None,
		/** When the list of pages is cleared, such as with a Goto */
		Cleared,
		/** As soon as the page is released (typically when no longer visible). */
		Released,
	}
	
}
