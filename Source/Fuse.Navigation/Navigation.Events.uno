using Uno;
using Uno.UX;

namespace Fuse.Navigation
{
	public enum NavigationMode
	{
		Switch,
		Bypass,
		Seek,
	}

	public class NavigationArgs: EventArgs
	{
		public NavigationMode Mode { get; private set; }
		public double Progress { get; private set; }
		public double PreviousProgress { get; private set; }

		public NavigationArgs(double progress, double prevProgress,
			NavigationMode mode = NavigationMode.Switch )
		{
			Progress = progress;
			PreviousProgress = prevProgress;
			Mode = mode;
		}
	}
	
	public delegate void NavigationHandler(object sender, NavigationArgs state);
	
	public enum NavigationState
	{
		Stable,
		Seek,
		Transition,
	}
}
