using Uno;
using Uno.UX;

using Fuse.Triggers;
using Fuse.Triggers.Actions;
using Fuse.Scripting;

namespace Fuse
{
	public class AuthArgs : EventArgs, IScriptEvent
	{
		bool _status;
		string _message;

		public AuthArgs(bool result, string msg)
		{
			_status = result;
			_message = msg;
		}
		void IScriptEvent.Serialize(IEventSerializer s)
		{
			Serialize(s);
		}

		virtual void Serialize(IEventSerializer s)
		{
			s.AddBool("status", _status);
			s.AddString("message", _message);
		}
	}

	public delegate void AuthEventHandler(object sender, AuthArgs args);

	/**
		This is trigger action for taking biometric authentication. Both iOS and Android is using Fingerprint/Touch ID or Face Recognition/Face ID sensor depending on what sensor are available on the device.
		You need to add a reference to `"Fuse.Auth"` in your project file to use this feature.

		## Example

			The following example shows how to use it:

				<JavaScript>
					var Observable = require('FuseJS/Observable');
					var status = Observable();
					var statusMessage = Observable();

					module.exports = {
						status,
						statusMessage
						resultHandler: function(data) {
							status.value = data.result; // bool value indicating whether true value when it succeed or false value if it failed
							statusMessage.value = data.message;
						}
					};
				</JavaScript>
				<Panel>
					<Button Text="Sign In" Alignment="Center">
						<Clicked>
							<Authenticate PromptMessage="We need your biometric data for Sign In" Handler="{resultHandler}" />
						</Clicked>
					</Button>
				</Panel>

		When Using FaceID on iOS, it is mandatory to add description about why you need authentication using FaceID. You can add the description by adding this config on your `unoproj` file

				"iOS": {
					"PList": {
						"NSFaceIDUsageDescription": "Require access to FaceID for authenticating"
					}
				}
	*/
	public class Authenticate : TriggerAction
	{
		Node _target;

		/**
		Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event AuthEventHandler Handler;

		/**
		String message to inform user on why you need biometric data. This message only applicable for fingerprint scan
		*/
		public string PromptMessage
		{
			get; set;
		}

		public Authenticate()
		{
			PromptMessage = "We need your biometric information for authentication";
		}

		extern(!MOBILE)
		protected override void Perform(Node n)
		{
			Fuse.Diagnostics.UserWarning("Biometric authentication is not implemented for this platform", this);
		}

		extern(MOBILE)
		protected override void Perform(Node n)
		{
			_target = n;
			if defined(iOS)
				IOSBiometric.Authenticate(PromptMessage, AuthSuccess, AuthFailed);
			if defined(Android)
				AndroidBiometric.Authenticate(PromptMessage, AuthSuccess, AuthFailed);
		}

		void AuthSuccess()
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new AuthArgs(true, "Authentication succeed"));
			}
		}

		void AuthFailed(string message)
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new AuthArgs(false, message));
			}
		}
	}
}