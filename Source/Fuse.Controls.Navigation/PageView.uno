using Uno;

namespace Fuse.Controls
{
	/**
		A specialized @Navigator that has no standard transitions.
	*/
	public class PageView : Navigator
	{
		public PageView()
		{
			Transition = NavigationControlTransition.None;
			GotoState = NavigatorGotoState.Unchanged;
		}
	}
}
