using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Controls.Native;

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
	public class SystemScreenConfig : Behavior
	{
		public enum Visibility
		{
			None,
			Minimal,
			Full,
		}

		public enum StatusBarTheme
		{
			Light,
			Dark
		}

		private static SystemScreenConfig rootedConfig = null;

		internal IDisposable _timer;

		protected override void OnRooted()
		{
			base.OnRooted();

			if(rootedConfig==null)
			{
				rootedConfig = this;
			}
			else
			{
				Fuse.Diagnostics.UserError("Only one SystemScreenConfig element should be rooted at once", this);
			}

			if defined(Android)
			{
				SystemScreenConfigAndroidImpl.Init(this);
			}
		}
		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			resetTimer();

			rootedConfig = null;

			if defined(Android)
			{
				SystemScreenConfigAndroidImpl.DeInit();
			}
		}

		internal void resetTimer() 
		{
			if(_timer!=null) 
			{
				_timer.Dispose();
				_timer = null;
			}
		}

		internal void timerDone()
		{
			if defined(Android)
			{
				SystemScreenConfigAndroidImpl.TimerDone();
			}
			resetTimer();
		}

		

		private Visibility _visibility;
		/**
			Provides a sane default behavior for the visibility of system UI on every platform.
		*/
		public Visibility Show 
		{ 
			get
			{
				return _visibility;
			} 
			set
			{
				_visibility = value;
				if defined(Android)
				{
					SystemScreenConfigAndroidImpl.SetShowState(value);
				}
			} 
		}

		private bool _showNavigation = true;
		/**
			Allows you to control the visibility of the navigation bar on Android.
			Please note there is a general rule not to show the navigation bar without also showing the status bar.
		*/
		public bool ShowNavigation 
		{ 
			get
			{
				return _showNavigation;
			}
			set
			{
				_showNavigation = value;
				if defined(Android)
				{
					SystemScreenConfigAndroidImpl.SetNavigationState(value);
				}
			} 
		}

		private bool _showStatus = true;
		/**
			Allows you to control the visibility of the status bar on Android systems.
		*/
		public bool ShowStatus 
		{ 
			get
			{
				return _showStatus;
			}
			set
			{
				_showStatus = value;
				if defined(Android)
				{
					SystemScreenConfigAndroidImpl.SetStatusState(value);
				}
			} 
		}

		private bool _isDim = false;
		public bool IsDim 
		{ 
			get
			{
				return _isDim;
			} 
			set
			{
				_isDim = value;
				if defined(Android)
				{
					SystemScreenConfigAndroidImpl.SetDimState(value);
				}
			} 
		}

		//Sane default of 5 seconds
		private double _resetDelay = 5.0;
		/**
			Sets the time before outside changes to visibility states is reset, defaults to 5.
			Setting the value to 0 disables the reset behavior.
		*/
		public double ResetDelay 
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

		private StatusBarTheme _theme = StatusBarTheme.Dark;
		/**
			Sets if the OS UI should be light or dark
		*/
		public StatusBarTheme Theme
		{
			get
			{
				return _theme;
			}
			set
			{
				_theme = value;
				if defined(Android)
				{
					SystemScreenConfigAndroidImpl.SetLightStatusbarState(value == StatusBarTheme.Light);
				}
			}
		}
	}
}
