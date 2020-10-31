using Uno;
using Uno.UX;
using Fuse;
using Fuse.Scripting;
using Uno.Threading;

namespace Fuse
{
	[UXGlobalModule]
	/**
		This is javacript module for taking biometric authentication. Both iOS and Android is using Fingerprint/Touch ID or Face Recognition/Face ID sensor depending on what sensor are available on the device.
		You need to add a reference to `"Fuse.Auth"` in your project file to use this feature.

		## Example

			The following example shows how to use it:

				<JavaScript>
					var Auth = require('FuseJS/Biometric');

					var authenticate = function(e) {
						if (Auth.isBiometricSupported()) {
							Auth.authenticate("We need your biometric data to continue").then(function(result) {
								if (result.status) {
									// auth success
								} else {
									console.log(result.message);
								}
							});
						}
					}
					module.exports = {
						authenticate
					};
				</JavaScript>
				<Panel>
					<Button Text="Sign In" Alignment="Center">
						<Clicked Handler="{authenticate}" />
					</Button>
				</Panel>

		When Using FaceID on iOS, it is mandatory to add description about why you need authentication using FaceID. You can add the description by adding this config on your `unoproj` file

				"iOS": {
					"PList": {
						"NSFaceIDUsageDescription": "Require access to FaceID for authenticating"
					}
				}
	*/
	public class BiometricModule : NativeModule
	{
		static readonly BiometricModule _instance;

		public BiometricModule()
		{
			if (_instance != null) return;

			_instance = this;
			Resource.SetGlobalKey(_instance, "FuseJS/Biometric");
			AddMember(new NativeFunction("isBiometricSupported", (NativeCallback)SupportBiometric));
			AddMember(new NativePromise<BiometricStatus, Scripting.Object>("authenticate", Authenticate, Converter));
		}

		static object SupportBiometric(Context c, object[] args)
		{
			var supported = false;
			if defined(Android)
				supported = AndroidBiometric.IsSupported();
			if defined(iOS)
				supported = IOSBiometric.IsSupported();
			return supported;
		}

		static Future<BiometricStatus> Authenticate(object[] args)
		{
			if (args.Length != 1)
				throw new Exception("authenticate() requires exactly 1 parameter.");
			var p = new Promise<BiometricStatus>();
			if defined(iOS)
				IOSBiometric.Authenticate(args[0] as string, p);
			if defined(Android)
				AndroidBiometric.Authenticate(args[0] as string, p);
			return p;
		}

		static Scripting.Object Converter(Context context, BiometricStatus info)
		{
			var wrapperObject = context.NewObject();
			wrapperObject["status"] = info.Status;
			wrapperObject["message"] = info.Message;
			return wrapperObject;
		}
	}

	internal class BiometricStatus
	{
		public bool Status;
		public string Message;

		public BiometricStatus(bool status, string message)
		{
			Status = status;
			Message = message;
		}
	}
}