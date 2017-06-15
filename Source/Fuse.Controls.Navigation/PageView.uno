using Uno;

namespace Fuse.Controls
{
	/**
		A @Navigator without standard transitions.
		This is convenient when you want to provide custom transitions for all pages.
		
		`<PageView />` is equivalent to the following:
		
			<Navigator Transition="None" GotoState="Unchanged" />
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
