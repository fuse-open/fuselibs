using Uno;
using Uno.UX;
using Fuse;
using Fuse.Scripting;
using Uno.Threading;

namespace Fuse
{
	[UXGlobalModule]
	/**
		Javascript Module for taking Platform SignIn. Platform SignIn is a SignIn mechanism that use `Sign In With Apple` on iOS and `Google SignIn` on Android.

		Platform SignIn is only available on the mobile target platform (iOS and Android).

		You need to add a reference to `"Fuse.Auth"` in your project file to use this feature.

		> For more information on what are the pre-request when implementing `Sign In With Apple` or `Google Sign In`, you can check the documentation on the apple developer website or android developer website
		> for iOS add "SystemCapabilities": { "SignInWithApple":true }  in the unoproj file.

		## Example

			The following example shows how to use it:

				```XML
					<App>
						<JavaScript>
							var Auth = require('useJS/Auth');

							function doSignIn() {
								Auth.signIn().then(function(result) {
									// result is json object containing these properties :
									// email -> user email that has been sign in / sign up
									// firstName -> User firstname
									// lastName -> User Lastname
									// userId -> User uniqe Id
								}, function (ex) {
									// failed login
								})
							}
							Auth.hasSignedIn().then(function (result) {
								if (result) {
									// user has already sign in
								}
							})

							module.exports = {
								doSignIn
							}

						</JavaScript>
						<Button Text="Sign In">
							<Clicked>
								<Callback Handler="{doSignIn}" />
							</Clicked>
						</Button>
					</App
				```

		> When the callback handler is fired for the first time and the result object of `status` property is true, save those logged user information immediately to the server especially on iOS,
		>  because as stated in the documentation on the apple website, the Sign In With Apple  will only send userId informataion the next time user do the authentication again

	*/
	public class SignInModule : NativeModule
	{
		static readonly SignInModule _instance;

		public SignInModule()
		{
			if (_instance != null) return;

			_instance = this;
			Resource.SetGlobalKey(_instance, "FuseJS/Auth");
			AddMember(new NativePromise<bool, bool>("hasSignedIn", HasSignedIn));
			AddMember(new NativePromise<LoginInformation, Scripting.Object>("signIn", SignIn, Converter));
		}

		static Future<bool> HasSignedIn(object[] args)
		{
			var p = new Promise<bool>();
			if defined (iOS)
				SignInWithApple.HasSignedIn(p);
			if defined (Android)
				SignInWithGoogle.HasSignedIn(p);
			return p;
		}

		static Future<LoginInformation> SignIn(object[] args)
		{
			var p = new Promise<LoginInformation>();
			if defined (iOS)
				SignInWithApple.SignIn(p);
			if defined (Android)
				SignInWithGoogle.SignIn(p);
			return p;
		}

		static Scripting.Object Converter(Context context, LoginInformation loginInfo)
		{
			var wrapperObject = context.NewObject();
			wrapperObject["userId"] = loginInfo.CurrentIdentifier;
			wrapperObject["firstName"] = loginInfo.FamilyName;
			wrapperObject["lastName"] = loginInfo.GivenName;
			wrapperObject["email"] = loginInfo.Email;
			wrapperObject["user"] = loginInfo.User;
			wrapperObject["password"] = loginInfo.Password;
			return wrapperObject;
		}
	}

	internal class LoginInformation
	{
		public string CurrentIdentifier;
		public string FamilyName;
		public string GivenName;
		public string Email;
		public string User;
		public string Password;

		public LoginInformation( string currIdentifier, string familyName, string givenName, string email, string user, string password)
		{
			CurrentIdentifier = currIdentifier;
			FamilyName = familyName;
			GivenName = givenName;
			Email = email;
			User = user;
			Password = password;
		}
	}
}