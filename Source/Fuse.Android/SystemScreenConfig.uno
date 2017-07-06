using Uno;
using Uno.Collections;
using Fuse.Platform;

namespace Fuse.Android
{
	/**
		Allows you to control the state of the status bar and navigation bar on Android systems

		# Note

		 * You are not allowed to have the navigation bar visible alone. This is a general rule for Android, and is therefore enforced here
		 * The user can change this state themselves, for example through swiping down from the top of the display.

		# Example

		The following example allows the user to control the status bar and navigation bar state through three buttons.

			<App>
				<ClientPanel Color="#2196F3">
					<Android.SystemScreenConfig Show="{displayValue}" />
					<JavaScript>
						var Observable = require("FuseJS/Observable");
						var displayValue = Observable("All");
						function status() {
							displayValue.value = "Status";
						}
						function all() {
							displayValue.value = "All";
						}
						function none() {
							displayValue.value = "None";
						}
						module.exports = {
							status: status,
							all: all,
							none: none,
							displayValue: displayValue
						}
					</JavaScript>
					<StackPanel>
						<Text FontSize="20">
							Status bar and navigation bar example
						</Text>
						<Button Clicked="{status}" Text="Status" Margin="20"/>
						<Button Clicked="{all}" Text="All" Margin="20"/>
						<Button Clicked="{none}" Text="None" Margin="20"/>
					</StackPanel>
				</ClientPanel>
			</App>
	*/
	public class SystemScreenConfig : Behavior
	{
		public enum Visibility 
		{
			None,
			Status,
			All
		}

		public Visibility Show
		{
			get 
			{
				if defined(Android)
				{
					if((SystemUiVisibility.Flags & (SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation)) != 0) 
					{
						return Visibility.None;
					}
					else if((SystemUiVisibility.Flags & SystemUiVisibility.Flag.HideNavigation) != 0) 
					{
						return Visibility.Status;
					}
					else 
					{
						return Visibility.All;
					}
				} 
				else 
				{
					return Visibility.None;
				}
			}
			set 
			{
				if defined(Android)
				{ 
					switch(value) 
					{
						case Visibility.None:
							SystemUiVisibility.Flags = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation;
						break;
						case Visibility.Status:
							SystemUiVisibility.Flags = SystemUiVisibility.Flag.HideNavigation;
						break;
						case Visibility.All:
							SystemUiVisibility.Flags = SystemUiVisibility.Flag.None;
						break;
					}
				}
			}
		}
	}

}
