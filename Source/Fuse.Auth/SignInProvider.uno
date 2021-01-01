using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Fuse;
using Fuse.Platform;
using Fuse.Storage;

namespace Fuse
{
	[Require("Xcode.Framework","AuthenticationServices")]
	[Require("Xcode.Framework","Security")]
	[ForeignInclude(Language.ObjC, "SignInHelper.h")]
	extern(iOS) class SignInWithApple
	{
		static ObjC.Object Handle;
		static SignInWithApple instance;
		static Promise<bool> _hasSignInPromise;
		static Promise<LoginInformation> _signInPromise;

		static SignInWithApple()
		{
			if (Handle == null && Fuse.iOSDevice.OperatingSystemVersion.Major >= 13)
				Handle = Setup();
		}

		public static void HasSignedIn(Promise<bool> promise)
		{
			if (Fuse.iOSDevice.OperatingSystemVersion.Major >= 13)
			{
				_hasSignInPromise = promise;
				HasSignedIn(Handle, OnResult);
			}
			else
				promise.Resolve(false);
		}

		static void OnResult(bool result)
		{
			_hasSignInPromise.Resolve(result);
		}

		public static void SignIn(Action success, Action<string> fail)
		{
			if (Fuse.iOSDevice.OperatingSystemVersion.Major >= 13)
				SignIn(Handle, success, fail);
			else
				fail("This iOS version is not supported for Sign In With Apple");
		}

		public static void SignIn(Promise<LoginInformation> promise)
		{
			if (Fuse.iOSDevice.OperatingSystemVersion.Major >= 13)
			{
				_signInPromise = promise;
				SignIn(Handle, OnLoginSucceed, OnLoginFailed);
			}
			else
				promise.Reject(new Exception("This iOS version is not supported for Sign In With Apple"));
		}

		static void OnLoginSucceed()
		{
			var _userId = IOSUserSettingsImpl.GetStringValue("platformSignIn.userId");
			var _lastName = IOSUserSettingsImpl.GetStringValue("platformSignIn.lastName");
			var _firstName = IOSUserSettingsImpl.GetStringValue("platformSignIn.firstName");
			var _email = IOSUserSettingsImpl.GetStringValue("platformSignIn.email");
			var _user = IOSUserSettingsImpl.GetStringValue("platformSignIn.user");
			var _password = IOSUserSettingsImpl.GetStringValue("platformSignIn.password");
			_signInPromise.Resolve(new LoginInformation(_userId, _lastName, _firstName, _email, _user, _password));
		}

		static void OnLoginFailed(string message)
		{
			_signInPromise.Reject(new Exception(message));
		}

		[Foreign(Language.ObjC)]
		extern(iOS) static void HasSignedIn(ObjC.Object Handle, Action<bool> result)
		@{
			SignInHelper* helper = (SignInHelper *)Handle;
			[helper hasSignedIn:result];
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static ObjC.Object Setup()
		@{
			return [[SignInHelper alloc] init];
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static void SignIn(ObjC.Object Handle, Action success, Action<string> fail)
		@{
			SignInHelper* helper = (SignInHelper *)Handle;
			dispatch_async(dispatch_get_main_queue(), ^{
				[helper handleAppleIDAuthorization:success error:fail];
			});
		@}
	}

	[Require("Gradle.Dependency.Implementation", "com.google.android.gms:play-services-auth:17.0.0")]
	[ForeignInclude(Language.Java,
		"com.google.android.gms.auth.api.signin.GoogleSignInOptions",
		"com.google.android.gms.auth.api.signin.GoogleSignIn",
		"com.google.android.gms.auth.api.signin.GoogleSignInClient",
		"com.google.android.gms.auth.api.signin.GoogleSignInAccount",
		"com.google.android.gms.common.api.ApiException",
		"com.google.android.gms.tasks.Task",
		"android.content.Intent",
		"com.fuse.Activity",
		"android.content.SharedPreferences",
		"android.preference.PreferenceManager"
	)]
	extern(Android) class SignInWithGoogle
	{
		static Java.Object Handle;
		static SignInWithGoogle instance;
		static Action _success;
		static Action<string> _fail;
		static int RequestCode = 9987;
		static Promise<bool> _hasSignInPromise;
		static Promise<LoginInformation> _signInPromise;

		static SignInWithGoogle()
		{
			if (Handle == null)
				Handle = Setup();
		}

		public static void HasSignedIn(Promise<bool> promise)
		{
			_hasSignInPromise = promise;
			HasSignedIn(Handle, OnResult);
		}

		static void OnResult(bool result)
		{
			_hasSignInPromise.Resolve(result);
		}

		public static void SignIn(Action success, Action<string> fail)
		{
			_success = success;
			_fail = fail;
			SignIn(MakeIntent(Handle));
		}

		public static void SignIn(Promise<LoginInformation> promise)
		{
			_signInPromise = promise;
			_success = OnLoginSucceed;
			_fail = OnLoginFailed;
			SignIn(MakeIntent(Handle));
		}

		static void OnLoginSucceed()
		{
			var _userId = AndroidUserSettingsImpl.GetStringValue("platformSignIn.userId");
			var _lastName = AndroidUserSettingsImpl.GetStringValue("platformSignIn.lastName");
			var _firstName = AndroidUserSettingsImpl.GetStringValue("platformSignIn.firstName");
			var _email = AndroidUserSettingsImpl.GetStringValue("platformSignIn.email");
			_signInPromise.Resolve(new LoginInformation(_userId, _lastName, _firstName, _email, "", ""));
		}

		static void OnLoginFailed(string message)
		{
			_signInPromise.Reject(new Exception(message));
		}

		[Foreign(Language.Java)]
		extern(android) static void SignIn(Java.Object intent)
		@{
			int requestCode = @{RequestCode:Get()};
			com.fuse.Activity.getRootActivity().startActivityForResult((Intent)intent, requestCode);
		@}

		static void OnResult (int requestCode, Java.Object intent)
		{
			if (requestCode == RequestCode)
				OnResultHandler(requestCode, intent, _success, _fail);
		}

		[Foreign(Language.Java)]
		extern(android) static void OnResultHandler(int requestCode, Java.Object intent, Action success, Action<string> fail)
		@{
			Intent data = (Intent)intent;
			Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
			try {
				GoogleSignInAccount account = task.getResult(ApiException.class);
				@{SaveAccount(Java.Object):Call(account)};
				if (success != null)
					success.run();
			} catch (ApiException e) {
				if (fail != null)
					fail.run(e.getMessage());
			}
		@}

		[Foreign(Language.Java)]
		extern(android) static Java.Object MakeIntent(Java.Object Handle)
		@{
			GoogleSignInClient mGoogleSignInClient = (GoogleSignInClient)Handle;
			return mGoogleSignInClient.getSignInIntent();
		@}

		[Foreign(Language.Java)]
		extern(Android) static void HasSignedIn(Java.Object Handle, Action<bool> result)
		@{

			GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(Activity.getRootActivity());
			if (account != null)
			{
				@{SaveAccount(Java.Object):Call(account)};
				if (result != null)
					result.run(true);
			}
			else
			{
				@{ClearAccount():Call()};
				if (result != null)
					result.run(false);
			}
		@}

		[Foreign(Language.Java)]
		extern(Android) static Java.Object Setup()
		@{
			com.fuse.Activity.ResultListener l = new com.fuse.Activity.ResultListener() {
				@Override public boolean onResult(int requestCode, int resultCode, android.content.Intent data) {
					@{OnResult(int,Java.Object):Call(requestCode, data)};
					return false;
				}
			};
			com.fuse.Activity.subscribeToResults(l);
			GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
											.requestEmail()
											.build();
			return GoogleSignIn.getClient(Activity.getRootActivity(), gso);
		@}

		[Foreign(Language.Java)]
		extern(Android) static void SaveAccount(Java.Object accountData)
		@{
			GoogleSignInAccount account = (GoogleSignInAccount)accountData;
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.putString("platformSignIn.email", account.getEmail());
			editor.putString("platformSignIn.firstName", account.getGivenName());
			editor.putString("platformSignIn.lastName", account.getFamilyName());
			editor.putString("platformSignIn.userId", account.getId());
			editor.apply();
		@}

		[Foreign(Language.Java)]
		extern(Android) static void ClearAccount()
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.remove("platformSignIn.email");
			editor.remove("platformSignIn.firstName");
			editor.remove("platformSignIn.lastName");
			editor.remove("platformSignIn.userId");
			editor.apply();
		@}
	}
}