using Uno;

namespace Fuse.Platform
{
	/** Application App Events.

		This class provides hooks that can be used to get callbacks
		when the system related app events are fired. For example a
		'low memory' warning would qualify as a device event whereas
		input or lifecycle events would not.

	*/
	internal static class AppEvents
	{
		internal static event Action LowMemoryWarning;

		static AppEvents()
		{
			Uno.Platform.CoreApp.ReceivedLowMemoryWarning += OnLowMemoryWarning;
		}

		static void OnLowMemoryWarning(object s, object a)
		{
			var handler = LowMemoryWarning;
			if (handler != null)
				handler();
		}
	}
}
