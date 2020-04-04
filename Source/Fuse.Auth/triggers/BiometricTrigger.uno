using Uno;
using Uno.UX;

using Fuse.Triggers;
using Fuse.Triggers.Actions;

namespace Fuse
{
	/**
		Triggers if device has biometric sensor and user has already configure it

		## Example

			<Panel>
				<SupportBiometric>
					<Button Text="Sign In With Biometric">
						<Clicked>
							<Authenticate />
						</Clicked>
					</Button>
				</SupportBiometric>
			</Panel>
	*/
	public class SupportBiometric: Trigger
	{
		protected override void OnRooted()
		{
			if defined(Android)
			{
				if (AndroidBiometric.IsSupported())
					Activate();
			}
			if defined(iOS)
			{
				if (IOSBiometric.IsSupported())
					Activate();
			}
			base.OnRooted();
		}

		protected override void OnUnrooted()
		{
			if defined(Android)
			{
				if (AndroidBiometric.IsSupported())
					Deactivate();
			}
			if defined(iOS)
			{
				if (IOSBiometric.IsSupported())
					Deactivate();
			}
			base.OnUnrooted();
		}
	}
}