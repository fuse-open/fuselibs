using Uno;

namespace Fuse.Platform
{
	public enum ApplicationState
	{
		Uninitialized,
		Background,     // Not rendering
		Foreground,     // Rendering, not interactive
		Interactive,
		Terminating = -1
	}

	/** Application lifecycle events.

		This class provides hooks that can be used to get callbacks
		when the application's state changes, which allows you to
		respond to changes in the environment the app is running in.

		@seealso FuseJS.Lifecycle
	*/
	public static class Lifecycle
	{

		public static ApplicationState State { get { return (ApplicationState)Uno.Platform.CoreApp.State; } }

		public static event Action<ApplicationState> Started;
		public static event Action<ApplicationState> EnteringForeground;
		public static event Action<ApplicationState> EnteringInteractive;
		public static event Action<ApplicationState> ExitedInteractive;
		public static event Action<ApplicationState> EnteringBackground;
		public static event Action<ApplicationState> Terminating;

		static Lifecycle()
		{
			Uno.Platform.CoreApp.Started += OnStarted;
			Uno.Platform.CoreApp.EnteringForeground += OnEnteringForeground;
			Uno.Platform.CoreApp.EnteringInteractive += OnEnteringInteractive;
			Uno.Platform.CoreApp.ExitedInteractive += OnExitedInteractive;
			Uno.Platform.CoreApp.EnteringBackground += OnEnteringBackground;
			Uno.Platform.CoreApp.Terminating += OnTerminating;
		}

		static void OnStarted(Uno.Platform.ApplicationState newState)
		{
			var handler = Started;
			if (handler != null)
				handler((ApplicationState)newState);
		}

		static void OnEnteringForeground(Uno.Platform.ApplicationState newState)
		{
			var handler = EnteringForeground;
			if (handler != null)
				handler((ApplicationState)newState);
		}

		static void OnEnteringInteractive(Uno.Platform.ApplicationState newState)
		{
			var handler = EnteringInteractive;
			if (handler != null)
				handler((ApplicationState)newState);
		}

		static void OnExitedInteractive(Uno.Platform.ApplicationState newState)
		{
			var handler = ExitedInteractive;
			if (handler != null)
				handler((ApplicationState)newState);
		}

		static void OnEnteringBackground(Uno.Platform.ApplicationState newState)
		{
			var handler = EnteringBackground;
			if (handler != null)
				handler((ApplicationState)newState);
		}

		static void OnTerminating(Uno.Platform.ApplicationState newState)
		{
			var handler = Terminating;
			if (handler != null)
				handler((ApplicationState)newState);
		}
	}
}
