using Uno;
using Uno.Collections;
using Fuse.Platform;

namespace Fuse.Android
{
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
