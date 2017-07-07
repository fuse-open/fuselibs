using Uno;
using Uno.UX;
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
		private enum ActualVisibility
		{
			None,
			Status,
			All,
			Navigation
		}

		public SystemScreenConfig() 
		{
			if defined(Android) 
			{
				SystemUiVisibility.VisibilityChanged += visibilityChanged;
			}
		}

		private Timer _timer;

		private extern(Android) void visibilityChanged(SystemUiVisibility.Flag newFlag) 
		{
			if((newFlag & (SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation)) == 0) 
			{
				_actualShow = ActualVisibility.All;
			}
			else if((newFlag & SystemUiVisibility.Flag.HideNavigation) != 0) 
			{
				_actualShow = ActualVisibility.Status;
			}
			else if((newFlag & SystemUiVisibility.Flag.Fullscreen) != 0) 
			{
				_actualShow = ActualVisibility.Navigation;
			}
			else 
			{
				_actualShow = ActualVisibility.None;
			}

			//Reset the timer anyways, in case the state changed to what we want
			if(_timer!=null) 
			{
				_timer.Stop();
				_timer = null;
			}
			//Was things changed due to an outside influence?
			if((int)_show != (int)_actualShow) //Cheeky 
			{
				_timer = Timer.Wait(_resetDelay, timerDone);
			}
		}

		private extern(Android) void timerDone()
		{
			setShow(_show);
		}

		private ActualVisibility _actualShow = ActualVisibility.None;

		private float _resetDelay = 5f;
		public float ResetDelay
		{
			get
			{
				return _resetDelay;
			}
			set
			{
				_resetDelay = value;
			}
		}

		private Visibility _show = Visibility.None;
		public Visibility Show
		{
			get 
			{
				return _show;
			}
			set 
			{
				if defined(Android)
				{ 
					_show = value;
					setShow(value);
				}
			}
		}

		private extern(Android) void setShow(Visibility visibility) 
		{
			switch(visibility) 
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
