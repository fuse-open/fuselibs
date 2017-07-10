using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Controls.Native
{
	/**
		Allows you to control certain aspects of the system UI. On android, this is the visible state of the status and navigation bar. 
		Changes made by outside influences are reset after a time specified by `ResetDelay`. This behavior can be disabled by setting the time to 0.

		# Note
		 * Some properties, like `Show`, set the requested appearance. Some things, such as the status bar and navigation bar on android might be changed by outside elements like the user swiping downwards from the top.
		 * `Show` supplies a generic but reasonable behavior on every system, and is not supposed to be used together with system-specific properties like `ShowNavigation`

		# Example
	*/
	public extern(!Android) class SystemScreenConfig : SystemScreenConfigBase
	{
	    
	}
}
