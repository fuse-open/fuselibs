using Fuse.Animations;

namespace Fuse.Triggers
{
	/**
		Triggers if run on an iOS device

		## Example

		This example sets a panel's background color to green if the app is
		running on iOS. If the app is ran on another platform, it will be red:

			<Panel ux:Name="panel" Background="#F00" >
				<iOS>
					<Change panel.Background="#0F0" />
				</iOS>
			</Panel>
	*/
	public class iOS: Trigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			if defined(iOS)
			{
				Activate();
			}
		}

		protected override void OnUnrooted()
		{
			if defined(iOS)
			{
				Deactivate();
			}
			base.OnUnrooted();
		}
	}

	/**
		Triggers if run on an Android device

		## Example

		This example sets a panel's background color to green if the app is
		running on Android. If the app is ran on another platform, it will be
		red:

			<Panel ux:Name="panel" Background="#F00" >
				<Android>
					<Change panel.Background="#0F0" />
				</Android>
			</Panel>
	*/
	public class Android: Trigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			if defined(Android)
			{
				Activate();
			}
		}

		protected override void OnUnrooted()
		{
			if defined(Android)
			{
				Deactivate();
			}
			base.OnUnrooted();
		}
	}
}
