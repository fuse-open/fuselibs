using Uno;
using Uno.UX;
using Android;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Platform;

namespace Fuse
{
	[Require("Xcode.Framework","LocalAuthentication")]
	[Require("Source.Import","LocalAuthentication/LocalAuthentication.h")]
	extern(iOS) class IOSBiometric
	{
		[Foreign(Language.ObjC)]
		public extern(iOS) static bool IsSupported()
		@{
			LAContext *laContext = [[LAContext alloc] init];
			NSError *authError = nil;
			return [laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError];
		@}

		[Foreign(Language.ObjC)]
		public extern(iOS) static void Authenticate(string reason, Action action_success, Action<string> action_fail)
		@{
			LAContext *laContext = [[LAContext alloc] init];
			NSError *authError = nil;
			if ([laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
			{
				[laContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
				localizedReason:reason
				reply:^(BOOL success, NSError *error) {
					if (success)
						action_success();
					else
						action_fail([error localizedDescription]);
				}];
			}
			else
				action_fail([authError localizedDescription]);
		@}
	}


	[Require("Gradle.Dependency.Implementation", "androidx.biometric:biometric:1.0.1")]
	[ForeignInclude(Language.Java,
		"androidx.biometric.BiometricManager",
		"androidx.biometric.BiometricPrompt",
		"androidx.core.content.ContextCompat",
		"java.util.concurrent.Executor",
		"android.app.KeyguardManager",
		"android.content.Context"
	)]
	extern(Android) class AndroidBiometric
	{
		[Foreign(Language.Java)]
		public extern(Android) static bool IsSupported()
		@{
			BiometricManager biometricManager = BiometricManager.from(com.fuse.Activity.getRootActivity());
			switch (biometricManager.canAuthenticate()) {
				case BiometricManager.BIOMETRIC_SUCCESS:
					return true;
				case BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE:
					return false;
				case BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE:
					return false;
				case BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED:
					return false;
			}
			return false;
		@}

		[Foreign(Language.Java)]
		public extern(Android) static void Authenticate(string reason, Action success, Action<string> fail)
		@{
			if (@{IsSupported():Call()}) {
				Executor executor = ContextCompat.getMainExecutor(com.fuse.Activity.getRootActivity());
				BiometricPrompt biometricPrompt = new BiometricPrompt(com.fuse.Activity.getRootActivity(),
						executor, new BiometricPrompt.AuthenticationCallback() {

					@Override
					public void onAuthenticationError(int errorCode, CharSequence errString) {
						super.onAuthenticationError(errorCode, errString);
						fail.run(errString.toString());
					}

					@Override
					public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
						super.onAuthenticationSucceeded(result);
						success.run();
					}

					@Override
					public void onAuthenticationFailed() {
						super.onAuthenticationFailed();
						fail.run("Authentication failed");
					}
				});

				boolean isDeviceSecure = true;
				BiometricPrompt.PromptInfo.Builder builder = new BiometricPrompt.PromptInfo.Builder();
				KeyguardManager kManager = (KeyguardManager) com.fuse.Activity.getRootActivity().getSystemService(Context.KEYGUARD_SERVICE);
				if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M)
					isDeviceSecure = kManager.isDeviceSecure();
				if (!isDeviceSecure)
					builder = builder.setNegativeButtonText("Cancel");
				builder = builder.setTitle("Biometric Authentication")
						.setSubtitle(reason)
						.setDeviceCredentialAllowed(isDeviceSecure)
						.setConfirmationRequired(false);
				BiometricPrompt.PromptInfo promptInfo = builder.build();
				biometricPrompt.authenticate(promptInfo);
			} else {
				fail.run("Biometric is not supported");
			}
		@}
	}
}