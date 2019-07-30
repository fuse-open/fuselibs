using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;

namespace Fuse.PushNotifications
{
	/**
		@scriptmodule FuseJS/Push

		Handles push notification from messaging services.

		This module currently supports APNS (Apple Push Notification Service) and GCM (Google Cloud Messaging).

		@include Docs/Guide.md

		## Remarks

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		You need to add a reference to `Fuse.PushNotifications` in your project file to use this feature.

		## Android setup
		@include Docs/AndroidSpecifics.md

		## iOS setup
		@include Docs/AppleSpecifics.md
	*/
	[UXGlobalModule]
	public sealed class Push : NativeEventEmitterModule
	{
		static readonly Push _instance;

		public Push()
			: base(true,
				"receivedMessage",
				"registrationSucceeded")
		{
			if (_instance != null) return;
			Uno.UX.Resource.SetGlobalKey(_instance = this, "FuseJS/Push");

			// Old-style events for backwards compatibility
			var onReceivedMessage = new NativeEvent("onReceivedMessage");
			var onRegistrationFailed = new NativeEvent("onRegistrationFailed");
			var onRegistrationSucceeded = new NativeEvent("onRegistrationSucceeded");

			On("receivedMessage", onReceivedMessage);
			// Note: If we decide to remove these old-style events in the future, the
			// "error" event will no longer have a listener by default, meaning that the
			// module will then throw an exception on "error" (as per the way
			// EventEmitter works), unlike the current behaviour.  To retain the current
			// behaviour we might then want to add a dummy listener to the "error"
			// event.
			On("error", onRegistrationFailed);
			On("registrationSucceeded", onRegistrationSucceeded);

			AddMember(onReceivedMessage);
			AddMember(onRegistrationSucceeded);
			AddMember(onRegistrationFailed);
			AddMember(new NativeFunction("clearBadgeNumber", ClearBadgeNumber));
			AddMember(new NativeFunction("clearAllNotifications", ClearAllNotifications));
			AddMember(new NativeFunction("register", Register));
			AddMember(new NativeFunction("isRegisteredForRemoteNotifications", IsRegisteredForRemoteNotifications));

			Fuse.PushNotifications.PushNotify.ReceivedNotification += OnReceivedNotification;
			Fuse.PushNotifications.PushNotify.RegistrationSucceeded += OnRegistrationSucceeded;
			Fuse.PushNotifications.PushNotify.RegistrationFailed += OnRegistrationFailed;
		}

		/**
			@scriptevent receivedMessage
			@param message The content of the notification as json

			Triggered when your app receives a notification.
		*/
		void OnReceivedNotification(object sender, KeyValuePair<string,bool>message)
		{
			Emit("receivedMessage", message.Key, message.Value);
		}

		/**
			@scriptevent registrationSucceeded
			@param message The registration key from the backend

			Triggered when your app registers with the APNS or GCM backend.
		*/
		void OnRegistrationSucceeded(object sender, string message)
		{
			Emit("registrationSucceeded", message);
		}

		/**
			@scriptevent error
			@param message A backend specific reason for the failure.

			Called if your app fails to register with the backend.
		*/
		void OnRegistrationFailed(object sender, string message)
		{
			EmitError(message);
		}

		/**
			@scriptmethod clearBadgeNumber

			Clears the badge number shown on the iOS home screen.

			Has no effects on other platforms.
		*/
		public object ClearBadgeNumber(Context context, object[] args)
		{
			Fuse.PushNotifications.PushNotify.ClearBadgeNumber();
			return null;
		}

		/**
			@scriptmethod clearAllNotifications

			Cancels all previously shown notifications.
		*/
		public object ClearAllNotifications(Context context, object[] args)
		{
			Fuse.PushNotifications.PushNotify.ClearAllNotifications();
			return null;
		}

		/**
			@scriptmethod register

			Registers the app with APNS. Only neccesary if APNS.RegisterOnLaunch was
			set to false in the unoproj file.
		*/
		public object Register(Context context, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "Push.register takes no arguments", this);
				return null;
			}
			Fuse.PushNotifications.PushNotify.Register();
			return null;
		}

		/**
			@scriptmethod isRegisteredForRemoteNotifications

			Gets whether or not the user has enabled remote notifications
		*/
		public object IsRegisteredForRemoteNotifications(Context context, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "Push.isRegisteredForRemoteNotifications takes no arguments", this);
				return null;
			}
			return Fuse.PushNotifications.PushNotify.IsRegisteredForRemoteNotifications();
		}
	}
}
