using Uno;

namespace Fuse.Platform
{
	/** InterApp events.

		@seealso Fuse.Reactive.FuseJS.InterApp
	*/
	public static class InterApp
	{
		/** Triggered when the application receives an URI from another app. */
		public static event Action<string> ReceivedURI;

		static InterApp()
		{
			Uno.Platform.EventSources.InterAppInvoke.ReceivedURI += OnReceivedURI;
		}

		static void OnReceivedURI(object sender, string uri)
		{
			// Sender is always null at the time of writing this so
			// we don't use it.
			var handler = ReceivedURI;
			if (handler != null)
				handler(uri);
		}
	}
}
