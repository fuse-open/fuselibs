using Uno;
using Uno.Platform;
using Uno.Collections;

using Fuse;
using Fuse.Input;

namespace Fuse.Triggers
{
	public delegate void KeyPressHandler(object sender, Fuse.Input.KeyEventArgs args);

	/**
		Triggers when a specific key is pressed

		For a complete list of supported keys, check out the @Key enum list.

		> Please note that not all platforms support all settings for Key.

		## Example

		The following example will flash the screen blue when the "menu" button
		(which is present on some older Android devices) is pressed:

			<Panel>
				<Rectangle ux:Name="rect" Layer="Background" Color="#F00" />
				<OnKeyPress Key="MenuButton">
					<Change rect.Color="#00F" Duration="0.2" />
				</OnKeyPress>
			</Panel>
	*/
	public class OnKeyPress : Trigger
	{
		/**
			An event that triggers when the specified key is pressed, and can
			be listened to through data-binding.

			## Example

				<Panel>
					<JavaScript>
						module.exports = {
							menuButtonClicked: function() { debug_log("menu button clicked"); }
						}
					</JavaScript>
					<OnKeyPress Key="BackButton" Handler="{menuButtonClicked}" />
				</Panel>
		*/
		public event KeyPressHandler Handler;

		/** The key-code defining what key cause this trigger to fire */
		public Uno.Platform.Key Key { get; set; }

		protected override void OnRooted()
		{
			base.OnRooted();
			Keyboard.KeyPressed.AddGlobalHandler(OnKeyPressed);
		}

		protected override void OnUnrooted()
		{
			Keyboard.KeyPressed.RemoveGlobalHandler(OnKeyPressed);
			base.OnUnrooted();
		}

		internal void OnKeyPressed(object sender, Fuse.Input.KeyEventArgs args)
		{
			if (args.Key == Key)
			{
				Pulse();
				if (Handler != null)
					Handler(this, args);
			}
		}
	}

	/**
		Triggers when the back-button is pressed

		This trigger fires when the user presses either a physical or emulated
		back button on their device.

		> Be aware that @Router also interacts with the back-button. Using both
		> OnBackButton and Router in the same application might lead to
		> undesired behavior.

		## Example

		The following code will flash the screen blue when the back button is
		pressed:

			<Panel>
				<Rectangle ux:Name="rect" Layer="Background" Color="#F00" />
				<OnBackButton>
					<Change rect.Color="#00F" Duration="0.2" />
				</OnBackButton>
			</Panel>
	*/
	public sealed class OnBackButton : OnKeyPress
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			this.Key = Key.BackButton;
		}
	}
}
