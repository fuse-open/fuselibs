using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse;
using Fuse.Scripting;

namespace Fuse.Shortcut
{
	/**
		@scriptmodule FuseJS/Shortcut

		This module allows you to shows menu items when pressing App Icon on the device home screen.
		This feature refer to the [home screen actions](https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/home-screen-actions/) on iOS and [App Shortcut](https://developer.android.com/guide/topics/ui/shortcuts.html) on Android (introduced in Android 7.1 / API Level 25).

		You need to add a reference to `"Fuse.Shortcut"` in your project file to use this feature.

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		## Usage

		The following example shows how create shortcut:
		```xml
				<App>
					<JavaScript>

						var Observable = require("FuseJS/Observable")
						var selectedShortcut = new Observable("-")

						var shortcut = require("FuseJS/Shortcut");
						shortcut.registerShortcuts([
							{
								id: 'compose',
								title: "Compose",
								icon: "assets/images/compose.png"
							},
							{
								id: 'profile',
								title: "Profile",
								icon: "assets/images/user.png"
							},
							{
								id: 'book_store',
								title: "Book Store",
								icon: "assets/images/book.png"
							}
						])

						shortcut.on('shortcutClicked', (type) => {
							selectedShortcut.value = type;
						})

						module.exports = {
							selectedShortcut
						}

					</JavaScript>
					<StackPanel Margin="20">
						<Text Value="Selected Shortcut: {selectedShortcut}" />
					</StackPanel>
				</App>

		Note that on the `registerShortcuts` method accepts array of json objects with the following properties:
		* id, id of the shortcut, and will be passed on the `shortcutClicked` callback when particular shortcut get clicked. This property is mandatory
		* title, to display menu title. This property is mandatory
		* subtitle, to display sub title (displayed below the title on iOS). This property is optional
		* icon, to display icon beside the menu title, value of the icon is a local image path (i.e asset path) not a url and must be registered as a Bundle. More info about Bundle [here.](/docs/assets/bundle). This property is optional
	*/
	[UXGlobalModule]
	public class ShortcutModule : NativeEventEmitterModule
	{
		static readonly ShortcutModule _instance;
		public ShortcutModule() : base(true, "shortcutClicked")
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Shortcut");

			AddMember(new NativeFunction("registerShortcuts", RegisterShortcuts));
		}

		object RegisterShortcuts(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				var shortcuts = Json.Stringify(args[0]);
				ShortcutProvider.RegisterShortcuts(shortcuts, MenuClicked);
			}
			return null;
		}

		void MenuClicked(string shortcutType)
		{
			Emit("shortcutClicked", shortcutType);
		}

	}
}
