using Uno;
using Uno.UX;

using Fuse.Storage;
using Fuse.Triggers;
using Fuse.Triggers.Actions;
using Fuse.Scripting;

namespace Fuse
{
	public class SignInArgs : EventArgs, IScriptEvent
	{
		bool _status;
		string _errorMessage;
		string _userId;
		string _lastName;
		string _firstName;
		string _email;
		string _user;
		string _password;

		public SignInArgs(bool result, string msg)
		{
			_status = result;
			_errorMessage = msg;
			ComposeUserDataFromUserSettings();
		}
		void IScriptEvent.Serialize(IEventSerializer s)
		{
			Serialize(s);
		}

		void ComposeUserDataFromUserSettings()
		{
			// retrieve user data that has been saved in NSUserDefaults
			if defined(iOS)
			{
				_userId = IOSUserSettingsImpl.GetStringValue("platformSignIn.userId");
				_lastName = IOSUserSettingsImpl.GetStringValue("platformSignIn.lastName");
				_firstName = IOSUserSettingsImpl.GetStringValue("platformSignIn.firstName");
				_email = IOSUserSettingsImpl.GetStringValue("platformSignIn.email");
				_user = IOSUserSettingsImpl.GetStringValue("platformSignIn.user");
				_password = IOSUserSettingsImpl.GetStringValue("platformSignIn.password");
			}
			// retrieve user data that has been saved in SharedPreferences
			if defined(Android)
			{
				_userId = AndroidUserSettingsImpl.GetStringValue("platformSignIn.userId");
				_lastName = AndroidUserSettingsImpl.GetStringValue("platformSignIn.lastName");
				_firstName = AndroidUserSettingsImpl.GetStringValue("platformSignIn.firstName");
				_email = AndroidUserSettingsImpl.GetStringValue("platformSignIn.email");
			}
		}

		virtual void Serialize(IEventSerializer s)
		{
			s.AddBool("status", _status);
			s.AddString("errorMessage", _errorMessage);
			s.AddString("userId", _userId);
			s.AddString("firstName", _firstName);
			s.AddString("lastName", _lastName);
			s.AddString("email", _email);
			s.AddString("user", _user);
			s.AddString("password", _password);
		}
	}

	public delegate void SignInEventHandler(object sender, SignInArgs args);

	/**
		This is trigger action for taking Platform SignIn. Platform SignIn is a SignIn mechanism that use `Sign In With Apple` on iOS and `Google SignIn` on Android.

		Platform SignIn is only available on the mobile target platform (iOS and Android).

		You need to add a reference to `"Fuse.Auth"` in your project file to use this feature.

		> For more information on what are the pre-request when implementing `Sign In With Apple` or `Google Sign In`, you can check the documentation on the apple developer website or android developer website
		> for iOS add "SystemCapabilities": { "SignInWithApple":true }  in the unoproj file.

		## Example

			The following example shows how to use it:

				```XML
					<App>
						<JavaScript>
							var Observable = require('FuseJS/Observable');
							var status = Observable();
							var statusMessage = Observable();

							module.exports = {
								resultHandler: function(result) {
									console.dir(result);
									// result is json object containing these properties :
									// status -> boolean value indicating whether sign in action success or fail
									// email -> user email that has been sign in / sign up
									// firstName -> User firstname
									// lastName -> User Lastname
									// userId -> User uniqe Id
								}
							}
						</JavaScript>
						<Button Text="Sign In">
							<Clicked>
								<PlatformSignIn Handler="{resultHandler}" />
							</Clicked>
						</Button>
					</App
				```

		> When the callback handler is fired for the first time and the result object of `status` property is true, save those logged user information immediately to the server especially on iOS,
		>  because as stated in the documentation on the apple website, the Sign In With Apple will only send userId informataion the next time user do the authentication again
	*/
	public class PlatformSignIn : TriggerAction
	{
		Node _target;

		/**
		Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event SignInEventHandler Handler;

		extern(!MOBILE)
		protected override void Perform(Node n)
		{
			Fuse.Diagnostics.UserWarning("Platform SignIn is not implemented for this platform", this);
		}

		extern(MOBILE)
		protected override void Perform(Node n)
		{
			_target = n;
			if defined(Android)
				SignInWithGoogle.SignIn(AuthSuccess, AuthFailed);
			if defined(iOS)
				SignInWithApple.SignIn(AuthSuccess, AuthFailed);
		}

		void AuthSuccess()
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new SignInArgs(true, ""));
			}
		}

		void AuthFailed(string message)
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new SignInArgs(false, message));
			}
		}
	}
}