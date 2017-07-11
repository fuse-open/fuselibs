using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	/**
		TODO write docs please
	*/
	public extern(Android) class SystemScreenConfig : SystemScreenConfigBase
	{
		protected override void OnRooted()
		{
			base.OnRooted();

			SystemUiVisibility.VisibilityChanged += visibilityChanged;
		}
		protected override void OnUnrooted()
		{
			base.OnUnrooted();

			SystemUiVisibility.VisibilityChanged -= visibilityChanged;
		}

		private SystemUiVisibility.Flag _wantedFlags = SystemUiVisibility.Flag.None;

		private extern(Android) void visibilityChanged(SystemUiVisibility.Flag newFlag) 
		{
			SystemUiVisibility.Flag mask = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation | SystemUiVisibility.Flag.LowProfile;
			SystemUiVisibility.Flag otherFlags = newFlag & (~mask);

			SystemUiVisibility.Flag actualFlags = newFlag & mask;

			//Reset the timer anyways, in case the state changed to what we want
			resetTimer();
			//Was things changed due to an outside influence?
			if(actualFlags != _wantedFlags && _resetDelay != Float.ZeroTolerance) //Cheeky 
			{
				_timer = Timer.Wait(_resetDelay, timerDone);
			}
		}

		private void timerDone()
		{
			SystemUiVisibility.Flags = _wantedFlags;
			resetTimer();
		}

		private Visibility _visibility;
		/**
			Provides a sane default behavior for the visibility of system UI on every platform.
		*/
		public override Visibility Show 
		{ 
			get
			{
				return _visibility;
			} 
			set
			{
				_visibility = value;
				switch(value)
				{
					case Visibility.None:
						SystemUiVisibility.Flags = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation;
						_wantedFlags = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation;
					break;
					case Visibility.Minimal:
						SystemUiVisibility.Flags = SystemUiVisibility.Flag.HideNavigation;
						_wantedFlags = SystemUiVisibility.Flag.HideNavigation;
					break;
					case Visibility.Full:
						SystemUiVisibility.Flags = SystemUiVisibility.Flag.None;
						_wantedFlags = SystemUiVisibility.Flag.None;
					break;
				}
			} 
		}

		private bool _showNavigation = true;
		/**
			Allows you to control the visibility of the navigation bar on Android.
			Please note there is a general rule not to show the navigation bar without also showing the status bar.
		*/
		public override bool ShowNavigation 
		{ 
			get
			{
				return _showNavigation;
			}
			set
			{
				if(value)
				{
					_wantedFlags = _wantedFlags ^ SystemUiVisibility.Flag.HideNavigation;
					SystemUiVisibility.Flags = SystemUiVisibility.Flags ^ SystemUiVisibility.Flag.HideNavigation;
				}
				else
				{
					_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.HideNavigation;
					SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.HideNavigation;
				}
				_showNavigation = value;
			} 
		}

		private bool _showStatus = true;
		/**
			Allows you to control the visibility of the status bar on Android systems.
		*/
		public override bool ShowStatus 
		{ 
			get
			{
				return _showStatus;
			}
			set
			{
				if(value)
				{
					_wantedFlags = _wantedFlags ^ SystemUiVisibility.Flag.Fullscreen;
					SystemUiVisibility.Flags = SystemUiVisibility.Flags ^ SystemUiVisibility.Flag.Fullscreen;
				}
				else
				{
					_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.Fullscreen;
					SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.Fullscreen;
				}
				_showStatus = value;
			} 
		}

		private bool _isDim = false;
		public override bool IsDim 
		{ 
			get
			{
				return _isDim;
			} 
			set
			{
				if(value)
				{
					_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.LowProfile;
					SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.LowProfile;
				}
				else
				{
					_wantedFlags = _wantedFlags ^ SystemUiVisibility.Flag.LowProfile;
					SystemUiVisibility.Flags = SystemUiVisibility.Flags ^ SystemUiVisibility.Flag.LowProfile;
				}
				_isDim = value;
			} 
		}

		private double _resetDelay = 5.0;
		/**
			Sets the time before outside changes to visibility states is reset.
			Setting the value to 0 disables the reset behavior.
		*/
		public override double ResetDelay 
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
	}
}
