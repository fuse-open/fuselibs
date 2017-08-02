using Fuse.Controls.Native;

namespace Fuse.Controls.Native
{
	extern(Android) internal class SystemScreenConfigAndroidImpl
	{
		private static SystemUiVisibility.Flag _wantedFlags = SystemUiVisibility.Flag.None;
		private static SystemScreenConfig config;

		public static void Init(SystemScreenConfig config)
		{
			SystemScreenConfigAndroidImpl.config = config;
			SystemUiVisibility.VisibilityChanged += VisibilityChanged;
		}

		public static void DeInit()
		{
			SystemUiVisibility.VisibilityChanged -= VisibilityChanged;
			SystemScreenConfigAndroidImpl.config = null;
		}

		public static void TimerDone()
		{
			SystemUiVisibility.Flags = _wantedFlags;
			debug_log "Settingh state";
		}

		public static void SetShowState(SystemScreenConfig.Visibility state)
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

		public static void SetStatusState(bool val)
		{
			if(val)
			{
				_wantedFlags &= ~SystemUiVisibility.Flag.Fullscreen;
				SystemUiVisibility.Flags &= ~SystemUiVisibility.Flag.Fullscreen;
			}
			else
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.Fullscreen;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.Fullscreen;
			}
		}

		public static void SetLightStatusbarState(bool isLight)
		{
			if(isLight)
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.LightStatusBar;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.LightStatusBar;
			}
			else
			{
				_wantedFlags &= ~SystemUiVisibility.Flag.LightStatusBar;
				SystemUiVisibility.Flags &= ~SystemUiVisibility.Flag.LightStatusBar;
			}
		}

		public static void SetNavigationState(bool val)
		{
			if(val)
			{
				_wantedFlags &= ~SystemUiVisibility.Flag.HideNavigation;
				SystemUiVisibility.Flags &= ~SystemUiVisibility.Flag.HideNavigation;
			}
			else
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.HideNavigation;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.HideNavigation;
			}
		}

		public static void SetDimState(bool val)
		{
			if(val)
			{
				_wantedFlags = _wantedFlags | SystemUiVisibility.Flag.LowProfile;
				SystemUiVisibility.Flags = SystemUiVisibility.Flags | SystemUiVisibility.Flag.LowProfile;
			}
			else
			{
				_wantedFlags &= ~SystemUiVisibility.Flag.LowProfile;
				SystemUiVisibility.Flags &= ~SystemUiVisibility.Flag.LowProfile;
			}
		}

		private static extern(Android) void VisibilityChanged(SystemUiVisibility.Flag newFlag) 
		{
			//Only modify flags we set, to avoid weirdness
			SystemUiVisibility.Flag mask = SystemUiVisibility.Flag.Fullscreen | 
											SystemUiVisibility.Flag.HideNavigation | 
											SystemUiVisibility.Flag.LowProfile | 
											SystemUiVisibility.Flag.LightStatusBar;
			
			SystemUiVisibility.Flag otherFlags = newFlag & (~mask);

			SystemUiVisibility.Flag actualFlags = newFlag & mask;

			//Reset the timer anyways, in case the state changed to what we want
			config.resetTimer();
			//Was things changed due to an outside influence?
			if(actualFlags != _wantedFlags && config.ResetDelay >= 0) //Cheeky 
			{
				config._timer = Timer.Wait(config.ResetDelay, config.timerDone);
			}
		}
	}
}
