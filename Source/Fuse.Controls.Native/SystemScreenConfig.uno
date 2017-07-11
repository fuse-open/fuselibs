using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Controls
{
	/**
		Allows you to control certain aspects of the system UI. On android, this is the visible state of the status and navigation bar. 
		Changes made by outside influences are reset after a time specified by `ResetDelay`. This behavior can be disabled by setting the time to 0.

		# Note
		 * Some properties, like `Show`, set the requested appearance. Some things, such as the status bar and navigation bar on android might be changed by outside elements like the user swiping downwards from the top.
		 * `Show` supplies a generic but reasonable behavior on every system, and is not supposed to be used together with system-specific properties like `ShowNavigation`

		# Example
		The following example allows the user to control the status bar and navigation bar state through three buttons. If the user manually changes the visibility state of the bars, it will be reverted after 2 seconds.
			
			<App>
				<ClientPanel Color="#2196F3">
					<Android.SystemScreenConfig Show="{displayValue}" ResetDelay="2"/>
					<JavaScript>
						var Observable = require("FuseJS/Observable");
						var displayValue = Observable("All");
						function minimal() {
							displayValue.value = "Minimal";
						}
						function full() {
							displayValue.value = "Full";
						}
						function none() {
							displayValue.value = "None";
						}
						module.exports = {
							minimal: minimal,
							full: full,
							none: none,
							displayValue: displayValue
						}
					</JavaScript>
					<StackPanel>
						<Text FontSize="20">
							Status bar and navigation bar example
						</Text>
						<Button Clicked="{minimal}" Text="Minimal" Margin="20"/>
						<Button Clicked="{full}" Text="Full" Margin="20"/>
						<Button Clicked="{none}" Text="None" Margin="20"/>
					</StackPanel>
				</ClientPanel>
			</App>
		@experimental
	*/
	public extern(!Android) class SystemScreenConfig : SystemScreenConfigBase
	{

	}
}
