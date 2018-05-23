using Uno;
using Fuse.Platform;

namespace Fuse
{
	extern (MOBILE) internal class MobileBootstrapping
	{
		static bool _isInited;
		public static void Init()
		{
			if (_isInited) return;
			_isInited = true;

			Fuse.Platform.Lifecycle.Started += OnStarted;
			Fuse.Platform.Lifecycle.EnteringForeground += OnEnterForeground;
			Fuse.Platform.Lifecycle.EnteringInteractive += OnEnterInteractive;
			Fuse.Platform.Lifecycle.ExitedInteractive += OnExitInteractive;
			Fuse.Platform.Lifecycle.Terminating += OnTerminating;

			if defined(Mobile && !Library)
			{
				Uno.Platform.EventSources.HardwareKeys.KeyDown += KeyboardBootstrapper.OnKeyPressed;
				Uno.Platform.EventSources.HardwareKeys.KeyUp += KeyboardBootstrapper.OnKeyReleased;
			}
		}

		static void OnTerminating(Fuse.Platform.ApplicationState state)
		{
			Fuse.Platform.Lifecycle.Started -= OnStarted;
			Fuse.Platform.Lifecycle.EnteringForeground -= OnEnterForeground;
			Fuse.Platform.Lifecycle.EnteringInteractive -= OnEnterInteractive;
			Fuse.Platform.Lifecycle.ExitedInteractive -= OnExitInteractive;
			Fuse.Platform.Lifecycle.Terminating -= OnTerminating;
		}

		static void OnStarted(Fuse.Platform.ApplicationState state)
		{
			Uno.Platform.CoreApp.Current.Load();
		}

		static void OnEnterForeground(Fuse.Platform.ApplicationState state)
		{
			Uno.Platform.Displays.MainDisplay.TicksPerSecond = 20;
		}

		static void OnEnterInteractive(Fuse.Platform.ApplicationState state)
		{
			Uno.Platform.Displays.MainDisplay.TicksPerSecond = 60;
		}

		static void OnExitInteractive(Fuse.Platform.ApplicationState state)
		{
			Uno.Platform.Displays.MainDisplay.TicksPerSecond = 20;
		}
	}
}
