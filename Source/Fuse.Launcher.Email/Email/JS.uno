using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	/**
		@scriptmodule FuseJS/Email

		Launches the default email app, and starts composing a message.

		You need to add a reference to `"Fuse.Launcher"` in your project file to use this feature.

			var email = require('FuseJS/Email');
			email.compose("to@example.com", "cc@example.com", "bcc@example.com", "subject", "message");

	*/
	[UXGlobalModule]
	public sealed class Email : NativeModule
	{
		static readonly Email _instance;

		public Email()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Email");
			AddMember(new NativeFunction("compose", Compose));
		}

		/** @scriptmethod compose

			Launches the default email app, and starts composing a message.

			compose accepts the following arguments:

			to – The email address(es) of the recipient
			cc – The email address(es) of whom to send a carbon copy
			bcc – The email address(es) of whom to send a blind carbon copy
			subject – The subject of the email
			message – The body text of the email

				var email = require('FuseJS/Email');
				email.compose("to@example.com", "cc@example.com", "bcc@example.com", "subject", "message");

		*/
		public static object Compose(Scripting.Context context, object[] args)
		{
			string to = (string)args[0];
			string cc = (string)args[1];
			string bcc = (string)args[2];
			string subject = (string)args[3];
			string message = (string)args[4];

			Fuse.LauncherImpl.EmailLauncher.LaunchEmail(to, cc, bcc, subject, message);
			return null;
		}
	}
}
