using Fuse.Controls.Native;

namespace Fuse.Controls.Native
{
	extern(Android) internal class SystemScreenConfigAndroidImpl
	{
		private static SystemUiVisibility.Flag _wantedFlags = SystemUiVisibility.Flag.None;
		private static SystemScreenConfig config;

		public static void init(SystemScreenConfig config)
		{
			SystemScreenConfigAndroidImpl.config = config;
			SystemUiVisibility.VisibilityChanged += visibilityChanged;
		}

		public static void deInit()
		{
			SystemUiVisibility.VisibilityChanged -= visibilityChanged;
			SystemScreenConfigAndroidImpl.config = null;
		}

		public static void timerDone()
		{
			SystemUiVisibility.Flags = _wantedFlags;
		}

		public static void setShowState(SystemScreenConfig.Visibility state)
		{
			switch(state)
			{
				case SystemScreenConfig.Visibility.None:
					SystemUiVisibility.Flags = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation;
					_wantedFlags = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation;
				break;
				case SystemScreenConfig.Visibility.Minimal:
					SystemUiVisibility.Flags = SystemUiVisibility.Flag.HideNavigation;
					_wantedFlags = SystemUiVisibility.Flag.HideNavigation;
				break;
				case SystemScreenConfig.Visibility.Full:
					SystemUiVisibility.Flags = SystemUiVisibility.Flag.None;
					_wantedFlags = SystemUiVisibility.Flag.None;
				break;
			}
		}

		public static void setStatusState(bool val)
		{
			if(val)
			{
				_wantedFlags = _wantedFlags ^ SystemUiVisibility.Flag.Fullscreen;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags ^ SystemUiVisibility.Flag.Fullscreen;
			}
			else
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.Fullscreen;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.Fullscreen;
			}
		}

		public static void setNavigationState(bool val)
		{
			if(val)
			{
				_wantedFlags = _wantedFlags ^ SystemUiVisibility.Flag.HideNavigation;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags ^ SystemUiVisibility.Flag.HideNavigation;
			}
			else
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.HideNavigation;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.HideNavigation;
			}
		}

		public static void setDimState(bool val)
		{
			if(val)
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.LowProfile;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.LowProfile;
			}
			else
			{
				_wantedFlags = _wantedFlags ^ SystemUiVisibility.Flag.LowProfile;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags ^ SystemUiVisibility.Flag.LowProfile;
			}
		}

		private static extern(Android) void visibilityChanged(SystemUiVisibility.Flag newFlag) 
		{
			SystemUiVisibility.Flag mask = SystemUiVisibility.Flag.Fullscreen | SystemUiVisibility.Flag.HideNavigation | SystemUiVisibility.Flag.LowProfile;
			SystemUiVisibility.Flag otherFlags = newFlag & (~mask);

			SystemUiVisibility.Flag actualFlags = newFlag & mask;

			//Reset the timer anyways, in case the state changed to what we want
			config.resetTimer();
			//Was things changed due to an outside influence?
			if(actualFlags != _wantedFlags && config.ResetDelay > 0.0001f) //Cheeky 
			{
				config._timer = Timer.Wait(config.ResetDelay, timerDone);
			}
		}
	}
}
