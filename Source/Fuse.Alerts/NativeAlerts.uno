using Uno;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Diagnostics;
using Uno.Runtime.Implementation;
using Uno.UX;
using Fuse.Scripting;
namespace Fuse.Alerts
{
	[ForeignInclude(Language.Java, "java.lang.Runnable", "android.app.AlertDialog", "com.fuse.Activity", "android.content.DialogInterface")]
	[ForeignInclude(Language.ObjC, "Uno-iOS/AppDelegate.h")]
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Alerts

		Offers simple alert and yes/no dialogs on mobile platforms.
	*/
	public sealed class NativeAlerts : NativeModule
	{

		public NativeAlerts()
		{
				Resource.SetGlobalKey(this, "FuseJS/Alerts");
				AddMember(new NativePromise<bool, bool>("confirm", Confirm, null));
				AddMember(new NativePromise<bool, bool>("alert", Alert, null));
		}

		internal sealed class DialogCallback
		{
			Promise<bool> _promise;

			public DialogCallback(Promise<bool> promise)
			{
				_promise = promise;
			}

			public void Positive()
			{
				_promise.Resolve(true);
			}
			public void Negative()
			{
				_promise.Resolve(false);
			}
		}

		static T getOrDefault<T>(object[] args, int index, T defaultValue)
		{
			return index < args.Length ?  (T)args[index] : defaultValue;
		}

		/**
			@scriptmethod alert(title, description, okbuttonlabel)

			Displays an alert box with a single button.

			@param title (string) The dialog box title. Defaults to "Alert!".
			@param description (string) The long form description of the alert. Blank by default.
			@param okbuttonlabel (string) The OK button label text. Defaults to "OK".

			@return (Promise) A boolean promise that resolves to `true` if the OK button was pressed.
		*/
		public static Future<bool> Alert(object[] args)
		{
			return AlertInternal(
				getOrDefault(args, 0, "Alert!"),
				getOrDefault(args, 1, ""),
				getOrDefault(args, 2, "OK"));
		}

		/**
			@scriptmethod confirm(title, description, okbuttonlabel, cancelbuttonlabel)

			Displays an ok/cancel dialog.

			@param title (string) The dialog box title. Defaults to "Confirm".
			@param description (string) The long form description of the alert. Blank by default.
			@param okbuttonlabel (string) The OK button label text. Defaults to "OK".
			@param cancelbuttonlabel (string) The Cancel button label text. Defaults to "Cancel".

			@return (Promise) A boolean promise that resolves to `true` if the OK button was pressed and `false` if the Cancel button was pressed.
		*/
		public static Future<bool> Confirm(object[] args)
		{
			return ConfirmInternal(
				getOrDefault(args, 0, "Confirm"),
				getOrDefault(args, 1, ""),
				getOrDefault(args, 2, "OK"),
				getOrDefault(args, 3, "Cancel"));
		}


		/* DESKTOP */

		extern (!mobile) static Future<bool> ConfirmInternal(String title, String message, String okButtonLabel, String cancelButtonLabel)
		{
			var promise = new Promise<bool>();
			try
			{
				return promise;
			}
			finally
			{
				promise.Resolve(true);
			}
		}

		extern (!mobile) static Future<bool> AlertInternal(String title, String message, String okButtonLabel)
		{
			var promise = new Promise<bool>();
			try
			{
				return promise;
			}
			finally
			{
				promise.Resolve(true);
			}
		}

		/* ANDROID */

		extern (android) static Future<bool> ConfirmInternal(String title, String message, String okButtonLabel, String cancelButtonLabel)
		{
			var promise = new Promise<bool>();
			var cb = new DialogCallback(promise);
			ConfirmNative(title, message, okButtonLabel, cancelButtonLabel, cb.Positive, cb.Negative);
			return promise;
		}

		extern (android) static Future<bool> AlertInternal(String title, String message, String okButtonLabel)
		{
			var promise = new Promise<bool>();
			AlertNative(title, message, okButtonLabel, new DialogCallback(promise).Positive);
			return promise;
		}

		[Foreign(Language.Java)]
		extern (android) static void AlertNative(String title, String message, String okButtonLabel, Action onOK)
		@{
			Runnable r = new Runnable() {
				@Override
				public void run() {
					new AlertDialog.Builder(Activity.getRootActivity())
						.setMessage(message)
						.setTitle(title)
						.setPositiveButton(okButtonLabel, new DialogInterface.OnClickListener()
						{
							@Override
							public void onClick(DialogInterface dialog, int which)
							{
								onOK.run();
							}
						})
						.create().show();
				}
			};
			Activity.getRootActivity().runOnUiThread(r);
		@}

		[Foreign(Language.Java)]
		extern (android) static void ConfirmNative(String title, String message, String okButtonLabel, String cancelButtonLabel, Action onOK, Action onCancel)
		@{
			Runnable r = new Runnable() {
				@Override
				public void run() {
					new AlertDialog.Builder(Activity.getRootActivity())
						.setMessage(message)
						.setTitle(title)
						.setPositiveButton(okButtonLabel, new DialogInterface.OnClickListener()
						{
							@Override
							public void onClick(DialogInterface dialog, int which)
							{
								onOK.run();
							}
						})
						.setNegativeButton(cancelButtonLabel, new DialogInterface.OnClickListener()
						{
							@Override
							public void onClick(DialogInterface dialog, int which)
							{
								onCancel.run();
							}
						})
						.create().show();
				}
			};
			Activity.getRootActivity().runOnUiThread(r);
		@}

		/* IOS */

		extern (iOS) static Future<bool> ConfirmInternal(String title, String message, String okButtonLabel, String cancelButtonLabel)
		{
			var promise = new Promise<bool>();
			var cb = new DialogCallback(promise);
			ConfirmNative(title, message, okButtonLabel, cancelButtonLabel, cb.Positive, cb.Negative);
			return promise;
		}

		extern (iOS) static Future<bool> AlertInternal(String title, String message, String okButtonLabel)
		{
			var promise = new Promise<bool>();
			AlertNative(title, message, okButtonLabel, new DialogCallback(promise).Positive);
			return promise;
		}

		[Foreign(Language.ObjC)]
		extern (iOS) static void AlertNative(String title, String message, String okButtonLabel, Action onOK)
		@{
			UIAlertController* alert = [UIAlertController
				alertControllerWithTitle:title
				message:message
				preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* defaultAction = [UIAlertAction
				actionWithTitle:okButtonLabel
				style:UIAlertActionStyleDefault
				handler:^(UIAlertAction * action) { onOK(); }];

			[alert addAction:defaultAction];

			dispatch_async(dispatch_get_main_queue(), ^{
				[(::uAppDelegate*)[[UIApplication sharedApplication] delegate]
					presentViewController:alert animated:YES completion:nil];
			});
		@}

		[Foreign(Language.ObjC)]
		extern (iOS) static void ConfirmNative(String title, String message, String okButtonLabel, String cancelButtonLabel, Action onOK, Action onCancel)
		@{
			UIAlertController* modalAlert = [UIAlertController
				alertControllerWithTitle:title
				message:message
				preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* positiveAction = [UIAlertAction
				actionWithTitle:okButtonLabel
				style:UIAlertActionStyleDefault
				handler:^(UIAlertAction * action) { onOK(); }];

			UIAlertAction* negativeAction = [UIAlertAction
				actionWithTitle:cancelButtonLabel
				style:UIAlertActionStyleCancel
				handler:^(UIAlertAction * action) { onCancel(); }];

			[modalAlert addAction:positiveAction];
			[modalAlert addAction:negativeAction];

			dispatch_async(dispatch_get_main_queue(), ^{
				[(::uAppDelegate*)[[UIApplication sharedApplication] delegate]
					presentViewController:modalAlert animated:YES completion:nil];
			});
		@}
	}
}
